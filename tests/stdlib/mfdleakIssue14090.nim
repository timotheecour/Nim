#[
## issue #14090
this module is to help investigate this issue.
Running this will show that windows fails this test all the time
module named `m` to avoid running it automatically.
]#

import osproc, strutils

proc testFdLeak() =
  let n = 100
  var count = [0,0]
  let options = ["", "-d:nimInheritHandles"]
  for j in 0..<options.len:
    for i in 0..<n:
      let cmd = "nim c -r $1 tests/stdlib/tfdleak.nim" % options[j]
      echo ("runCustomTest", options[j], j, i, n)
      let (outp, status) = execCmdEx(cmd)
      doAssert status == 0
      if "leaked" in outp:
        count[j].inc
        echo count, "\n", outp
  doAssert count == [0,0], $count

when isMainModule: testFdLeak()
