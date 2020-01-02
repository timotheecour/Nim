#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the ability to call native procs from libraries.
# It is not possible to do this in a platform independent way, unfortunately.
# However, the interface has been designed to take platform differences into
# account and been ported to all major platforms.

{.push stack_trace: off.}

const
  NilLibHandle: LibHandle = nil

proc nimLoadLibraryError(path: string) =
  # carefully written to avoid memory allocation:
  cstderr.rawWrite("could not load: ")
  cstderr.rawWrite(path)
  cstderr.rawWrite("\n")
  when not defined(nimDebugDlOpen) and not defined(windows):
    cstderr.rawWrite("compile with -d:nimDebugDlOpen for more information\n")
  when defined(windows) and defined(guiapp):
    # Because console output is not shown in GUI apps, display error as message box:
    const prefix = "could not load: "
    var msg: array[1000, char]
    copyMem(msg[0].addr, prefix.cstring, prefix.len)
    copyMem(msg[prefix.len].addr, path.cstring, min(path.len + 1, 1000 - prefix.len))
    discard MessageBoxA(nil, msg[0].addr, nil, 0)
  quit(1)

proc procAddrError(name: cstring) {.compilerproc, nonReloadable, hcrInline.} =
  # carefully written to avoid memory allocation:
  cstderr.rawWrite("could not import: ")
  cstderr.rawWrite(name)
  cstderr.rawWrite("\n")
  quit(1)

# this code was inspired from Lua's source code:
# Lua - An Extensible Extension Language
# Tecgraf: Computer Graphics Technology Group, PUC-Rio, Brazil
# http://www.lua.org
# mailto:info@lua.org

when defined(posix):
  #
  # =========================================================================
  # This is an implementation based on the dlfcn interface.
  # The dlfcn interface is available in Linux, SunOS, Solaris, IRIX, FreeBSD,
  # NetBSD, AIX 4.2, HPUX 11, and probably most other Unix flavors, at least
  # as an emulation layer on top of native functions.
  # =========================================================================
  #

  # c stuff:
  when defined(linux) or defined(macosx):
    const RTLD_NOW = cint(2)
  else:
    var
      RTLD_NOW {.importc: "RTLD_NOW", header: "<dlfcn.h>".}: cint

  proc dlclose(lib: LibHandle) {.importc, header: "<dlfcn.h>".}
  proc dlopen(path: cstring, mode: cint): LibHandle {.
      importc, header: "<dlfcn.h>".}
  proc dlsym(lib: LibHandle, name: cstring): ProcAddr {.
      importc, header: "<dlfcn.h>".}

  proc dlerror(): cstring {.importc, header: "<dlfcn.h>".}

  proc nimUnloadLibrary(lib: LibHandle) =
    dlclose(lib)

  proc nimLoadLibrary(path: string): LibHandle =
    result = dlopen(path, RTLD_NOW)
    when defined(nimDebugDlOpen):
      let error = dlerror()
      if error != nil:
        cstderr.rawWrite(error)
        cstderr.rawWrite("\n")

  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr =
    result = dlsym(lib, name)
    if result == nil: procAddrError(name)

elif defined(windows) or defined(dos):
  #
  # =======================================================================
  # Native Windows Implementation
  # =======================================================================
  #
  when defined(cpp):
    type
      THINSTANCE {.importc: "HINSTANCE".} = object
        x: pointer
    proc getProcAddress(lib: THINSTANCE, name: cstring): ProcAddr {.
        importcpp: "(void*)GetProcAddress(@)", header: "<windows.h>", stdcall.}
  else:
    type
      THINSTANCE {.importc: "HINSTANCE".} = pointer
    proc getProcAddress(lib: THINSTANCE, name: cstring): ProcAddr {.
        importc: "GetProcAddress", header: "<windows.h>", stdcall.}

  proc freeLibrary(lib: THINSTANCE) {.
      importc: "FreeLibrary", header: "<windows.h>", stdcall.}
  proc winLoadLibrary(path: cstring): THINSTANCE {.
      importc: "LoadLibraryA", header: "<windows.h>", stdcall.}

  proc nimUnloadLibrary(lib: LibHandle) =
    freeLibrary(cast[THINSTANCE](lib))

  proc nimLoadLibrary(path: string): LibHandle =
    result = cast[LibHandle](winLoadLibrary(path))

  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr =
    result = getProcAddress(cast[THINSTANCE](lib), name)
    echo "nimGetProcAddr.0"
    echo name
    echo "nimGetProcAddr.0b"
    defer:
      echo "nimGetProcAddr.1:begin"
      echo result == nil
      echo "nimGetProcAddr.1:done"
    if result != nil: return
    const decoratedLength = 250
    var decorated: array[decoratedLength, char]
    decorated[0] = '_'
    echo name
    var m = 1
    while m < (decoratedLength - 5):
      if name[m - 1] == '\x00': break
      decorated[m] = name[m - 1]
      inc(m)
    decorated[m] = '@'
    for i in countup(0, 50):
      var k = i * 4
      if k div 100 == 0:
        if k div 10 == 0:
          m = m + 1
        else:
          m = m + 2
      else:
        m = m + 3
      echo "nimGetProcAddr.3:" & $m
      decorated[m + 1] = '\x00'
      while true:
        decorated[m] = chr(ord('0') + (k %% 10))
        dec(m)
        k = k div 10
        if k == 0: break
      echo defined(nimNoArrayToCstringConversion)
      #echo decorated
      when defined(nimNoArrayToCstringConversion):
        result = getProcAddress(cast[THINSTANCE](lib), addr decorated)
      else:
        result = getProcAddress(cast[THINSTANCE](lib), decorated)
      echo "nimGetProcAddr.5.1"
      if result != nil: return
      # TODO: break?
      echo "nimGetProcAddr.6"
    procAddrError(name)
    echo "nimGetProcAddr.7"

elif defined(genode):

  proc nimUnloadLibrary(lib: LibHandle) {.
    error: "nimUnloadLibrary not implemented".}

  proc nimLoadLibrary(path: string): LibHandle {.
    error: "nimLoadLibrary not implemented".}

  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr {.
    error: "nimGetProcAddr not implemented".}

elif defined(nintendoswitch):
  proc nimUnloadLibrary(lib: LibHandle) =
    cstderr.rawWrite("nimUnLoadLibrary not implemented")
    cstderr.rawWrite("\n")
    quit(1)

  proc nimLoadLibrary(path: string): LibHandle =
    cstderr.rawWrite("nimLoadLibrary not implemented")
    cstderr.rawWrite("\n")
    quit(1)


  proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr =
    cstderr.rawWrite("nimGetProAddr not implemented")
    cstderr.rawWrite(name)
    cstderr.rawWrite("\n")
    quit(1)

else:
  {.error: "no implementation for dyncalls".}

{.pop.}
