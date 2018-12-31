##[
Global data computed at compile time that application can use at runtime.
]##

type GlobalDataFileEntry = object
  file: cstring
  src: cstring

type GlobalData = object
  files*: array[0..300, GlobalDataFileEntry] ## 'nil' terminated
  filesLen: int
  contextLines: cint

var globalData: GlobalData

proc globalDataSetVars(contextLines: cint) {.compilerproc.} =
  globalData.contextLines = contextLines

proc globalDataSetFileSource(file: cstring, src: cstring) {.compilerproc.} =
  # XXX we could check for duplicates here for DLL support
  globalData.files[globalData.filesLen] = GlobalDataFileEntry(file:file, src:src)
  inc globalData.filesLen

proc formatSurroundingSource(src: cstring, line: int, contextLines: int): cstring =
  ## shows `contextLines` lines around `line` from `src`
  if contextLines == 0: return ""
  let line1 = line - (contextLines div 2)
  let line2 = line1 + contextLines

  var ret: string
  var prefix = ".."
  var linei = 1
  var lineStart = true
  for srci in src:
    if linei < line1:
      # iterate until we reach 1st matching line.
      # Note: in the unlikely case this becomes a bottleneck, we can
      # pre-compute at compile time or caching lines at run time.
      if srci == '\n':
        linei.inc
        lineStart = true
      else:
        lineStart = false
      continue
    if lineStart:
      ret.add '\n'
      if linei == line:
        ret.add "* "
      else:
        ret.add "  "

    if srci == '\n':
      linei.inc
      if linei >= line2: break
      lineStart = true
    else:
      lineStart = false
      ret.add srci

  return ret

proc nimGetSourceLine(file: cstring, line: int): cstring {.compilerRtl, inl, exportc: "$1".} =
  for i in 0..globalData.filesLen-1:
    let data = globalData.files[i]
     # TODO: to abs at CT?
    if data.file != file: continue
    return formatSurroundingSource(data.src, line, globalData.contextLines)
  return "?" # todo
