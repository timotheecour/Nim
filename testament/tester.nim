#
#
#            Nim Tester
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nim against the testcases.

import
  parseutils, strutils, pegs, os, osproc, streams, parsecfg, json,
  marshal, backend, parseopt, specs, htmlgen, browsers, terminal,
  algorithm, compiler/nodejs, times, sets, md5

import "$nim/tools/ciutils"

var useColors = true
var backendLogging = true
var simulate = false
var verboseMegatest = false # very verbose but can be useful
var verboseCommands = false

const
  testsDir = "tests" & DirSep
  resultsFile = "testresults.html"
  #jsonFile = "testresults.json" # not used
  Usage = """Usage:
  tester [options] command [arguments]

Command:
  all                         run all tests
  c|cat|category <category>   run all the tests of a certain category
  r|run <test>                run single test file
  html                        generate $1 from the database
  stats                       generate statistics about test cases
Arguments:
  arguments are passed to the compiler
Options:
  --print                   also print results to the console
  --verboseMegatest         log to stdout megatetest compilation
  --verboseCommands         log to stdout info about commands being run
  --simulate                see what tests would be run but don't run them (for debugging)
  --failing                 only show failing/ignored tests
  --targets:"c c++ js objc" run tests for specified targets (default: all)
  --nim:path                use a particular nim executable (default: compiler/nim)
  --directory:dir           Change to directory dir before reading the tests or doing anything else.
  --colors:on|off           Turn messagescoloring on|off.
  --backendLogging:on|off   Disable or enable backend logging. By default turned on.
""" % resultsFile

type
  Category = distinct string
  TResults = object
    total, passed, skipped: int
    data: string

  TTest = object
    name: string
    cat: Category
    options: string
    spec: TSpec
    startTime: float

# ----------------------------------------------------------------------------

let
  pegLineError =
    peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' ('Error') ':' \s* {.*}"
  pegLineTemplate =
    peg"""
      {[^(]*} '(' {\d+} ', ' {\d+} ') '
      'template/generic instantiation' ( ' of `' [^`]+ '`' )? ' from here' .*
    """
  pegOtherError = peg"'Error:' \s* {.*}"
  pegSuccess = peg"'Hint: operation successful'.*"
  pegOfInterest = pegLineError / pegOtherError

var gTargets = {low(TTarget)..high(TTarget)}

proc normalizeMsg(s: string): string =
  result = newStringOfCap(s.len+1)
  for x in splitLines(s):
    if result.len > 0: result.add '\L'
    result.add x.strip

proc getFileDir(filename: string): string =
  result = filename.splitFile().dir
  if not result.isAbsolute():
    result = getCurrentDir() / result

proc execCmdEx2(command: string, args: openarray[string], options: set[ProcessOption], input: string, onStdout: proc(line: string) = nil): tuple[
                output: TaintedString,
                exitCode: int] {.tags:
                [ExecIOEffect, ReadIOEffect, RootEffect], gcsafe.} =
  var p = startProcess(command, args=args, options=options)
  var outp = outputStream(p)

  # There is no way to provide input for the child process
  # anymore. Closing it will create EOF on stdin instead of eternal
  # blocking.
  let instream = inputStream(p)
  instream.write(input)
  close instream

  result = (TaintedString"", -1)
  var line = newStringOfCap(120).TaintedString
  while true:
    if outp.readLine(line):
      result.output.string.add(line.string)
      result.output.string.add("\n")
      if onStdout != nil: onStdout(line.string)
    else:
      result.exitCode = peekExitCode(p)
      if result.exitCode != -1: break
  close(p)

  if verboseCommands:
    var command2 = command
    if args.len > 0: command2.add " " & args.quoteShellCommand
    echo (msg: "execCmdEx2",
      command: command2,
      options: options,
      exitCode: result.exitCode)

proc nimcacheDir(filename, options: string, target: TTarget): string =
  ## Give each test a private nimcache dir so they don't clobber each other's.
  let hashInput = options & $target
  return "nimcache" / (filename & '_' & hashInput.getMD5)

proc callCompiler(cmdTemplate, filename, options: string,
                  target: TTarget, extraOptions=""): TSpec =
  let nimcache = nimcacheDir(filename, options, target)
  let options = options & " " & quoteShell("--nimCache:" & nimcache) & extraOptions
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell,
                       "filedir", filename.getFileDir()])
  var p = startProcess(command=c[0], args=c[1 .. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var tmpl = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
    if x =~ pegOfInterest:
      # `err` should contain the last error/warning message
      err = x
    elif x =~ pegLineTemplate and err == "":
      # `tmpl` contains the last template expansion before the error
      tmpl = x
    elif x =~ pegSuccess:
      suc = x
  close(p)
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = 0
  result.column = 0
  result.tfile = ""
  result.tline = 0
  result.tcolumn = 0
  if tmpl =~ pegLineTemplate:
    result.tfile = extractFilename(matches[0])
    result.tline = parseInt(matches[1])
    result.tcolumn = parseInt(matches[2])
  if err =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.column = parseInt(matches[2])
    result.msg = matches[3]
  elif err =~ pegOtherError:
    result.msg = matches[0]
  elif suc =~ pegSuccess:
    result.err = reSuccess

proc callCCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                       "options", options, "file", filename.quoteShell,
                       "filedir", filename.getFileDir()])
  var p = startProcess(command="gcc", args=c[5 .. ^1],
                       options={poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var x = newStringOfCap(120)
  result.nimout = ""
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = -1
  while outp.readLine(x.TaintedString) or running(p):
    result.nimout.add(x & "\n")
  close(p)
  if p.peekExitCode == 0:
    result.err = reSuccess

proc initResults: TResults =
  result.total = 0
  result.passed = 0
  result.skipped = 0
  result.data = ""

import macros

macro ignoreStyleEcho(args: varargs[typed]): untyped =
  let typForegroundColor = bindSym"ForegroundColor".getType
  let typBackgroundColor = bindSym"BackgroundColor".getType
  let typStyle = bindSym"Style".getType
  let typTerminalCmd = bindSym"TerminalCmd".getType
  result = newCall(bindSym"echo")
  for arg in children(args):
    if arg.kind == nnkNilLit: continue
    let typ = arg.getType
    if typ.kind != nnkEnumTy or
       typ != typForegroundColor and
       typ != typBackgroundColor and
       typ != typStyle and
       typ != typTerminalCmd:
      result.add(arg)

template maybeStyledEcho(args: varargs[untyped]): untyped =
  if useColors:
    styledEcho(args)
  else:
    ignoreStyleEcho(args)


proc `$`(x: TResults): string =
  result = ("Tests passed: $1 / $3 <br />\n" &
            "Tests skipped: $2 / $3 <br />\n") %
            [$x.passed, $x.skipped, $x.total]

proc addResult(r: var TResults, test: TTest, target: TTarget,
               expected, given: string, success: TResultEnum) =
  # test.name is easier to find than test.name.extractFilename
  # A bit hacky but simple and works with tests/testament/tshouldfail.nim
  var name = test.name.replace(DirSep, '/')
  name.add " " & $target & test.options

  let duration = epochTime() - test.startTime
  let durationStr = duration.formatFloat(ffDecimal, precision = 8).align(11)
  if backendLogging:
    backend.writeTestResult(name = name,
                            category = test.cat.string,
                            target = $target,
                            action = $test.spec.action,
                            result = $success,
                            expected = expected,
                            given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  if success == reSuccess:
    maybeStyledEcho fgGreen, "PASS: ", fgCyan, alignLeft(name, 60), fgBlue, " (", durationStr, " secs)"
  elif success == reDisabled:
    maybeStyledEcho styleDim, fgYellow, "SKIP: ", styleBright, fgCyan, name
  elif success == reJoined:
    maybeStyledEcho styleDim, fgYellow, "JOINED: ", styleBright, fgCyan, name
  else:
    maybeStyledEcho styleBright, fgRed, "FAIL: ", fgCyan, name
    maybeStyledEcho styleBright, fgCyan, "Test \"", test.name, "\"", " in category \"", test.cat.string, "\""
    maybeStyledEcho styleBright, fgRed, "Failure: ", $success
    maybeStyledEcho fgYellow, "Expected:"
    maybeStyledEcho styleBright, expected, "\n"
    maybeStyledEcho fgYellow, "Gotten:"
    maybeStyledEcho styleBright, given, "\n"

  if backendLogging and existsEnv("APPVEYOR"):
    let (outcome, msg) =
      if success == reSuccess:
        ("Passed", "")
      elif success in {reDisabled, reJoined}:
        ("Skipped", "")
      else:
        ("Failed", "Failure: " & $success & "\nExpected:\n" & expected & "\n\n" & "Gotten:\n" & given)
    var p = startProcess("appveyor", args=["AddTest", test.name.replace("\\", "/") & test.options,
                         "-Framework", "nim-testament", "-FileName",
                         test.cat.string,
                         "-Outcome", outcome, "-ErrorMessage", msg,
                         "-Duration", $(duration*1000).int],
                         options={poStdErrToStdOut, poUsePath, poParentStreams})
    discard waitForExit(p)
    close(p)

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  if strip(expected.msg) notin strip(given.msg):
    r.addResult(test, target, expected.msg, given.msg, reMsgsDiffer)
  elif expected.nimout.len > 0 and expected.nimout.normalizeMsg notin given.nimout.normalizeMsg:
    r.addResult(test, target, expected.nimout, given.nimout, reMsgsDiffer)
  elif expected.tfile == "" and extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, target, expected.file, given.file, reFilesDiffer)
  elif expected.line != given.line and expected.line != 0 or
       expected.column != given.column and expected.column != 0:
    r.addResult(test, target, $expected.line & ':' & $expected.column,
                      $given.line & ':' & $given.column,
                      reLinesDiffer)
  elif expected.tfile != "" and extractFilename(expected.tfile) != extractFilename(given.tfile) and
      "internal error:" notin expected.msg:
    r.addResult(test, target, expected.tfile, given.tfile, reFilesDiffer)
  elif expected.tline != given.tline and expected.tline != 0 or
       expected.tcolumn != given.tcolumn and expected.tcolumn != 0:
    r.addResult(test, target, $expected.tline & ':' & $expected.tcolumn,
                      $given.tline & ':' & $given.tcolumn,
                      reLinesDiffer)
  else:
    r.addResult(test, target, expected.msg, given.msg, reSuccess)
    inc(r.passed)

proc generatedFile(test: TTest, target: TTarget): string =
  let (_, name, _) = test.name.splitFile
  let ext = targetToExt[target]
  result = nimcacheDir(test.name, test.options, target) /
    ((if target == targetJS: "" else: "compiler_") & name.changeFileExt(ext))

proc needsCodegenCheck(spec: TSpec): bool =
  result = spec.maxCodeSize > 0 or spec.ccodeCheck.len > 0

proc codegenCheck(test: TTest, target: TTarget, spec: TSpec, expectedMsg: var string,
                  given: var TSpec) =
  try:
    let genFile = generatedFile(test, target)
    let contents = readFile(genFile).string
    let check = spec.ccodeCheck
    if check.len > 0:
      if check[0] == '\\':
        # little hack to get 'match' support:
        if not contents.match(check.peg):
          given.err = reCodegenFailure
      elif contents.find(check.peg) < 0:
        given.err = reCodegenFailure
      expectedMsg = check
    if spec.maxCodeSize > 0 and contents.len > spec.maxCodeSize:
      given.err = reCodegenFailure
      given.msg = "generated code size: " & $contents.len
      expectedMsg = "max allowed size: " & $spec.maxCodeSize
  except ValueError:
    given.err = reInvalidPeg
    echo getCurrentExceptionMsg()
  except IOError:
    given.err = reCodeNotFound
    echo getCurrentExceptionMsg()

proc nimoutCheck(test: TTest; expectedNimout: string; given: var TSpec) =
  let giv = given.nimout.strip
  var currentPos = 0
  # Only check that nimout contains all expected lines in that order.
  # There may be more output in nimout. It is ignored here.
  for line in expectedNimout.strip.splitLines:
    currentPos = giv.find(line.strip, currentPos)
    if currentPos < 0:
      given.err = reMsgsDiffer
      return

proc compilerOutputTests(test: TTest, target: TTarget, given: var TSpec,
                         expected: TSpec; r: var TResults) =
  var expectedmsg: string = ""
  var givenmsg: string = ""
  if given.err == reSuccess:
    if expected.needsCodegenCheck:
      codegenCheck(test, target, expected, expectedmsg, given)
      givenmsg = given.msg
    if expected.nimout.len > 0:
      expectedmsg = expected.nimout
      givenmsg = given.nimout.strip
      nimoutCheck(test, expectedmsg, given)
  else:
    givenmsg = given.nimout.strip
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, target, expectedmsg, givenmsg, given.err)

proc testSpec(r: var TResults, test: TTest, targets: set[TTarget] = {}) =
  var expected = test.spec
  if expected.parseErrors.len > 0:
    # targetC is a lie, but parameter is required
    r.addResult(test, targetC, "", expected.parseErrors, reInvalidSpec)
    inc(r.total)
    return
  if expected.err in {reDisabled, reJoined}:
    # targetC is a lie, but parameter is required
    r.addResult(test, targetC, "", "", expected.err)
    inc(r.skipped)
    inc(r.total)
    return
  expected.targets.incl targets
  # still no target specified at all
  if expected.targets == {}:
    if getEnv("NIM_COMPILE_TO_CPP", "false").string == "true":
      expected.targets = {targetCpp}
    else:
      expected.targets = {targetC}
  for target in expected.targets:
    inc(r.total)
    if target notin gTargets:
      r.addResult(test, target, "", "", reDisabled)
      inc(r.skipped)
      continue

    if simulate:
      var count {.global.} = 0
      count.inc
      echo "testSpec count: ", count, " expected: ", expected
      continue

    case expected.action
    of actionCompile:
      var given = callCompiler(expected.getCmd, test.name, test.options, target,
        extraOptions=" --stdout --hint[Path]:off --hint[Processing]:off")
      compilerOutputTests(test, target, given, expected, r)
    of actionRun:
      # In this branch of code "early return" pattern is clearer than deep
      # nested conditionals - the empty rows in between to clarify the "danger"
      var given = callCompiler(expected.getCmd, test.name, test.options,
                               target)
      if given.err != reSuccess:
        r.addResult(test, target, "", given.msg, given.err)
        continue
      let isJsTarget = target == targetJS
      var exeFile: string
      if isJsTarget:
        let file = test.name.lastPathPart.changeFileExt("js")
        exeFile = nimcacheDir(test.name, test.options, target) / file
      else:
        exeFile = changeFileExt(test.name, ExeExt)

      if not existsFile(exeFile):
        r.addResult(test, target, expected.output, "executable not found", reExeNotFound)
        continue

      let nodejs = if isJsTarget: findNodeJs() else: ""
      if isJsTarget and nodejs == "":
        r.addResult(test, target, expected.output, "nodejs binary not in PATH",
                    reExeNotFound)
        continue
      var exeCmd: string
      var args: seq[string]
      if isJsTarget:
        exeCmd = nodejs
        args.add exeFile
      else:
        exeCmd = exeFile
      var (buf, exitCode) = execCmdEx2(exeCmd, args, options = {poStdErrToStdOut}, input = expected.input)
      # Treat all failure codes from nodejs as 1. Older versions of nodejs used
      # to return other codes, but for us it is sufficient to know that it's not 0.
      if exitCode != 0: exitCode = 1
      let bufB =
        if expected.sortoutput:
          var x = splitLines(strip(buf.string))
          sort(x, system.cmp)
          join(x, "\n")
        else:
          strip(buf.string)
      if exitCode != expected.exitCode:
        r.addResult(test, target, "exitcode: " & $expected.exitCode,
                          "exitcode: " & $exitCode & "\n\nOutput:\n" &
                          bufB, reExitCodesDiffer)
        continue
      if (expected.outputCheck == ocEqual and expected.output != bufB) or
         (expected.outputCheck == ocSubstr and expected.output notin bufB):
        given.err = reOutputsDiffer
        r.addResult(test, target, expected.output, bufB, reOutputsDiffer)
        continue
      compilerOutputTests(test, target, given, expected, r)
      continue
    of actionReject:
      var given = callCompiler(expected.getCmd, test.name, test.options,
                               target)
      cmpMsgs(r, expected, given, test, target)
      continue

proc testC(r: var TResults, test: TTest, action: TTestAction) =
  # runs C code. Doesn't support any specs, just goes by exit code.
  let tname = test.name.addFileExt(".c")
  inc(r.total)
  maybeStyledEcho "Processing ", fgCyan, extractFilename(tname)
  var given = callCCompiler(getCmd(TSpec()), test.name & ".c", test.options, targetC)
  if given.err != reSuccess:
    r.addResult(test, targetC, "", given.msg, given.err)
  elif action == actionRun:
    let exeFile = changeFileExt(test.name, ExeExt)
    var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
    if exitCode != 0: given.err = reExitCodesDiffer
  if given.err == reSuccess: inc(r.passed)

proc testExec(r: var TResults, test: TTest) =
  # runs executable or script, just goes by exit code
  inc(r.total)
  let (outp, errC) = execCmdEx(test.options.strip())
  var given: TSpec
  if errC == 0:
    given.err = reSuccess
  else:
    given.err = reExitCodesDiffer
    given.msg = outp.string

  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, targetC, "", given.msg, given.err)

proc makeTest(test, options: string, cat: Category): TTest =
  result.cat = cat
  result.name = test
  result.options = options
  result.spec = parseSpec(addFileExt(test, ".nim"))
  result.startTime = epochTime()

# TODO: fix these files
const disabledFilesDefault = @[
  "LockFreeHash.nim",
  "sharedstrings.nim",
  "tableimpl.nim",

  # Error: undeclared identifier: 'hasThreadSupport'
  "ioselectors_epoll.nim",
  "ioselectors_kqueue.nim",
  "ioselectors_poll.nim",

  # Error: undeclared identifier: 'Timeval'
  "ioselectors_select.nim",
]

when defined(windows):
  const
    # array of modules disabled from compilation test of stdlib.
    disabledFiles = disabledFilesDefault & @["coro.nim"]
else:
  const
    # array of modules disabled from compilation test of stdlib.
    # TODO: why the ["-"]? (previous code should've prob used seq[string] = @[] instead)
    disabledFiles = disabledFilesDefault & @["-"]

include categories

proc main() =
  os.putenv "NIMTEST_COLOR", "never"
  os.putenv "NIMTEST_OUTPUT_LVL", "PRINT_FAILURES"

  backend.open()
  var optPrintResults = false
  var optFailing = false
  var targetsStr = ""

  var p = initOptParser()
  p.next()
  while p.kind == cmdLongoption:
    case p.key.string.normalize
    of "print", "verbose": optPrintResults = true
    of "verbosemegatest": verboseMegatest = true
    of "verbosecommands": verboseCommands = true
    of "failing": optFailing = true
    of "pedantic": discard "now always enabled"
    of "targets":
      targetsStr = p.val.string
      gTargets = parseTargets(targetsStr)
    of "nim":
      compilerPrefix = addFileExt(p.val.string, ExeExt)
    of "directory":
      setCurrentDir(p.val.string)
    of "colors":
      case p.val.string:
      of "on":
        useColors = true
      of "off":
        useColors = false
      else:
        quit Usage
    of "simulate":
      simulate = true
    of "backendlogging":
      case p.val.string:
      of "on":
        backendLogging = true
      of "off":
        backendLogging = false
      else:
        quit Usage
    else:
      quit Usage
    p.next()
  if p.kind != cmdArgument:
    quit Usage
  var action = p.key.string.normalize
  p.next()
  var r = initResults()
  case action
  of "all":
    #processCategory(r, Category"megatest", p.cmdLineRest.string, testsDir, runJoinableTests = false)

    var myself = quoteShell(findExe("testament" / "tester"))
    if targetsStr.len > 0:
      myself &= " " & quoteShell("--targets:" & targetsStr)

    myself &= " " & quoteShell("--nim:" & compilerPrefix)

    var cats: seq[string]
    let rest = if p.cmdLineRest.string.len > 0: " " & p.cmdLineRest.string else: ""
    for kind, dir in walkDir(testsDir):
      assert testsDir.startsWith(testsDir)
      let cat = dir[testsDir.len .. ^1]
      if kind == pcDir and cat notin ["testdata", "nimcache"]:
        cats.add cat
    cats.add AdditionalCategories

    var cmds: seq[string]
    for cat in cats:
      cmds.add(myself & " pcat " & quoteShell(cat) & rest)

    proc progressStatus(idx: int) =
      echo "progress[all]: i: " & $idx & " / " & $cats.len & " cat: " & cats[idx]

    if simulate:
      for i, cati in cats:
        progressStatus(i)
        processCategory(r, Category(cati), p.cmdLineRest.string, testsDir, runJoinableTests = false)
    else:
      quit osproc.execProcesses(cmds, {poEchoCmd, poStdErrToStdOut, poUsePath, poParentStreams}, beforeRunEvent = progressStatus)
  of "c", "cat", "category":
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest.string, testsDir, runJoinableTests = true)
  of "pcat":
    # 'pcat' is used for running a category in parallel. Currently the only
    # difference is that we don't want to run joinable tests here as they
    # are covered by the 'megatest' category.
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest.string, testsDir, runJoinableTests = false)
  of "r", "run":
    # at least one directory is required in the path, to use as a category name
    let pathParts = split(p.key.string, {DirSep, AltSep})
    # "stdlib/nre/captures.nim" -> "stdlib" + "nre/captures.nim"
    let cat = Category(pathParts[0])
    let subPath = joinPath(pathParts[1..^1])
    processSingleTest(r, cat, p.cmdLineRest.string, subPath)
  of "html":
    generateHtml(resultsFile, optFailing)
  else:
    quit Usage

  if optPrintResults:
    if action == "html": openDefaultBrowser(resultsFile)
    else: echo r, r.data
  backend.close()
  var failed = r.total - r.passed - r.skipped
  if failed != 0:
    echo "FAILURE! total: ", r.total, " passed: ", r.passed, " skipped: ",
      r.skipped, " failed: ", failed
    quit(QuitFailure)

if paramCount() == 0:
  quit Usage
main()
