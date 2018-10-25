# Small program that runs the test cases

import strutils, os

const
  dir = "nimpretty/tests/"

var
  failures = 0

when defined(develop):
  const nimp = "bin" / "nimpretty".addFileExt(ExeExt)
  if execShellCmd("nim c -o:$# nimpretty/nimpretty.nim" % [nimp]) != 0:
    quit("FAILURE: compilation of nimpretty failed")
else:
  const nimp = "nimpretty"

proc test(infile, ext: string) =
  var extraArg = ""

  case infile.splitFile.name:
    # can hardcode custom options here
    of "simple4": extraArg = "--indentSpaces:4"
    of "simple5": extraArg = "--margin:100"
    else: discard

  let cmd = "$# -o:$# --backup:off $# $#" % [nimp, infile.changeFileExt(ext), extraArg, infile]
  # echo cmd
  if execShellCmd(cmd) != 0:
    quit("FAILURE")
  let nimFile = splitFile(infile).name
  let expected = dir / "expected" / nimFile & ".nim"
  let produced = dir / nimFile.changeFileExt(ext)
  if strip(readFile(expected)) != strip(readFile(produced)):
    echo "FAILURE: files differ: ", nimFile
    discard execShellCmd("diff -uNdr " & expected & " " & produced)
    failures += 1
  else:
    echo "SUCCESS: files identical: ", nimFile

for t in walkFiles(dir / "*.nim"):
  test(t, "pretty")
  # also test that pretty(pretty(x)) == pretty(x)
  test(t.changeFileExt("pretty"), "pretty2")

  removeFile(t.changeFileExt("pretty"))
  removeFile(t.changeFileExt("pretty2"))


if failures > 0: quit($failures & " failures occurred.")
