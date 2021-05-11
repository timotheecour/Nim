#
#
#            Nim Testament
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This program verifies Nim against the testcases.

import
  strutils, pegs, os, osproc, streams, json,
  backend, parseopt, specs, htmlgen, browsers, terminal,
  algorithm, times, md5, azure, intsets, macros
from std/sugar import dup
import compiler/nodejs
import lib/stdtest/testutils
from lib/stdtest/specialpaths import splitTestFile
from std/private/gitutils import diffStrings
import timn/dbgs

proc trimUnitSep(x: var string) =
  let L = x.len
  if L > 0 and x[^1] == '\31':
    setLen x, L-1

proc verboseCmd(cmd: string) =
  if optVerbose:
    echo "executing: ", cmd

const
  failString* = "FAIL: " # ensures all failures can be searched with 1 keyword in CI logs
  testsDir = "tests" & DirSep
  resultsFile = "testresults.html"
  Usage = """Usage:
  testament [options] command [arguments]

Command:
  p|pat|pattern <glob>        run all the tests matching the given pattern
  all                         run all tests
  c|cat|category <category>   run all the tests of a certain category
  r|run <test>                run single test file
  html                        generate $1 from the database
Arguments:
  arguments are passed to the compiler
Options:
  --print                   print results to the console
  --verbose                 print commands (compiling and running tests)
  --simulate                see what tests would be run but don't run them (for debugging)
  --failing                 only show failing/ignored tests
  --targets:"c cpp js objc" run tests for specified targets (default: all)
  --nim:path                use a particular nim executable (default: $$PATH/nim)
  --directory:dir           Change to directory dir before reading the tests or doing anything else.
  --colors:on|off           Turn messages coloring on|off.
  --backendLogging:on|off   Disable or enable backend logging. By default turned on.
  --megatest:on|off         Enable or disable megatest. Default is on.
  --skipFrom:file           Read tests to skip from `file` - one test per line, # comments ignored

On Azure Pipelines, testament will also publish test results via Azure Pipelines' Test Management API
provided that System.AccessToken is made available via the environment variable SYSTEM_ACCESSTOKEN.

Experimental: using environment variable `NIM_TESTAMENT_REMOTE_NETWORKING=1` enables
tests with remote networking (as in CI).
""" % resultsFile

proc initResults: TResults =
  result.total = 0
  result.passed = 0
  result.failedButAllowed = 0
  result.skipped = 0
  result.data = ""

# ----------------------------------------------------------------------------
proc isTestEnabled(r: var TResults, test: TTest): bool

let
  pegLineError =
    peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' ('Error') ':' \s* {.*}"
  pegOtherError = peg"'Error:' \s* {.*}"
  pegOfInterest = pegLineError / pegOtherError

var gTargets = {low(TTarget)..high(TTarget)}
var targetsSet = false

proc isSuccess(input: string): bool =
  # not clear how to do the equivalent of pkg/regex's: re"FOO(.*?)BAR" in pegs
  # note: this doesn't handle colors, eg: `\e[1m\e[0m\e[32mHint:`; while we
  # could handle colors, there would be other issues such as handling other flags
  # that may appear in user config (eg: `--filenames`).
  # Passing `XDG_CONFIG_HOME= testament args...` can be used to ignore user config
  # stored in XDG_CONFIG_HOME, refs https://wiki.archlinux.org/index.php/XDG_Base_Directory
  input.startsWith("Hint: ") and
    (input.endsWith("[SuccessX]") or input.endsWith("[BuildMode]"))

proc getFileDir(filename: string): string =
  result = filename.splitFile().dir
  if not result.isAbsolute():
    result = getCurrentDir() / result

proc execCmdEx2(command: string, args: openArray[string]; workingDir, input: string = ""): tuple[
                cmdLine: string,
                output: string,
                exitCode: int] {.tags:
                [ExecIOEffect, ReadIOEffect, RootEffect], gcsafe.} =

  result.cmdLine.add quoteShell(command)
  for arg in args:
    result.cmdLine.add ' '
    result.cmdLine.add quoteShell(arg)
  verboseCmd(result.cmdLine)
  var p = startProcess(command, workingDir = workingDir, args = args,
                       options = {poStdErrToStdOut, poUsePath})
  var outp = outputStream(p)

  # There is no way to provide input for the child process
  # anymore. Closing it will create EOF on stdin instead of eternal
  # blocking.
  let instream = inputStream(p)
  instream.write(input)
  close instream

  result.exitCode = -1
  var line = newStringOfCap(120)
  while true:
    if outp.readLine(line):
      result.output.add line
      result.output.add '\n'
    else:
      result.exitCode = peekExitCode(p)
      if result.exitCode != -1: break
  close(p)

proc nimcacheDir(filename, options: string, target: TTarget): string =
  ## Give each test a private nimcache dir so they don't clobber each other's.
  let hashInput = options & $target
  result = "nimcache" / (filename & '_' & hashInput.getMD5)

proc prepareTestArgs(cmdTemplate, filename, options, nimcache: string,
                     target: TTarget, extraOptions = ""): seq[string] =
  var options = target.defaultOptions & ' ' & options
  # improve pending https://github.com/nim-lang/Nim/issues/14343
  if nimcache.len > 0: options.add ' ' & ("--nimCache:" & nimcache).quoteShell
  options.add ' ' & extraOptions
  result = parseCmdLine(cmdTemplate % ["target", targetToCmd[target],
                      "options", options, "file", filename.quoteShell,
                      "filedir", filename.getFileDir(), "nim", testamentData0.compilerPrefix])

proc callNimCompiler(cmdTemplate, filename, options, nimcache: string,
                     target: TTarget, extraOptions = ""): TSpec =
  let c = prepareTestArgs(cmdTemplate, filename, options, nimcache, target,
                          extraOptions)
  result.cmd = quoteShellCommand(c)
  verboseCmd(c.quoteShellCommand)
  var p = startProcess(command = c[0], args = c[1 .. ^1],
                       options = {poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var suc = ""
  var err = ""
  var x = newStringOfCap(120)
  result.nimout = ""
  while true:
    if outp.readLine(x):
      trimUnitSep x
      result.nimout.add(x & '\n')
      if x =~ pegOfInterest:
        # `err` should contain the last error/warning message
        err = x
      elif x.isSuccess:
        suc = x
    elif not running(p):
      break
  close(p)
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = 0
  result.column = 0
  result.err = reNimcCrash
  if err =~ pegLineError:
    result.file = extractFilename(matches[0])
    result.line = parseInt(matches[1])
    result.column = parseInt(matches[2])
    result.msg = matches[3]
  elif err =~ pegOtherError:
    result.msg = matches[0]
  elif suc.isSuccess:
    result.err = reSuccess
  trimUnitSep result.msg

proc callCCompiler(cmdTemplate, filename, options: string,
                  target: TTarget): TSpec =
  let c = prepareTestArgs(cmdTemplate, filename, options, nimcache = "", target)
  var p = startProcess(command = "gcc", args = c[5 .. ^1],
                       options = {poStdErrToStdOut, poUsePath})
  let outp = p.outputStream
  var x = newStringOfCap(120)
  result.nimout = ""
  result.msg = ""
  result.file = ""
  result.output = ""
  result.line = -1
  while true:
    if outp.readLine(x):
      result.nimout.add(x & '\n')
    elif not running(p):
      break
  close(p)
  if p.peekExitCode == 0:
    result.err = reSuccess

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
  if testamentData0.useColors:
    styledEcho(args)
  else:
    ignoreStyleEcho(args)


proc `$`(x: TResults): string =
  result = """
Tests passed or allowed to fail: $2 / $1 <br />
Tests failed and allowed to fail: $3 / $1 <br />
Tests skipped: $4 / $1 <br />
""" % [$x.total, $x.passed, $x.failedButAllowed, $x.skipped]

proc addResult(r: var TResults, test: TTest, target: TTarget,
               expected, given: string, successOrig: TResultEnum, allowFailure = false) =
  # test.name is easier to find than test.name.extractFilename
  # A bit hacky but simple and works with tests/testament/tshould_not_work.nim
  var name = test.name.replace(DirSep, '/')
  doAssert test.spec.isFlat or (test.spec.matrix.len == 0 and test.spec.targets.len == 0)
  name.add ' ' & $target & " " & test.spec.matrixFlat
  if allowFailure:
    name.add " (allowed to fail) "
  if test.options.len > 0: name.add ' ' & test.options

  let duration = epochTime() - test.startTime
  let success = if test.spec.timeout > 0.0 and duration > test.spec.timeout: reTimeout
                else: successOrig

  let durationStr = duration.formatFloat(ffDecimal, precision = 2).align(5)
  if testamentData0.backendLogging:
    backend.writeTestResult(name = name,
                            category = test.cat.string,
                            target = $target,
                            action = $test.spec.action,
                            result = $success,
                            expected = expected,
                            given = given)
  r.data.addf("$#\t$#\t$#\t$#", name, expected, given, $success)
  template dispNonSkipped(color, outcome) =
    maybeStyledEcho color, outcome, fgCyan, test.debugInfo, alignLeft(name, 60), fgBlue, " (", durationStr, " sec)"
  template disp(msg) =
    maybeStyledEcho styleDim, fgYellow, msg & ' ', styleBright, fgCyan, name
  if success == reSuccess:
    dispNonSkipped(fgGreen, "PASS: ")
  elif success == reDisabled:
    if test.spec.inCurrentBatch: disp("SKIP:")
    else: disp("NOTINBATCH:")
  elif success == reJoined: disp("JOINED:")
  else:
    dispNonSkipped(fgRed, failString)
    maybeStyledEcho styleBright, fgCyan, "Test \"", test.name, "\"", " in category \"", test.cat.string, "\""
    maybeStyledEcho styleBright, fgRed, "Failure: ", $success
    if success in {reBuildFailed, reNimcCrash, reInstallFailed}:
      # expected is empty, no reason to print it.
      echo given
    else:
      maybeStyledEcho fgYellow, "Expected:"
      maybeStyledEcho styleBright, expected, "\n"
      maybeStyledEcho fgYellow, "Gotten:"
      maybeStyledEcho styleBright, given, "\n"
      echo diffStrings(expected, given).output

  if testamentData0.backendLogging and (isAppVeyor or isAzure):
    let (outcome, msg) =
      case success
      of reSuccess:
        ("Passed", "")
      of reDisabled, reJoined:
        ("Skipped", "")
      of reBuildFailed, reNimcCrash, reInstallFailed:
        ("Failed", "Failure: " & $success & '\n' & given)
      else:
        ("Failed", "Failure: " & $success & "\nExpected:\n" & expected & "\n\n" & "Gotten:\n" & given)
    if isAzure:
      azure.addTestResult(name, test.cat.string, int(duration * 1000), msg, success)
    else:
      var p = startProcess("appveyor", args = ["AddTest", test.name.replace("\\", "/") & test.options,
                           "-Framework", "nim-testament", "-FileName",
                           test.cat.string,
                           "-Outcome", outcome, "-ErrorMessage", msg,
                           "-Duration", $(duration * 1000).int],
                           options = {poStdErrToStdOut, poUsePath, poParentStreams})
      discard waitForExit(p)
      close(p)

proc checkForInlineErrors(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  let pegLine = peg"{[^(]*} '(' {\d+} ', ' {\d+} ') ' {[^:]*} ':' \s* {.*}"
  var covered = initIntSet()
  for line in splitLines(given.nimout):

    if line =~ pegLine:
      let file = extractFilename(matches[0])
      let line = try: parseInt(matches[1]) except: -1
      let col = try: parseInt(matches[2]) except: -1
      let kind = matches[3]
      let msg = matches[4]

      if file == extractFilename test.name:
        var i = 0
        for x in expected.inlineErrors:
          if x.line == line and (x.col == col or x.col < 0) and
              x.kind == kind and x.msg in msg:
            covered.incl i
          inc i

  block coverCheck:
    for j in 0..high(expected.inlineErrors):
      if j notin covered:
        var e = test.name
        e.add '('
        e.addInt expected.inlineErrors[j].line
        if expected.inlineErrors[j].col > 0:
          e.add ", "
          e.addInt expected.inlineErrors[j].col
        e.add ") "
        e.add expected.inlineErrors[j].kind
        e.add ": "
        e.add expected.inlineErrors[j].msg

        r.addResult(test, target, e, given.nimout, reMsgsDiffer)
        break coverCheck

    r.addResult(test, target, "", given.msg, reSuccess)
    inc(r.passed)

proc nimoutCheck(expected, given: TSpec): bool =
  result = true
  if expected.nimoutFull:
    if expected.nimout != given.nimout:
      result = false
  elif expected.nimout.len > 0 and not greedyOrderedSubsetLines(expected.nimout, given.nimout):
    result = false

proc cmpMsgs(r: var TResults, expected, given: TSpec, test: TTest, target: TTarget) =
  if expected.inlineErrors.len > 0:
    checkForInlineErrors(r, expected, given, test, target)
  elif strip(expected.msg) notin strip(given.msg):
    r.addResult(test, target, expected.msg, given.msg, reMsgsDiffer)
  elif not nimoutCheck(expected, given):
    r.addResult(test, target, expected.nimout, given.nimout, reMsgsDiffer)
  elif extractFilename(expected.file) != extractFilename(given.file) and
      "internal error:" notin expected.msg:
    r.addResult(test, target, expected.file, given.file, reFilesDiffer)
  elif expected.line != given.line and expected.line != 0 or
       expected.column != given.column and expected.column != 0:
    r.addResult(test, target, $expected.line & ':' & $expected.column,
                      $given.line & ':' & $given.column, reLinesDiffer)
  else:
    r.addResult(test, target, expected.msg, given.msg, reSuccess)
    inc(r.passed)

proc generatedFile(test: TTest, target: TTarget): string =
  if target == targetJS:
    result = test.name.changeFileExt("js")
  else:
    let (_, name, _) = test.name.splitFile
    let ext = targetToExt[target]
    result = nimcacheDir(test.name, test.options, target) / "@m" & name.changeFileExt(ext)

proc needsCodegenCheck(spec: TSpec): bool =
  result = spec.maxCodeSize > 0 or spec.ccodeCheck.len > 0

proc codegenCheck(test: TTest, target: TTarget, spec: TSpec, expectedMsg: var string,
                  given: var TSpec) =
  try:
    let genFile = generatedFile(test, target)
    let contents = readFile(genFile)
    for check in spec.ccodeCheck:
      if check.len > 0 and check[0] == '\\':
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

proc compilerOutputTests(test: TTest, target: TTarget, given: var TSpec,
                         expected: TSpec; r: var TResults) =
  var expectedmsg: string = ""
  var givenmsg: string = ""
  if given.err == reSuccess:
    if expected.needsCodegenCheck:
      codegenCheck(test, target, expected, expectedmsg, given)
      givenmsg = given.msg
    if not nimoutCheck(expected, given):
      given.err = reMsgsDiffer
      expectedmsg = expected.nimout
      givenmsg = given.nimout.strip
  else:
    givenmsg = "$ " & given.cmd & '\n' & given.nimout
  if given.err == reSuccess: inc(r.passed)
  r.addResult(test, target, expectedmsg, givenmsg, given.err)

proc getTestSpecTarget(): TTarget =
  if getEnv("NIM_COMPILE_TO_CPP", "false") == "true":
    result = targetCpp
  else:
    result = targetC

var count = 0

proc equalModuloLastNewline(a, b: string): bool =
  # allow lazy output spec that omits last newline, but really those should be fixed instead
  result = a == b or b.endsWith("\n") and a == b[0 ..< ^1]

proc testSpecHelper(r: var TResults, test: TTest) =
  testamentData0.flatTests.add test

proc runFlatSpec(r: var TResults, test: TTest) =
  var test = test
  var expected = test.spec
  doAssert expected.isFlat
  let extraOptions = expected.matrixFlat
  let target = expected.targetFlat
  let nimcache = test.nimcache
  doAssert nimcache.len > 0
  test.startTime = epochTime()
  template callNimCompilerImpl(): untyped = 
    # xxx this used to also pass: `--stdout --hint:Path:off`, but was done inconsistently
    # with other branches
    callNimCompiler(expected.getCmd, test.name, test.options, nimcache, target, extraOptions)
  case expected.action
  of actionCompile:
    var given = callNimCompilerImpl()
    compilerOutputTests(test, target, given, expected, r)
  of actionRun:
    var given = callNimCompilerImpl()
    if given.err != reSuccess:
      r.addResult(test, target, "", "$ " & given.cmd & '\n' & given.nimout, given.err)
    else:
      let isJsTarget = target == targetJS
      var exeFile = changeFileExt(test.name, if isJsTarget: "js" else: ExeExt)
      if not fileExists(exeFile):
        r.addResult(test, target, expected.output,
                    "executable not found: " & exeFile, reExeNotFound)
      else:
        let nodejs = if isJsTarget: findNodeJs() else: ""
        if isJsTarget and nodejs == "":
          r.addResult(test, target, expected.output, "nodejs binary not in PATH",
                      reExeNotFound)
        else:
          var exeCmd: string
          var args = test.args
          if isJsTarget:
            exeCmd = nodejs
            # see D20210217T215950
            args = @["--unhandled-rejections=strict", exeFile] & args
          else:
            exeCmd = exeFile.dup(normalizeExe)
            if expected.useValgrind != disabled:
              var valgrindOptions = @["--error-exitcode=1"]
              if expected.useValgrind != leaking:
                valgrindOptions.add "--leak-check=yes"
              args = valgrindOptions & exeCmd & args
              exeCmd = "valgrind"
          var (_, buf, exitCode) = execCmdEx2(exeCmd, args, input = expected.input)
          # Treat all failure codes from nodejs as 1. Older versions of nodejs used
          # to return other codes, but for us it is sufficient to know that it's not 0.
          if exitCode != 0: exitCode = 1
          let bufB =
            if expected.sortoutput:
              var buf2 = buf
              buf2.stripLineEnd
              var x = splitLines(buf2)
              sort(x, system.cmp)
              join(x, "\n") & '\n'
            else:
              buf
          if exitCode != expected.exitCode:
            r.addResult(test, target, "exitcode: " & $expected.exitCode,
                              "exitcode: " & $exitCode & "\n\nOutput:\n" &
                              bufB, reExitcodesDiffer)
          elif (expected.outputCheck == ocEqual and not expected.output.equalModuloLastNewline(bufB)) or
              (expected.outputCheck == ocSubstr and expected.output notin bufB):
            given.err = reOutputsDiffer
            r.addResult(test, target, expected.output, bufB, reOutputsDiffer)
          else:
            compilerOutputTests(test, target, given, expected, r)
  of actionReject:
    let given = callNimCompilerImpl()
    cmpMsgs(r, expected, given, test, target)

import std/jsonutils

proc runAccumulatedTests(r: var TResults) =
  if testamentData0.isParallel:
    let n = countProcessors()
    var cmds: seq[string]
    cmds.setLen n
    let file = "/tmp/D20210510T192652.json"
    writeFile(file, $testamentData0.toJson)
    for i in 0..<n:
      # TODO: could also use stdin for communication, or even http
      let data = WorkerData(batch: i, numBatches: n, file: file)
      let cmd = "$1 --worker:$2" % [getAppFilename().quoteShell, ($data.toJson).quoteShell]
      dbg cmd
      cmds.add cmd
    proc progressStatus(idx: int) =
      echo "progress2[all]: $1/$2" % [$idx, $n]
    let m = osproc.execProcesses(cmds, {poEchoCmd, poStdErrToStdOut, poUsePath, poParentStreams}, beforeRunEvent = progressStatus)
    dbg m
    azure.finalize()
    quit m
  else:
    for i, test in testamentData0.flatTests:
      dbg i, testamentData0.flatTests.len
      runFlatSpec(r, test)

let workArg = "--worker:"

proc workerProcess(arg: string) =
  let val = arg[workArg.len..<arg.len]
  dbg val
  let data = val.parseJson.jsonTo(WorkerData)
  testamentData0 = data.file.readFile.parseJson.jsonTo(TestamentData)
  dbg testamentData0.compilerPrefix
  # dbg testamentData0
  # let tests = data.file.readFile.parseJson.jsonTo(TestamentData)
  # testamentData0 = initTestamentData()
  # dbg data
  # let tests = data.file.readFile.parseJson.jsonTo(seq[TTest])
  var r = initResults()
  for i, test in testamentData0.flatTests:
    if i mod data.numBatches == data.batch:
      dbg i, testamentData0.flatTests.len, test.name
      runFlatSpec(r, test)
  dbg "done" # TODO: check resutls

proc targetHelper(r: var TResults, test: TTest) =
  doAssert test.spec.isFlat
  let target = test.spec.targetFlat
  inc(r.total)
  if target notin gTargets: # PRTEMP?
    r.addResult(test, target, "", "", reDisabled)
    inc(r.skipped)
  elif testamentData0.simulate:
    inc count
    echo "testSpec count: ", count, " expected: ", test.spec
  else:
    var test = test
    test.nimcache = nimcacheDir(test.name, test.options, target)
    testSpecHelper(r, test)

proc testSpec(r: var TResults, test: TTest, targets: set[TTarget] = {}) =
  var expected = test.spec
  if expected.parseErrors.len > 0:
    # targetC is a lie, but a parameter is required
    r.addResult(test, targetC, "", expected.parseErrors, reInvalidSpec)
    inc(r.total)
    return
  expected.targets.incl targets
  if expected.targets == {}:
    expected.targets = {getTestSpecTarget()}
  if expected.isFlat:
    var test = test
    test.spec = expected
    if isTestEnabled(r, test): targetHelper(r, test)
  else:
    for spec in flattentSepc(expected):
      var test = test
      test.spec = spec
      if isTestEnabled(r, test): targetHelper(r, test)

proc testSpecWithNimcache(r: var TResults, test: TTest; nimcache: string) {.used.} =
  for spec in flattentSepc(test.spec):
    var test = test
    test.spec = spec
    if isTestEnabled(r, test):
      inc(r.total)
      test.nimcache = nimcache
      testSpecHelper(r, test) # PRTEMP: bugfix: honors matrix

proc testC(r: var TResults, test: TTest, action: TTestAction) =
  # runs C code. Doesn't support any specs, just goes by exit code.
  for spec2 in flattentSepc(test.spec):
    var test = test
    test.spec = spec2
    if isTestEnabled(r, test):
      let tname = test.name.addFileExt(".c")
      inc(r.total)
      maybeStyledEcho "Processing ", fgCyan, extractFilename(tname)
      var given = callCCompiler(getCmd(TSpec()), test.name & ".c", test.options, targetC)
      if given.err != reSuccess:
        r.addResult(test, targetC, "", given.msg, given.err)
      elif action == actionRun:
        let exeFile = changeFileExt(test.name, ExeExt)
        var (_, exitCode) = execCmdEx(exeFile, options = {poStdErrToStdOut, poUsePath})
        if exitCode != 0: given.err = reExitcodesDiffer
      if given.err == reSuccess: inc(r.passed)

proc testExec(r: var TResults, test: TTest) =
  # runs executable or script, just goes by exit code
  for spec2 in flattentSepc(test.spec):
    var test = test
    test.spec = spec2
    if isTestEnabled(r, test):
      inc(r.total)
      let (outp, errC) = execCmdEx(test.options.strip())
      var given: TSpec
      if errC == 0:
        given.err = reSuccess
      else:
        given.err = reExitcodesDiffer
        given.msg = outp

      if given.err == reSuccess: inc(r.passed)
      r.addResult(test, targetC, "", given.msg, given.err)

proc makeTest(test, options: string, cat: Category): TTest =
  result.cat = cat
  result.name = test
  result.options = options
  result.spec = parseSpec(addFileExt(test, ".nim"))
  result.startTime = epochTime()

proc makeRawTest(test, options: string, cat: Category): TTest {.used.} =
  result.cat = cat
  result.name = test
  result.options = options
  result.spec = initSpec(addFileExt(test, ".nim"))
  result.startTime = epochTime()
  result.spec.action = actionCompile
  result.spec.targets = {getTestSpecTarget()}

# TODO: fix these files
const disabledFilesDefault = @[
  "LockFreeHash.nim",
  "sharedstrings.nim",
  "tableimpl.nim",
  "setimpl.nim",
  "hashcommon.nim",

  # Requires compiling with '--threads:on`
  "sharedlist.nim",
  "sharedtables.nim",

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
    disabledFiles = disabledFilesDefault

include categories

proc loadSkipFrom(name: string): seq[string] =
  if name.len == 0: return
  # One skip per line, comments start with #
  # used by `nlvm` (at least)
  for line in lines(name):
    let sline = line.strip()
    if sline.len > 0 and not sline.startsWith('#'):
      result.add sline

proc parseOnOff(val: string): bool =
  case val:
  of "on", "": true
  of "off": false
  else: quit Usage

proc main() =
  let args = commandLineParams()
  if args.len == 1 and args[0].startsWith(workArg):
    workerProcess(args[0])
    return
  var r = initResults()
  testamentData0 = initTestamentData()
  azure.init()
  backend.open()
  var optPrintResults = false
  var optFailing = false
  var targetsStr = ""
  var isMainProcess = true
  var skipFrom = ""

  var p = initOptParser()
  p.next()
  while p.kind in {cmdLongOption, cmdShortOption}:
    case p.key.normalize
    of "print": optPrintResults = parseOnOff(p.val)
    of "verbose": optVerbose = parseOnOff(p.val)
    of "failing": optFailing = parseOnOff(p.val)
    of "pedantic": discard # deadcode refs https://github.com/nim-lang/Nim/issues/16731
    of "targets":
      targetsStr = p.val
      gTargets = parseTargets(targetsStr)
      targetsSet = true
    of "nim":
      testamentData0.compilerPrefix = addFileExt(p.val.absolutePath, ExeExt)
    of "directory":
      setCurrentDir(p.val)
    of "colors": testamentData0.useColors = parseOnOff(p.val)
    of "batch":
      testamentData0.batchArg = p.val
      if p.val != "_" and p.val.len > 0 and p.val[0] in {'0'..'9'}:
        let s = p.val.split("_")
        doAssert s.len == 2, $(p.val, s)
        testamentData0.testamentBatch = s[0].parseInt
        testamentData0.testamentNumBatch = s[1].parseInt
        doAssert testamentData0.testamentNumBatch > 0
        doAssert testamentData0.testamentBatch >= 0 and testamentData0.testamentBatch < testamentData0.testamentNumBatch
    of "simulate": testamentData0.simulate = parseOnOff(p.val)
    of "megatest": testamentData0.useMegatest = parseOnOff(p.val)
    of "backendlogging": testamentData0.backendLogging = parseOnOff(p.val)
    of "skipfrom":
      skipFrom = p.val
    else:
      quit Usage
    p.next()
  if p.kind != cmdArgument:
    quit Usage

  var action = p.key.normalize
  p.next()

  template getSkip =
    testamentData0.skips = loadSkipFrom(skipFrom)

  case action
  of "all":
    var cats: seq[string]
    # cmdLineRest PRTMEP
    for kind, dir in walkDir(testsDir):
      assert testsDir.startsWith(testsDir)
      let cat = dir[testsDir.len .. ^1]
      if kind == pcDir and cat notin ["testdata", "nimcache"]:
        cats.add cat
    if isNimRepoTests(): cats.add AdditionalCategories
    if testamentData0.useMegatest: cats.add "megatest"
    getSkip()
    for i, cati in cats:
      processCategory(r, Category(cati), p.cmdLineRest, testsDir, runJoinableTests = false)
  of "c", "cat", "category":
    getSkip()
    var cat = Category(p.key)
    processCategory(r, cat, p.cmdLineRest, testsDir, runJoinableTests = true)
  of "pcat":
    getSkip()
    # 'pcat' is used for running a category in parallel. Currently the only
    # difference is that we don't want to run joinable tests here as they
    # are covered by the 'megatest' category.
    isMainProcess = false
    var cat = Category(p.key)
    p.next
    processCategory(r, cat, p.cmdLineRest, testsDir, runJoinableTests = false)
  of "p", "pat", "pattern":
    getSkip()
    let pattern = p.key
    p.next
    processPattern(r, pattern, p.cmdLineRest, testamentData0.simulate)
  of "r", "run":
    let (cat, path) = splitTestFile(p.key)
    processSingleTest(r, cat.Category, p.cmdLineRest, path, gTargets, targetsSet)
  of "html":
    generateHtml(resultsFile, optFailing)
  else:
    quit Usage

  runAccumulatedTests(r)

  if optPrintResults:
    if action == "html": openDefaultBrowser(resultsFile)
    else: echo r, r.data
  azure.finalize()
  backend.close()
  var failed = r.total - r.passed - r.skipped
  if failed != 0:
    echo "FAILURE! total: ", r.total, " passed: ", r.passed, " skipped: ",
      r.skipped, " failed: ", failed
    quit(QuitFailure)
  if isMainProcess:
    echo "Used ", testamentData0.compilerPrefix, " to run the tests. Use --nim to override."

if paramCount() == 0:
  quit Usage
main()
