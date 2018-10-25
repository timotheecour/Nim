#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Path handling utilities for Nim. Strictly typed code in order
## to avoid the never ending time sink in getting path handling right.
## Might be a candidate for the stdlib later.

include "system/inclrtl"
import strutils
import osdefs

## distinct types
type
  AbsoluteFile* = distinct string
  AbsoluteDir* = distinct string
  RelativeFile* = distinct string
  RelativeDir* = distinct string

proc isEmpty*(x: AbsoluteFile): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: AbsoluteDir): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: RelativeFile): bool {.inline.} = x.string.len == 0
proc isEmpty*(x: RelativeDir): bool {.inline.} = x.string.len == 0

type
  PathIter = object
    i, prev: int
    notFirst: bool

proc isAbsolute*(path: string): bool {.rtl, noSideEffect, extern: "nos$1".} =
  ## Checks whether a given `path` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  runnableExamples:
    doAssert(not "".isAbsolute)
    doAssert(not ".".isAbsolute)
    when defined(posix):
      doAssert "/".isAbsolute
      doAssert(not "a/".isAbsolute)

  if len(path) == 0: return false

  when doslikeFileSystem:
    var len = len(path)
    result = (path[0] in {'/', '\\'}) or
              (len > 1 and path[0] in {'a'..'z', 'A'..'Z'} and path[1] == ':')
  elif defined(macos):
    # according to https://perldoc.perl.org/File/Spec/Mac.html `:a` is a relative path
    result = path[0] != ':'
  elif defined(RISCOS):
    result = path[0] == '$'
  elif defined(posix):
    result = path[0] == '/'

proc hasNext(it: PathIter; x: string): bool =
  it.i < x.len

proc next(it: var PathIter; x: string): (int, int) =
  it.prev = it.i
  if not it.notFirst and x[it.i] in {DirSep, AltSep}:
    # absolute path:
    inc it.i
  else:
    while it.i < x.len and x[it.i] notin {DirSep, AltSep}: inc it.i
  if it.i > it.prev:
    result = (it.prev, it.i-1)
  elif hasNext(it, x):
    result = next(it, x)

  # skip all separators:
  while it.i < x.len and x[it.i] in {DirSep, AltSep}: inc it.i
  it.notFirst = true

iterator dirs(x: string): (int, int) =
  var it: PathIter
  while hasNext(it, x): yield next(it, x)

when false:
  iterator dirs(x: string): (int, int) =
    var i = 0
    var first = true
    while i < x.len:
      let prev = i
      if first and x[i] in {DirSep, AltSep}:
        # absolute path:
        inc i
      else:
        while i < x.len and x[i] notin {DirSep, AltSep}: inc i
      if i > prev:
        yield (prev, i-1)
      first = false
      # skip all separators:
      while i < x.len and x[i] in {DirSep, AltSep}: inc i

proc isDot(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] and x[bounds[0]] == '.'

proc isDotDot(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] + 1 and x[bounds[0]] == '.' and x[bounds[0]+1] == '.'

proc isSlash(x: string; bounds: (int, int)): bool =
  bounds[1] == bounds[0] and x[bounds[0]] in {DirSep, AltSep}

proc canon(x: string; result: var string; state: var int) =
  # state: 0th bit set if isAbsolute path. Other bits count
  # the number of path components.
  for b in dirs(x):
    if (state shr 1 == 0) and isSlash(x, b):
      result.add DirSep
      state = state or 1
    elif result.len > (state and 1) and isDotDot(x, b):
      var d = result.len
      # f/..
      while d > (state and 1) and result[d-1] != DirSep:
        dec d
      if d > 0: setLen(result, d-1)
    elif isDot(x, b):
      discard "discard the dot"
    elif b[1] >= b[0]:
      if result.len > 0 and result[^1] != DirSep:
        result.add DirSep
      result.add substr(x, b[0], b[1])
    inc state, 2

proc canon(x: string): string =
  # - Turn multiple slashes into single slashes.
  # - Resolve '/foo/../bar' to '/bar'.
  # - Remove './' from the path.
  result = newStringOfCap(x.len)
  var state = 0
  canon(x, result, state)

when FileSystemCaseSensitive:
  template `!=?`(a, b: char): bool = toLowerAscii(a) != toLowerAscii(b)
else:
  template `!=?`(a, b: char): bool = a != b

proc relativeTo(full, base: string; sep = DirSep): string =
  if full.len == 0: return ""
  var f, b: PathIter
  var ff = (0, -1)
  var bb = (0, -1) # (int, int)
  result = newStringOfCap(full.len)
  # skip the common prefix:
  while f.hasNext(full) and b.hasNext(base):
    ff = next(f, full)
    bb = next(b, base)
    let diff = ff[1] - ff[0]
    if diff != bb[1] - bb[0]: break
    var same = true
    for i in 0..diff:
      if full[i + ff[0]] !=? base[i + bb[0]]:
        same = false
        break
    if not same: break
    ff = (0, -1)
    bb = (0, -1)
  #  for i in 0..diff:
  #    result.add base[i + bb[0]]

  # /foo/bar/xxx/ -- base
  # /foo/bar/baz  -- full path
  #   ../baz
  # every directory that is in 'base', needs to add '..'
  while true:
    if bb[1] >= bb[0]:
      if result.len > 0 and result[^1] != sep:
        result.add sep
      result.add ".."
    if not b.hasNext(base): break
    bb = b.next(base)

  # add the rest of 'full':
  while true:
    if ff[1] >= ff[0]:
      if result.len > 0 and result[^1] != sep:
        result.add sep
      for i in 0..ff[1] - ff[0]:
        result.add full[i + ff[0]]
    if not f.hasNext(full): break
    ff = f.next(full)

when true:
  proc eqImpl(x, y: string): bool =
    when FileSystemCaseSensitive:
      result = cmpIgnoreCase(canon x, canon y) == 0
    else:
      result = canon(x) == canon(y)

  proc `==`*(x, y: AbsoluteFile): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: AbsoluteDir): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: RelativeFile): bool = eqImpl(x.string, y.string)
  proc `==`*(x, y: RelativeDir): bool = eqImpl(x.string, y.string)

  proc `/`*(base: AbsoluteDir; f: RelativeFile): AbsoluteFile =
    #assert isAbsolute(base.string)
    assert(not isAbsolute(f.string))
    result = AbsoluteFile newStringOfCap(base.string.len + f.string.len)
    var state = 0
    canon(base.string, result.string, state)
    canon(f.string, result.string, state)

  proc `/`*(base: AbsoluteDir; f: RelativeDir): AbsoluteDir =
    #assert isAbsolute(base.string)
    assert(not isAbsolute(f.string))
    result = AbsoluteDir newStringOfCap(base.string.len + f.string.len)
    var state = 0
    canon(base.string, result.string, state)
    canon(f.string, result.string, state)

  proc relativeTo*(fullPath: AbsoluteFile, baseFilename: AbsoluteDir;
                   sep = DirSep): RelativeFile =
    RelativeFile(relativeTo(fullPath.string, baseFilename.string, sep))

  proc toAbsolute*(file: string; base: AbsoluteDir): AbsoluteFile =
    if isAbsolute(file): result = AbsoluteFile(file)
    else: result = base / RelativeFile file

when isMainModule and defined(posix):
  doAssert canon"/foo/../bar" == "/bar"
  doAssert canon"foo/../bar" == "bar"

  doAssert canon"/f/../bar///" == "/bar"
  doAssert canon"f/..////bar" == "bar"

  doAssert canon"../bar" == "../bar"
  doAssert canon"/../bar" == "/../bar"

  doAssert canon("foo/../../bar/") == "../bar"
  doAssert canon("./bla/blob/") == "bla/blob"
  doAssert canon(".hiddenFile") == ".hiddenFile"
  doAssert canon("./bla/../../blob/./zoo.nim") == "../blob/zoo.nim"

  doAssert canon("C:/file/to/this/long") == "C:/file/to/this/long"
  doAssert canon("") == ""
  doAssert canon("foobar") == "foobar"
  doAssert canon("f/////////") == "f"

  doAssert relativeTo("/foo/bar//baz.nim", "/foo") == "bar/baz.nim"

  doAssert relativeTo("/Users/me/bar/z.nim", "/Users/other/bad") == "../../me/bar/z.nim"

  doAssert relativeTo("/Users/me/bar/z.nim", "/Users/other") == "../me/bar/z.nim"
  doAssert relativeTo("/Users///me/bar//z.nim", "//Users/") == "me/bar/z.nim"
  doAssert relativeTo("/Users/me/bar/z.nim", "/Users/me") == "bar/z.nim"
  doAssert relativeTo("", "/users/moo") == ""
  doAssert relativeTo("foo", "") == "foo"

  doAssert AbsoluteDir"/Users/me///" / RelativeFile"z.nim" == AbsoluteFile"/Users/me/z.nim"
  doAssert relativeTo("/foo/bar.nim", "/foo/") == "bar.nim"

when isMainModule and defined(windows):
  let nasty = string(AbsoluteDir(r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\linkedPkgs\pkgB-#head\../../simplePkgs/pkgB-#head/") / RelativeFile"pkgA/module.nim")
  doAssert nasty == r"C:\Users\rumpf\projects\nim\tests\nimble\nimbleDir\simplePkgs\pkgB-#head\pkgA\module.nim"
