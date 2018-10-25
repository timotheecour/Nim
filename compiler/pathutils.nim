import os
import ospaths2

export ospaths2

## MOVE
proc extractFilename*(x: AbsoluteFile): string {.borrow.}
proc quoteShell*(x: AbsoluteFile): string {.borrow.}
proc quoteShell*(x: AbsoluteDir): string {.borrow.}
proc cmpPaths*(x, y: AbsoluteDir): int {.borrow.}
proc splitFile*(x: AbsoluteFile): tuple[dir: AbsoluteDir, name, ext: string] =
  let (a, b, c) = splitFile(x.string)
  result = (dir: AbsoluteDir(a), name: b, ext: c)

proc changeFileExt*(x: AbsoluteFile; ext: string): AbsoluteFile {.borrow.}
proc changeFileExt*(x: RelativeFile; ext: string): RelativeFile {.borrow.}

proc addFileExt*(x: AbsoluteFile; ext: string): AbsoluteFile {.borrow.}
proc addFileExt*(x: RelativeFile; ext: string): RelativeFile {.borrow.}

##
proc copyFile*(source, dest: AbsoluteFile) =
  os.copyFile(source.string, dest.string)

proc removeFile*(x: AbsoluteFile) {.borrow.}

proc fileExists*(x: AbsoluteFile): bool {.borrow.}
proc dirExists*(x: AbsoluteDir): bool {.borrow.}

proc createDir*(x: AbsoluteDir) {.borrow.}

proc writeFile*(x: AbsoluteFile; content: string) {.borrow.}
