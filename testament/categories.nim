#
#
#            Nim Tester
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Include for the tester that contains test suites that test special features
## of the compiler.

const
  specialCategories = [
    "assert",
    "async",
    "debugger",
    "dll",
    "examples",
    "flags",
    "gc",
    "io",
    "js",
    "lib",
    "longgc",
    "manyloc",
    "nimble-all",
    "nimble-core",
    "nimble-extra",
    "niminaction",
    "rodfiles",
    "threads",
    "untestable",
    "stdlib",
    "testdata",
    "nimcache",
    "coroutines",
    "osproc",
    "shouldfail",
    "dir with space"
  ]

# included from tester.nim
# ---------------- ROD file tests ---------------------------------------------

const
  rodfilesDir = "tests/rodfiles"

proc delNimCache(filename, options: string) =
  for target in low(TTarget)..high(TTarget):
    let dir = nimcacheDir(filename, options, target)
    try:
      removeDir(dir)
    except OSError:
      echo "[Warning] could not delete: ", dir

proc runRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: string, clearCacheFirst=false) =
    if clearCacheFirst: delNimCache(filename, options)
    testSpec r, makeTest(rodfilesDir / filename, options, cat)


  # test basic recompilation scheme:
  test "hallo", true
  test "hallo"
  when false:
    # test incremental type information:
    test "hallo2"

  # test type converters:
  test "aconv", true
  test "bconv"

  # test G, A, B example from the documentation; test init sections:
  test "deada", true
  test "deada2"

  when false:
    # test method generation:
    test "bmethods", true
    test "bmethods2"

    # test generics:
    test "tgeneric1", true
    test "tgeneric2"

proc compileRodFiles(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped, clearCacheFirst=true) =
    if clearCacheFirst: delNimCache(filename, options)
    testSpec r, makeTest(rodfilesDir / filename, options, cat)

  # test DLL interfacing:
  test "gtkex1", true
  test "gtkex2"

# --------------------- flags tests -------------------------------------------

proc flagTests(r: var TResults, cat: Category, options: string) =
  # --genscript
  const filename = "tests"/"flags"/"tgenscript"
  const genopts = " --genscript"
  let nimcache = nimcacheDir(filename, genopts, targetC)
  testSpec r, makeTest(filename, genopts, cat)

  when defined(windows):
    testExec r, makeTest(filename, " cmd /c cd " & nimcache &
                         " && compile_tgenscript.bat", cat)

  elif defined(posix):
    testExec r, makeTest(filename, " sh -c \"cd " & nimcache &
                         " && sh compile_tgenscript.sh\"", cat)

  # Run
  testExec r, makeTest(filename, " " & nimcache / "tgenscript", cat)

# --------------------- DLL generation tests ----------------------------------

proc safeCopyFile(src, dest: string) =
  try:
    copyFile(src, dest)
  except OSError:
    echo "[Warning] could not copy: ", src, " to ", dest

proc runBasicDLLTest(c, r: var TResults, cat: Category, options: string) =
  const rpath = when defined(macosx):
      " --passL:-rpath --passL:@loader_path"
    else:
      ""

  var test1 = makeTest("lib/nimrtl.nim", options & " --app:lib -d:createNimRtl --threads:on", cat)
  test1.spec.action = actionCompile
  testSpec c, test1
  var test2 = makeTest("tests/dll/server.nim", options & " --app:lib -d:useNimRtl --threads:on" & rpath, cat)
  test2.spec.action = actionCompile
  testSpec c, test2

  when defined(Windows):
    # windows looks in the dir of the exe (yay!):
    var nimrtlDll = DynlibFormat % "nimrtl"
    safeCopyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)
  else:
    # posix relies on crappy LD_LIBRARY_PATH (ugh!):
    const libpathenv = when defined(haiku):
                         "LIBRARY_PATH"
                       else:
                         "LD_LIBRARY_PATH"
    var libpath = getEnv(libpathenv).string
    # Temporarily add the lib directory to LD_LIBRARY_PATH:
    putEnv(libpathenv, "tests/dll" & (if libpath.len > 0: ":" & libpath else: ""))
    defer: putEnv(libpathenv, libpath)
    var nimrtlDll = DynlibFormat % "nimrtl"
    safeCopyFile("lib" / nimrtlDll, "tests/dll" / nimrtlDll)

  testSpec r, makeTest("tests/dll/client.nim", options & " -d:useNimRtl --threads:on" & rpath,
                       cat)

proc dllTests(r: var TResults, cat: Category, options: string) =
  # dummy compile result:
  var c = initResults()

  runBasicDLLTest c, r, cat, options
  runBasicDLLTest c, r, cat, options & " -d:release"
  when not defined(windows):
    # still cannot find a recent Windows version of boehm.dll:
    runBasicDLLTest c, r, cat, options & " --gc:boehm"
    runBasicDLLTest c, r, cat, options & " -d:release --gc:boehm"

# ------------------------------ GC tests -------------------------------------

proc gcTests(r: var TResults, cat: Category, options: string) =
  template testWithNone(filename: untyped) =
    testSpec r, makeTest("tests/gc" / filename, options &
                  " --gc:none", cat)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release --gc:none", cat)

  template testWithoutMs(filename: untyped) =
    testSpec r, makeTest("tests/gc" / filename, options, cat)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release", cat)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release -d:useRealtimeGC", cat)

  template testWithoutBoehm(filename: untyped) =
    testWithoutMs filename
    testSpec r, makeTest("tests/gc" / filename, options &
                  " --gc:markAndSweep", cat)
    testSpec r, makeTest("tests/gc" / filename, options &
                  " -d:release --gc:markAndSweep", cat)
  template test(filename: untyped) =
    testWithoutBoehm filename
    when not defined(windows) and not defined(android):
      # AR: cannot find any boehm.dll on the net, right now, so disabled
      # for windows:
      testSpec r, makeTest("tests/gc" / filename, options &
                    " --gc:boehm", cat)
      testSpec r, makeTest("tests/gc" / filename, options &
                    " -d:release --gc:boehm", cat)

  testWithoutBoehm "foreign_thr"
  test "gcemscripten"
  test "growobjcrash"
  test "gcbench"
  test "gcleak"
  test "gcleak2"
  testWithoutBoehm "gctest"
  testWithNone "gctest"
  test "gcleak3"
  test "gcleak4"
  # Disabled because it works and takes too long to run:
  #test "gcleak5"
  testWithoutBoehm "weakrefs"
  test "cycleleak"
  testWithoutBoehm "closureleak"
  testWithoutMs "refarrayleak"

  testWithoutBoehm "tlists"
  testWithoutBoehm "thavlak"

  test "stackrefleak"
  test "cyclecollector"

proc longGCTests(r: var TResults, cat: Category, options: string) =
  when defined(windows):
    let cOptions = "-ldl -DWIN"
  else:
    let cOptions = "-ldl"

  var c = initResults()
  # According to ioTests, this should compile the file
  testSpec c, makeTest("tests/realtimeGC/shared", options, cat)
  #        ^- why is this not appended to r? Should this be discarded?
  testC r, makeTest("tests/realtimeGC/cmain", cOptions, cat), actionRun
  testSpec r, makeTest("tests/realtimeGC/nmain", options & "--threads: on", cat)

# ------------------------- threading tests -----------------------------------

proc threadTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)
    testSpec r, makeTest(filename, options & " -d:release", cat)
    testSpec r, makeTest(filename, options & " --tlsEmulation:on", cat)
  for t in os.walkFiles("tests/threads/t*.nim"):
    test(t)

# ------------------------- IO tests ------------------------------------------

proc ioTests(r: var TResults, cat: Category, options: string) =
  # We need readall_echo to be compiled for this test to run.
  # dummy compile result:
  var c = initResults()
  testSpec c, makeTest("tests/system/helpers/readall_echo", options, cat)
  testSpec r, makeTest("tests/system/tio", options, cat)

# ------------------------- async tests ---------------------------------------
proc asyncTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)
  for t in os.walkFiles("tests/async/t*.nim"):
    test(t)

# ------------------------- debugger tests ------------------------------------

proc debuggerTests(r: var TResults, cat: Category, options: string) =
  var t = makeTest("tools/nimgrep", options & " --debugger:on", cat)
  t.spec.action = actionCompile
  testSpec r, t

# ------------------------- JS tests ------------------------------------------

proc jsTests(r: var TResults, cat: Category, options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest(filename, options & " -d:nodejs", cat), {targetJS}
    testSpec r, makeTest(filename, options & " -d:nodejs -d:release", cat), {targetJS}

  for t in os.walkFiles("tests/js/t*.nim"):
    test(t)
  for testfile in ["exception/texceptions", "exception/texcpt1",
                   "exception/texcsub", "exception/tfinally",
                   "exception/tfinally2", "exception/tfinally3",
                   "actiontable/tactiontable", "method/tmultimjs",
                   "varres/tvarres0", "varres/tvarres3", "varres/tvarres4",
                   "varres/tvartup", "misc/tints", "misc/tunsignedinc",
                   "async/tjsandnativeasync"]:
    test "tests/" & testfile & ".nim"

  for testfile in ["strutils", "json", "random", "times", "logging"]:
    test "lib/pure/" & testfile & ".nim"

# ------------------------- nim in action -----------

proc testNimInAction(r: var TResults, cat: Category, options: string) =
  let options = options & " --nilseqs:on"

  template test(filename: untyped) =
    testSpec r, makeTest(filename, options, cat)

  template testJS(filename: untyped) =
    testSpec r, makeTest(filename, options, cat), {targetJS}

  template testCPP(filename: untyped) =
    testSpec r, makeTest(filename, options, cat), {targetCPP}

  let tests = [
    "niminaction/Chapter1/various1",
    "niminaction/Chapter2/various2",
    "niminaction/Chapter2/resultaccept",
    "niminaction/Chapter2/resultreject",
    "niminaction/Chapter2/explicit_discard",
    "niminaction/Chapter2/no_def_eq",
    "niminaction/Chapter2/no_iterator",
    "niminaction/Chapter2/no_seq_type",
    "niminaction/Chapter3/ChatApp/src/server",
    "niminaction/Chapter3/ChatApp/src/client",
    "niminaction/Chapter3/various3",
    "niminaction/Chapter6/WikipediaStats/concurrency_regex",
    "niminaction/Chapter6/WikipediaStats/concurrency",
    "niminaction/Chapter6/WikipediaStats/naive",
    "niminaction/Chapter6/WikipediaStats/parallel_counts",
    "niminaction/Chapter6/WikipediaStats/race_condition",
    "niminaction/Chapter6/WikipediaStats/sequential_counts",
    "niminaction/Chapter6/WikipediaStats/unguarded_access",
    "niminaction/Chapter7/Tweeter/src/tweeter",
    "niminaction/Chapter7/Tweeter/src/createDatabase",
    "niminaction/Chapter7/Tweeter/tests/database_test",
    "niminaction/Chapter8/sdl/sdl_test"
    ]

  # Verify that the files have not been modified. Death shall fall upon
  # whoever edits these hashes without dom96's permission, j/k. But please only
  # edit when making a conscious breaking change, also please try to make your
  # commit message clear and notify me so I can easily compile an errata later.
  const refHashes = @[
    "51afdfa84b3ca3d810809d6c4e5037ba",
    "30f07e4cd5eaec981f67868d4e91cfcf",
    "d14e7c032de36d219c9548066a97e846",
    "b335635562ff26ec0301bdd86356ac0c",
    "6c4add749fbf50860e2f523f548e6b0e",
    "76de5833a7cc46f96b006ce51179aeb1",
    "705eff79844e219b47366bd431658961",
    "a1e87b881c5eb161553d119be8b52f64",
    "2d706a6ec68d2973ec7e733e6d5dce50",
    "c11a013db35e798f44077bc0763cc86d",
    "3e32e2c5e9a24bd13375e1cd0467079c",
    "a5452722b2841f0c1db030cf17708955",
    "dc6c45eb59f8814aaaf7aabdb8962294",
    "69d208d281a2e7bffd3eaf4bab2309b1",
    "ec05666cfb60211bedc5e81d4c1caf3d",
    "da520038c153f4054cb8cc5faa617714",
    "59906c8cd819cae67476baa90a36b8c1",
    "9a8fe78c588d08018843b64b57409a02",
    "8b5d28e985c0542163927d253a3e4fc9",
    "783299b98179cc725f9c46b5e3b5381f",
    "1a2b3fba1187c68d6a9bfa66854f3318",
    "80f9c3e594a798225046e8a42e990daf"
  ]

  for i, test in tests:
    let filename = "tests" / test.addFileExt("nim")
    let testHash = getMD5(readFile(filename).string)
    doAssert testHash == refHashes[i], "Nim in Action test " & filename & " was changed."
  # Run the tests.
  for testfile in tests:
    test "tests/" & testfile & ".nim"
  let jsFile = "tests/niminaction/Chapter8/canvas/canvas_test.nim"
  testJS jsFile
  let cppFile = "tests/niminaction/Chapter8/sfml/sfml_test.nim"
  testCPP cppFile

# ------------------------- manyloc -------------------------------------------

proc findMainFile(dir: string): string =
  # finds the file belonging to ".nim.cfg"; if there is no such file
  # it returns the some ".nim" file if there is only one:
  const cfgExt = ".nim.cfg"
  result = ""
  var nimFiles = 0
  for kind, file in os.walkDir(dir):
    if kind == pcFile:
      if file.endsWith(cfgExt): return file[.. ^(cfgExt.len+1)] & ".nim"
      elif file.endsWith(".nim"):
        if result.len == 0: result = file
        inc nimFiles
  if nimFiles != 1: result.setlen(0)

proc manyLoc(r: var TResults, cat: Category, options: string) =
  for kind, dir in os.walkDir("tests/manyloc"):
    if kind == pcDir:
      when defined(windows):
        if dir.endsWith"nake": continue
      if dir.endsWith"named_argument_bug": continue
      let mainfile = findMainFile(dir)
      if mainfile != "":
        var test = makeTest(mainfile, options, cat)
        test.spec.action = actionCompile
        testSpec r, test

proc compileExample(r: var TResults, pattern, options: string, cat: Category) =
  for test in os.walkFiles(pattern):
    var test = makeTest(test, options, cat)
    test.spec.action = actionCompile
    testSpec r, test

proc testStdlib(r: var TResults, pattern, options: string, cat: Category) =
  var files: seq[string]

  proc isValid(file: string): bool =
    for dir in parentDirs(file, inclusive = false):
      if dir.lastPathPart in ["includes", "nimcache"]:
        # eg: lib/pure/includes/osenv.nim gives: Error: This is an include file for os.nim!
        return false
    let name = extractFilename(file)
    if name.splitFile.ext != ".nim": return false
    for namei in disabledFiles:
      # because of `LockFreeHash.nim` which has case
      if namei.cmpPaths(name) == 0: return false
    return true

  for testFile in os.walkDirRec(pattern):
    if isValid(testFile):
      files.add testFile

  files.sort # reproducible order
  for testFile in files:
    let contents = readFile(testFile).string
    var testObj = makeTest(testFile, options, cat)
    #[
    TODO:
    this logic is fragile:
    false positives (if appears in a comment), or false negatives, eg
    `when defined(osx) and isMainModule`.
    Instead of fixing this, a much better way, is to extend
    https://github.com/nim-lang/Nim/issues/9581 to stdlib modules as follows:
    * add these to megatest
    * patch compiler so `isMainModule` is true when -d:isMainModuleIsAlwaysTrue
    That'll give speedup benefit, and we don't have to patch stdlib files.
    ]#
    if "when isMainModule" notin contents:
      testObj.spec.action = actionCompile
    testSpec r, testObj

# ----------------------------- nimble ----------------------------------------
type
  PackageFilter = enum
    pfCoreOnly
    pfExtraOnly
    pfAll

var nimbleDir = getEnv("NIMBLE_DIR").string
if nimbleDir.len == 0: nimbleDir = getHomeDir() / ".nimble"
let
  nimbleExe = findExe("nimble")
  #packageDir = nimbleDir / "pkgs" # not used
  packageIndex = nimbleDir / "packages.json"

proc waitForExitEx(p: Process): int =
  var outp = outputStream(p)
  var line = newStringOfCap(120).TaintedString
  while true:
    if outp.readLine(line):
      discard
    else:
      result = peekExitCode(p)
      if result != -1: break
  close(p)

proc getPackageDir(package: string): string =
  ## TODO - Replace this with dom's version comparison magic.
  var commandOutput = execCmdEx("nimble path $#" % package)
  if commandOutput.exitCode != QuitSuccess:
    return ""
  else:
    result = commandOutput[0].string

iterator listPackages(filter: PackageFilter): tuple[name, url: string] =
  let packageList = parseFile(packageIndex)
  for package in packageList.items():
    let
      name = package["name"].str
      url = package["url"].str
      isCorePackage = "nim-lang" in normalize(url)
    case filter:
    of pfCoreOnly:
      if isCorePackage:
        yield (name, url)
    of pfExtraOnly:
      if not isCorePackage:
        yield (name, url)
    of pfAll:
      yield (name, url)

proc testNimblePackages(r: var TResults, cat: Category, filter: PackageFilter) =
  if nimbleExe == "":
    echo("[Warning] - Cannot run nimble tests: Nimble binary not found.")
    return

  if execCmd("$# update" % nimbleExe) == QuitFailure:
    echo("[Warning] - Cannot run nimble tests: Nimble update failed.")
    return

  let packageFileTest = makeTest("PackageFileParsed", "", cat)
  try:
    for name, url in listPackages(filter):
      var test = makeTest(name, "", cat)
      echo(url)
      let
        installProcess = startProcess(nimbleExe, "", ["install", "-y", name])
        installStatus = waitForExitEx(installProcess)
      installProcess.close
      if installStatus != QuitSuccess:
        r.addResult(test, targetC, "", "", reInstallFailed)
        continue

      let
        buildPath = getPackageDir(name).strip
        buildProcess = startProcess(nimbleExe, buildPath, ["build"])
        buildStatus = waitForExitEx(buildProcess)
      buildProcess.close
      if buildStatus != QuitSuccess:
        r.addResult(test, targetC, "", "", reBuildFailed)
      r.addResult(test, targetC, "", "", reSuccess)
    r.addResult(packageFileTest, targetC, "", "", reSuccess)
  except JsonParsingError:
    echo("[Warning] - Cannot run nimble tests: Invalid package file.")
    r.addResult(packageFileTest, targetC, "", "", reBuildFailed)


# ----------------------------------------------------------------------------

const AdditionalCategories = ["debugger", "examples", "lib", "megatest"]

proc `&.?`(a, b: string): string =
  # candidate for the stdlib?
  result = if b.startswith(a): b else: a & b

proc processSingleTest(r: var TResults, cat: Category, options, test: string) =
  let test = "tests" & DirSep &.? cat.string / test
  let target = if cat.string.normalize == "js": targetJS else: targetC
  if existsFile(test):
    testSpec r, makeTest(test, options, cat), {target}
  else:
    echo "[Warning] - ", test, " test does not exist"

proc isJoinableSpec(spec: TSpec): bool =
  result = not spec.sortoutput and
    spec.action == actionRun and
    not fileExists(spec.file.changeFileExt("cfg")) and
    not fileExists(spec.file.changeFileExt("nims")) and
    not fileExists(parentDir(spec.file) / "nim.cfg") and
    not fileExists(parentDir(spec.file) / "config.nims") and
    spec.cmd.len == 0 and
    spec.err != reDisabled and
    not spec.unjoinable and
    spec.exitCode == 0 and
    spec.input.len == 0 and
    spec.nimout.len == 0 and
    spec.outputCheck != ocSubstr and
    spec.ccodeCheck.len == 0 and
    (spec.targets == {} or spec.targets == {targetC})

proc norm(s: var string) =
  while true:
    let tmp = s.replace("\n\n", "\n")
    if tmp == s: break
    s = tmp
  s = s.strip

proc isTestFile*(file: string): bool =
  let (dir, name, ext) = splitFile(file)
  result = ext == ".nim" and name.startsWith("t")

proc runJoinedTest(r: var TResults, cat: Category, testsDir: string) =
  ## returs a list of tests that have problems
  var specs: seq[TSpec] = @[]
  for kind, dir in walkDir(testsDir):
    assert testsDir.startsWith(testsDir)
    let cat = dir[testsDir.len .. ^1]
    if kind == pcDir and cat notin specialCategories:
      for file in walkDirRec(testsDir / cat):
        if not isTestFile(file): continue
        let spec = parseSpec(file)
        if isJoinableSpec(spec):
          specs.add spec

  echo "joinable specs: ", specs.len

  if simulate:
    var s = "runJoinedTest: "
    for a in specs: s.add a.file & " "
    echo s
    return

  var megatest: string
  for runSpec in specs:
    megatest.add "import r\""
    megatest.add runSpec.file
    megatest.add "\"\n"

  writeFile("megatest.nim", megatest)

  const args = ["c", "-d:testing", "--listCmd", "megatest.nim"]
  echo ("megatest:PRTEMP",command, args, options, getCurrentDir())
  var (buf, exitCode) = execCmdEx2(command = compilerPrefix, args = args, options = {poStdErrToStdOut, poUsePath}, input = "")
  if exitCode != 0:
    echo buf
    quit("megatest compilation failed")

  (buf, exitCode) = execCmdEx("./megatest")
  if exitCode != 0:
    echo buf
    quit("megatest execution failed")

  norm buf
  writeFile("outputGotten.txt", buf)
  var outputExpected = ""
  for i, runSpec in specs:
    outputExpected.add runSpec.output.strip
    outputExpected.add '\n'
  norm outputExpected

  if buf != outputExpected:
    writeFile("outputExpected.txt", outputExpected)
    discard execShellCmd("diff -uNdr outputExpected.txt outputGotten.txt")
    echo "output different!"
    quit 1
  else:
    echo "output OK"
    removeFile("outputGotten.txt")
    removeFile("megatest.nim")
  #testSpec r, makeTest("megatest", options, cat)

# ---------------------------------------------------------------------------

proc processCategory(r: var TResults, cat: Category, options, testsDir: string,
                     runJoinableTests: bool) =
  case cat.string.normalize
  of "rodfiles":
    when false:
      compileRodFiles(r, cat, options)
      runRodFiles(r, cat, options)
  of "js":
    # only run the JS tests on Windows or Linux because Travis is bad
    # and other OSes like Haiku might lack nodejs:
    if not defined(linux) and isTravis:
      discard
    else:
      jsTests(r, cat, options)
  of "dll":
    dllTests(r, cat, options)
  of "flags":
    flagTests(r, cat, options)
  of "gc":
    gcTests(r, cat, options)
  of "longgc":
    longGCTests(r, cat, options)
  of "debugger":
    debuggerTests(r, cat, options)
  of "manyloc":
    manyLoc r, cat, options
  of "threads":
    threadTests r, cat, options & " --threads:on"
  of "io":
    ioTests r, cat, options
  of "async":
    asyncTests r, cat, options
  of "lib":
    testStdlib(r, "lib/pure/", options, cat)
    testStdlib(r, "lib/packages/docutils/", options, cat)
  of "examples":
    compileExample(r, "examples/*.nim", options, cat)
    compileExample(r, "examples/gtk/*.nim", options, cat)
    compileExample(r, "examples/talk/*.nim", options, cat)
  of "nimble-core":
    testNimblePackages(r, cat, pfCoreOnly)
  of "nimble-extra":
    testNimblePackages(r, cat, pfExtraOnly)
  of "nimble-all":
    testNimblePackages(r, cat, pfAll)
  of "niminaction":
    testNimInAction(r, cat, options)
  of "untestable":
    # We can't test it because it depends on a third party.
    discard # TODO: Move untestable tests to someplace else, i.e. nimble repo.
  of "megatest":
    runJoinedTest(r, cat, testsDir)
  else:
    var testsRun = 0

    var files: seq[string]
    for file in walkDirRec("tests" & DirSep &.? cat.string):
        if isTestFile(file): files.add file
    files.sort # give reproducible order

    for i, name in files:
      var test = makeTest(name, options, cat)
      if runJoinableTests or not isJoinableSpec(test.spec) or cat.string in specialCategories:
        discard "run the test"
      else:
        test.spec.err = reJoined
      testSpec r, test
      inc testsRun
    if testsRun == 0:
      echo "[Warning] - Invalid category specified \"", cat.string, "\", no tests were run"
