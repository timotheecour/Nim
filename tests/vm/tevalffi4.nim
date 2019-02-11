discard """
  cmd: "nim c --experimental:allowFFI $file"
  output: '''
foo
1.349858807576003
'''
  disabled: true
"""

when defined(windows):
  proc alloca(n: int): pointer {.importc, header: "<malloc.h>".}
else:
  proc C_alloca(n: uint): pointer {.importc:"C_alloca", dynlib: "/tmp/d02/liballoca2.dylib".}

proc ffi_fun1(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun3(a1:cint, a2:cint, a3:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun2(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}
proc ffi_fun4(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}

# proc c_exp2(a: cint): cint {.importc: "exp_temp", header: "<math.h>".}
proc c_exp2(a: cint): cint {.importc: "exp_temp", header: "<math2.h>".}

proc fun_bak2() =
  # let b3 = c_exp2(123)
  let b4 = ffi_fun1(123, 1234)
  let b5 = ffi_fun1(123, 1234)
  let b6 = ffi_fun2(123, 1234)

  # let b7 = ffi_fun2(123, 1234, 453)
  let b7 = ffi_fun2(123.cint, 1234.cint)
  let b8 = ffi_fun2(10.cint, 11.cint, 12.cint)

  when false:
    var b7 = ffi_fun3(10, 11, 12)
    b7 = ffi_fun3(10, 11, 12)
    b7 = ffi_fun3(10, 11, 12)
    let b8 = ffi_fun3(10, 11, 12)
    let b9 = ffi_fun4(10, 11, 12, 13, 14)

    discard normal_fun6(10, 11, 12, 13, 14)
    discard normal_fun2(10)
    discard normal_fun1()

    # normal_fun1b(10)
    # normal_fun0()
    # discard normal_fun_v(12)
    # discard normal_fun_v(12, 13)

proc main() =
  static:
    fun4()
    when true:
      fun4()

    when defined(case1):
      fun_bug_D20190102T222233()
    # echo fun()
    fun()
    fun2()
    fun3()
    fun_bug()

  # fun()
  # fun2()
  # var buffer = newStringOfCap(50)
  # var buffer = newStringOfCap(50)
  var buffer: string
  buffer.setLen 50
  let temp = addr buffer[0]

main()
