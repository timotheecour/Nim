{.push profiler: off.}

when false:
  proc timn_BREAK*() {.exportc, noinline.} =
    #[
    MOVE FACTOR
    # CHECKME: seems to work but make sure cross platform; eg __declspec(noinline); {.exportc, codegenDecl: """__attribute__((noinline)) void BREAK_5()""".}
    noinline needed, otherwise can be skipped in -d:release etc

    TODO: how to make a symbol static? (not exported)

    ## BUG:
    duplicate symbol '_timn_BREAK' in:
      /Users/timothee/.cache/nim/nim_r/stdlib_assertions.nim.c.o
      /Users/timothee/.cache/nim/nim_r/stdlib_system.nim.c.o
    ld: 1 duplicate symbol for architecture x86_64
    ]#
    proc c_printf(frmt: cstring) {.importc: "printf", header: "<stdio.h>", varargs.}
    c_printf("in timn_BREAK\n")
    # echo "in timn_BREAK" # IMPROVE: wo this, proc is skipped
    discard

when hostOS == "standalone":
  include "$projectpath/panicoverride"

  proc sysFatal(exceptn: typedesc, message: string) {.inline.} =
    panic(message)

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline.} =
    rawoutput(message)
    panic(arg)

elif defined(nimQuirky) and not defined(nimscript):
  import ansi_c

  proc name(t: typedesc): string {.magic: "TypeTrait".}

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    var buf = newStringOfCap(200)
    add(buf, "Error: unhandled exception: ")
    add(buf, message)
    add(buf, arg)
    add(buf, " [")
    add(buf, name exceptn)
    add(buf, "]")
    cstderr.rawWrite buf
    quit 1

  proc sysFatal(exceptn: typedesc, message: string) {.inline, noreturn.} =
    sysFatal(exceptn, message, "")

else:
  proc sysFatal(exceptn: typedesc, message: string) {.inline, noreturn.} =
    # timn_BREAK()
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message
    raise e

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    # timn_BREAK()
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message & arg
    raise e
{.pop.}
