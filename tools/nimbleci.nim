#[
nimble wide CI
]#

import std/[os, strutils, json, tables, macros, times, osproc, sequtils]
import ".." / compiler/asciitables

const pkgList = """
# add more packages here; lines starting with `#` are skipped

#TODO: jester@#head or jester? etc
jester

cligen

# CT failures
libffi

glob
nimongo
nimx
karax
freeimage
regex
nimpy
zero_functional
arraymancer
inim
c2nim
sdl1
iterutils
gnuplot
nimpb
lazy
"""

proc getNimblePkgPath(nimbleDir: string): string =
  nimbleDir / "packages_official.json"

template withDir*(dir, body) =
  let old = getCurrentDir()
  try:
    setCurrentDir(dir)
    body
  finally:
    setCurrentdir(old)

proc execEcho(cmd: string): bool =
  echo "running cmd:", cmd
  let status = execShellCmd(cmd)
  if status != 0:
    echo "failed: cmd: `", cmd, "` status:", status
  result = status == 0

type Stats = object
  seenOK: int
  foundOK: int                ## whether nimble can still access it
  urlOK: int                  ## some packages are invalid
  cloneOK: int
  tasksOK: int
  installOK: int
  developOK: int
  buildOK: int
  testOK: int
  totalTime: float
  tasks: seq[string]

type TestResult = ref object
  # we can add further test fields here (eg running time, mem usage etc)
  pkg: string
  stats: Stats

type TestResultAll = object
  tests: seq[TestResult]
  stats: Stats
  failures: seq[string]

proc parseNimble(data: JsonNode): Table[string, JsonNode] =
  result = initTable[string, JsonNode]()
  for a in data:
    result[a["name"].getStr()] = a

type Config = ref object
  pkgs: Table[string, JsonNode]
  pkgInstall: string
  pkgClone: string

  ## what to run
  runInstall: bool
  runDevelop: bool
  runClone: bool
  runBuild: bool
  runTasks: bool
  runTest: bool

proc runCIPackage(config: Config, data: var TestResult) =
  let t0 = epochTime()
  defer:
    data.stats.totalTime = epochTime() - t0
  let pkg = data.pkg
  echo "runCIPackage:", pkg
  data.stats.seenOK.inc
  if not(pkg in config.pkgs):
    echo "not found: ", pkg
    return
  data.stats.foundOK.inc

  let pkgJson = config.pkgs[pkg]
  if not pkgJson.hasKey "url":
    echo "url not found: ", (pkg, pkgJson)
    return

  data.stats.urlOK.inc
  let url = pkgJson["url"].getStr()

  if config.runInstall:
    let cmd = "nimble install --nimbleDir:$# -y $# " % [config.pkgInstall,
        pkg]
    if execEcho(cmd):
      data.stats.installOK.inc

  echo config.pkgClone
  createDir config.pkgClone
  withDir config.pkgClone:
    if not existsDir pkg:
      if config.runDevelop:
        if execEcho("nimble develop --nimbleDir:$# -y $#" % [
            config.pkgInstall,
          pkg]):
          data.stats.developOK.inc
      if config.runClone:
        if not execEcho("git clone $# $#" % [url, pkg]):
          return              # nothing left to do without a clone
    data.stats.cloneOK.inc

  withDir config.pkgClone / pkg:
    if config.runTasks:
      # TODO :wrap w echo
      let (outp, errC) = execCmdEx("nimble tasks")
      if errC != 0:
        echo "nimble tasks failed"
      else:
        data.stats.tasksOK.inc
        for line in outp.splitLines:
          var line = line
          line = line.strip
          # todo: pass `--hints:off --verbosity:0` once nimble supports it
          if (line.startsWith "Warning:") or (line.startsWith "Hint:"):
            continue
          data.stats.tasks.add line.split[0]

    if config.runBuild:
      data.stats.buildOK = ord execEcho("nimble build -N --nimbleDir:$#" % [
          config.pkgInstall])
    if config.runTest:
      # note: see caveat https://github.com/nim-lang/nimble/issues/558
      # where `nimble test` suceeds even if no tests are defined.
      data.stats.testOK = ord execEcho "nimble test"

proc tabFormat[T](result: var string, a: T) =
  # TODO: more generic, flattens anything into 1 line of a table
  var first = true
  for k, v in fieldPairs(a):
    if first: first = false
    else: result.add "\t"
    result.add k
    result.add ":\t"
    result.add $v

proc `$`(a: TestResultAll): string =
  var s = ""
  for i, ai in a.tests:
    s.tabFormat (i: i, pkg: ai.pkg)
    s.add "\t"
    s.tabFormat ai.stats
    s.add "\n"
  when true: # add total
    s.add("TOTAL\t$#\t\t\t" % [$a.tests.len])
    s.tabFormat a.stats
    s.add "\n"
  result = "TestResultAll:\n" & alignTable(s)

proc updateField[T](a: var T, b: T) =
  when T is SomeNumber:
    a+=b
  else:
    # string etc
    discard

proc updateResults(a: var TestResultAll, b: TestResult) =
  a.tests.add b
  if b.stats.testOK == 0: a.failures.add b.pkg
  for ai, bi in fields(a.stats, b.stats): updateField(ai, bi)

proc getPkgs(): seq[string] =
  for a in pkgList.splitLines:
    var a = a.strip
    if a.len == 0: continue
    if a.startsWith '#': continue
    result.add a

  echo (pkgs: result)

proc runCIPackages*(dirOutput: string) =
  echo "runCIPackages", (dirOutput: dirOutput, pid: getCurrentProcessId())
    # pending #9616 pid useful to kill process, since ^C doesn't work inside exec

  var data: TestResult
  var config = Config(
    pkgInstall: dirOutput/"nimbleRoot",
    pkgClone: dirOutput/"nimbleCloneRoot",
    # runInstall: true,
    # runDevelop: true,
    runClone: true,
    # runBuild: true,
    runTasks: true,
    # runTest: true,
  )

  doAssert execEcho "nimble refresh --nimbleDir:$#" % [config.pkgInstall]
  # doing it by hand until nimble exposes this API
  config.pkgs = config.pkgInstall.getNimblePkgPath.readFile.parseJson.parseNimble()

  # lets pkgs = getPkgs()
  # let pkgs = config.pkgs.mapIt(it["name"].getStr())
  # let pkgs = config.pkgs.mapIt(it["name"].getStr()) # todo: blocked by my Map PR
  var pkgs: seq[string]
  for k, v in config.pkgs:
    pkgs.add k

  var testsAll: TestResultAll
  for i, pkg in pkgs:
    var data = TestResult(pkg: pkg)
    runCIPackage(config, data)
    updateResults(testsAll, data)
    if data.stats.testOK == 0: echo "FAILURE:CI pkg:" & pkg
    echo testsAll
  # consider sending a notification, gather stats on failed packages

when isMainModule:
  runCIPackages(".")
