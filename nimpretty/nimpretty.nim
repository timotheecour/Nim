#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Standard tool for pretty printing.

when not defined(nimpretty):
  {.error: "This needs to be compiled with --define:nimPretty".}

import ../compiler / [idents, msgs, ast, syntaxes, renderer, options, pathutils]

import parseopt, strutils, os

const
  Version = "0.1"
  Usage = "nimpretty - Nim Pretty Printer Version " & Version & """

  (c) 2017 Andreas Rumpf
Usage:
  nimpretty [options] file.nim
Options:
  --backup:on|off     create a backup file before overwritting (default: ON)
  --output:file       set the output file (default: overwrite the .nim file)
  --indentSpaces:n    indents use `n` spaces (default: 0=infer from 1st indent)
  --version           show the version
  --help              show this help
"""

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(Version & "\n")
  stdout.flushFile()
  quit(0)

proc prettyPrint(infile, outfile: string, conf: ConfigRef) =
  let fileIdx = fileInfoIdx(conf, AbsoluteFile infile)
  conf.outFile = AbsoluteFile outfile
  when defined(nimpretty2):
    discard parseFile(fileIdx, newIdentCache(), conf)
  else:
    let tree = parseFile(fileIdx, newIdentCache(), conf)
    renderModule(tree, infile, outfile, {}, fileIdx, conf)

proc main =
  var conf = newConfigRef()
  var infile, outfile: string
  var backup = true
  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      infile = key.addFileExt(".nim")
    of cmdLongoption, cmdShortOption:
      case normalize(key)
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      of "backup": backup = parseBool(val)
      of "indentspaces": conf.nimprettyOpt.indentSpaces = parseInt(val)
      of "output", "o": outfile = val
      else: writeHelp()
    of cmdEnd: assert(false) # cannot happen
  if infile.len == 0:
    quit "[Error] no input file."
  if backup:
    os.copyFile(source=infile, dest=changeFileExt(infile, ".nim.backup"))
  if outfile.len == 0: outfile = infile
  prettyPrint(infile, outfile, conf)

main()
