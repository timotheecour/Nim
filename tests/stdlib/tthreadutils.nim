discard """
joinable: false
"""

#[
run with: `-d:nimTthreadutilsNum:10000` for stress testing
]#

when defined nimTthreadutilsSub:
  import std/threadutils
  var thr: array[10, Thread[int]]
  var count = 0
  proc threadFunc(a: int) {.thread.} =
    onceGlobal: count.inc
    doAssert count == 1
  proc main =
    for i, t in mpairs(thr):
      t.createThread(threadFunc, i)
    joinThreads(thr)
  main()

else:
  from stdtest/specialpaths import buildDir
  import os, strformat
  proc main =
    block: # onceGlobal
      const nim = getCurrentCompilerExe()
      const exe = buildDir / currentSourcePath.lastPathPart
      const file = currentSourcePath
      let cmd = fmt"{nim} c -d:nimTthreadutilsSub --threads -o:{exe} {file}"
      doAssert execShellCmd(cmd) == 0
      const nimTthreadutilsNum {.intdefine.} = 100 # in CI, save some time
      for i in 0..<nimTthreadutilsNum:
        let ret = execShellCmd(exe)
        doAssert ret == 0, $i

  main()

  import std/threadutils

  block: #onceThread
    var count = 0
    for i in 0..<10:
      onceThread:
        count.inc
        echo i
    doAssert count == 1
