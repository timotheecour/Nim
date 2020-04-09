discard """
  joinable: false
"""

## tests that don't quite fit the mold and are easier to handle via `execCmdEx`
## A few others could be added to here to simplify code.

import std/[strformat,os,osproc,strutils]

proc runCmd(file, options = ""): auto =
  let mode = if existsEnv("NIM_COMPILE_TO_CPP"): "cpp" else: "c"
  const nim = getCurrentCompilerExe()
  const testsDir = currentSourcePath().parentDir
  let fileabs = testsDir / file.unixToNativePath
  doAssert fileabs.existsFile, fileabs
  let cmd = fmt"{nim} {mode} {options} --hints:off {fileabs}"
  result = execCmdEx(cmd)
  when false: # uncomment if you need to debug
    echo result[0]
    echo result[1]

when defined(nimHasLibFFIEnabled):
  block: # mevalffi
    let (output, exitCode) = runCmd("vm/mevalffi.nim", "--experimental:compiletimeFFI")
    let expected = """
hello world stderr
hi stderr
foo
foo:100
foo:101
foo:102:103
foo:102:103:104
foo:0.03:asdf:103:105
ret={s1:foobar s2:foobar age:25 pi:3.14}
"""
    doAssert output == expected, output
    doAssert exitCode == 0

else: # don't run twice the same test
  block: # mstatic_assert
    let (output, exitCode) = runCmd("ccgbugs/mstatic_assert.nim", "-d:caseBad")
    doAssert "sizeof(bool) == 2" in output, output
    doAssert exitCode != 0

  block: # mabi_check
    let (output, exitCode) = runCmd("ccgbugs/mabi_check.nim")
    # on platforms that support _StaticAssert natively, will show full context, eg:
    # error: static_assert failed due to requirement 'sizeof(unsigned char) == 8'
    # "backend & Nim disagree on size for: BadImportcType{int64} [declared in mabi_check.nim(1, 6)]"
    doAssert "sizeof(unsigned char) == " in output, output
    doAssert exitCode != 0

  block: # mimportc_size_check
    block:
      let (_, exitCode) = runCmd("ccgbugs/mimportc_size_check.nim")
      doAssert exitCode == 0
    block:
      let (output, exitCode) = runCmd("ccgbugs/mimportc_size_check.nim", "-d:caseBad")
      doAssert "sizeof(struct Foo2) == 1" in output, output
      doAssert "sizeof(Foo5) == 16" in output, output
      doAssert "sizeof(Foo5) == 3" in output, output
      doAssert "sizeof(struct Foo6) == " in output, output
      doAssert exitCode != 0
