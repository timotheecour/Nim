#[
## TODO
* this will show `CC: dragonbox`:
`nim r -f --hint:cc --filenames:abs --processing:filenames --hint:conf nonexistant`
we could refine the logic to delay compilation until cgen phase instead.
(see also `tests/osproc/treadlines.nim`)
* allow some form of reporting so that caller can tell whether a dependency
  doesn't exist, or was already built, or builds with error, or builds successfully, etc.
* allow some way to expose this to user code
]#

import std/[osproc, os, strutils]
import msgs, options, ast, lineinfos, extccomp, pathutils

const prefix = "__" # prevent clashing with user files

type Job = object
  input: string
  copts: string

proc addDependencyImpl(conf: ConfigRef, name: string, info: TLineInfo, jobs: seq[Job], linkerFlags = "") =
  if name in conf.dependencies: return
  conf.dependencies.add name
  # xxx we could also build this under $nimb/build/
  let dir = conf.getNimcacheDir().string
  createDir dir
  for job in jobs:
    let objFile = dir / ("$1_$2_$3.o" % [prefix, name, job.input.splitFile.name])
    if optForceFullMake in conf.globalOptions or not objFile.fileExists:
      # xxx use `getCompilerExe`
      when defined(osx):
        let cppExe = "clang++"
      else:
        let cppExe = "g++"
      when defined(linux):
          # xxx: avoids linker errors:
          # relocation R_X86_64_32S against `.rodata' can not be used when making a PIE object; recompile with -fPIE
        let options = "-fPIE"
      else:
        let options = ""
      let inputFile = conf.libpath.string / job.input
      let cmd = "$# -c $# $# -O3 -o $# $#" % [cppExe.quoteShell, job.copts, options, objFile.quoteShell, inputFile.quoteShell]
      # xxx use md5 hash to recompile if needed
      writePrettyCmdsStderr displayProgressCC(conf, inputFile, cmd)
      let (outp, status) = execCmdEx(cmd)
      if status != 0:
        localError(conf, info, "building '$#' failed: cmd: $#\noutput:\n$#" % [name, cmd, outp])
    conf.addExternalFileToLink(objFile.AbsoluteFile)
  if linkerFlags.len > 0:
    conf.addLinkOption(linkerFlags)

proc addDependency*(conf: ConfigRef, name: string, info: TLineInfo) =
  case name
  of "drachennest_dragonbox":
    let copts = "-std=c++11"
    var jobs: seq[Job]
    for file in "impl.cc dragonbox.cc schubfach_32.cc schubfach_64.cc".split:
      jobs.add Job(input: "vendor/drachennest" / file, copts: copts)
    addDependencyImpl(conf, name, info, jobs = jobs)
  of "dragonbox_dragonbox":
    let dir = "vendor/dragonbox"
    let includeDir = conf.libpath.string / dir / "include"
    let copts = "-std=c++17 -I $#" % includeDir.quoteShell
    var jobs: seq[Job]
    for file in "impl.cc dragonbox_to_chars.cpp".split:
      jobs.add Job(input: dir / file, copts: copts)
    addDependencyImpl(conf, name, info, jobs = jobs, linkerFlags = "-lc++")
  else:
    localError(conf, info, "expected: 'dragonbox', got: '$1'" % name)
