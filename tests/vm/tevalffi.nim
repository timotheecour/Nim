discard """
  cmd: "nim c --experimental:allowFFI $file"
  output: '''
foo
1.349858807576003
'''
"""

# todo: this has no effect (unlike `--experimental:allowFFI`)
# {.push experimental: "allowFFI".}

proc c_printf(frmt: cstring, a0: pointer): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

proc c_printf2(frmt: cstring, a0: pointer): void {.importc: "printf", header: "<stdio.h>", varargs.}
# proc c_printf2(frmt: cstring, a0: pointer) {.importc: "printf", header: "<stdio.h>", varargs.}

proc snprintf*(buffer: pointer, buf_size: uint, format: cstring): cint {.importc: "snprintf", header: "<stdio.h>", varargs .}

proc c_exp(a: float64): float64 {.importc: "exp", header: "<math.h>".}
proc c_exp2(a: cint): cint {.importc: "exp_temp", header: "<math.h>".}

when defined(windows):
  proc alloca(n: int): pointer {.importc, header: "<malloc.h>".}
else:
  proc C_alloca(n: uint): pointer {.importc:"C_alloca", dynlib: "/tmp/d02/liballoca2.dylib".}

proc ffi_fun1(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun3(a1:cint, a2:cint, a3:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun2(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}
proc ffi_fun4(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}

proc normal_fun6(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint = discard
proc normal_fun2(a1:cint): cint = discard
proc normal_fun1(): cint = discard
proc normal_fun1b(a1:cint) = discard
proc normal_fun0() = discard

proc fun() =
  var x = 0.3
  let b1 = c_exp(x)
  let b2 = c_exp(0.4)
  # let b3 = c_exp2(123)
  let b4 = ffi_fun1(123, 1234)
  let b5 = ffi_fun1(123, 1234)
  let b6 = ffi_fun2(123, 1234)
  # let b7 = ffi_fun2(123, 1234, 453)
  var b7 = ffi_fun3(10, 11, 12)
  b7 = ffi_fun3(10, 11, 12)
  b7 = ffi_fun3(10, 11, 12)
  let b8 = ffi_fun3(10, 11, 12)
  let b9 = ffi_fun4(10, 11, 12, 13, 14)

  discard normal_fun6(10, 11, 12, 13, 14)
  discard normal_fun2(10)
  discard normal_fun1()
  normal_fun1b(10)
  normal_fun0()

proc fun_bak1() =
  block:
    c_printf("foo\n")
    # c_printf("foo2:a=%d\n", 123)
    var a = 123
    # c_printf("foo2:a=%d\n", a.addr) # works(prints) but then crashes
    # c_printf2("foo2:a={%d}\n", a.addr)

  block:
    var a: int32 = 123
    var x = 0.3
    let b = c_exp(x)
    let b2 = int(b*1_000_000) # avoid floating point equality
    doAssert b2 == 1349858

  when true:
   block:
    # var buffer: string
    # var buffer: array[50, char]
    # buffer.setLen 50
    # echo buffer
    # let temp = addr buffer[0]
    # let temp = unsafeAddr buffer[0]
    # var buffer: array[]
    # var buffer: array[50, char]
    # var buffer = newStringOfCap(50)
    # let temp = addr buffer[0]
    # # char buffer[50]; 

    var s: cstring = "geeksforgeeks"
    # var buffer2 = cast[ptr UncheckedArray[char]](allocShared(sizeof(T) * size))
    # var buffer2 = alloca(50)
    let n: uint = 50
    var buffer2 = C_alloca(n)
    # var buffer2 = cast[ptr UncheckedArray[char]](buffer)
    # var buffer2 = cast[UncheckedArray[char]](buffer)

    # let j = snprintf(buffer2, 6, "%s\n", s)
    # let j = snprintf(buffer2, n, "%s:%d", s, 1+2)

    # let j = snprintf(buffer2, n, "s1:%s s2:%s", s, s)
    var age: cint = 42
    # var age2=age.addr
    # let j = snprintf(buffer2, n, "s1:%s s2:%s s3:%d", s, s, age2)
    let j = snprintf(buffer2, n, "s1:%s s2:%s s3:%d", s, s, age)
    # let j = snprintf(buffer2, n, "%s", s)

    c_printf("ret={%s}\n", buffer2)
    c_printf("ret={s}\n")
    # echo cast[cstring](buffer2)
    
    # echo "{" & $cast[cstring](buffer2) & "}"
    # echo (j, $type(j))

    # let j = snprintf(buffer, 6, "%s\n", s)

    # let j = snprintf(temp, 6, "%s\n", s)
    # # echo buffer
    # # printf("string:\n%s\ncharacter count = %d\n", 
    # #                                  buffer, j); 

proc main() =
  static:
    when defined(case1):
      fun_bug_D20190102T222233()
  static: fun()
  fun()
  # var buffer = newStringOfCap(50)
  # var buffer = newStringOfCap(50)
  var buffer: string
  buffer.setLen 50
  let temp = addr buffer[0]

main()
