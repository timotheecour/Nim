discard """
  cmd: "nim c --experimental:allowFFI $file"
  output: '''
foo
1.349858807576003
'''
"""

# todo: this has no effect (unlike `--experimental:allowFFI`)
# {.push experimental: "allowFFI".}

# proc c_printf(frmt: cstring, a0: pointer): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

proc c_printf2(frmt: cstring, a0: pointer): void {.importc: "printf", header: "<stdio.h>", varargs.}
# proc c_printf2(frmt: cstring, a0: pointer) {.importc: "printf", header: "<stdio.h>", varargs.}

proc snprintf*(buffer: pointer, buf_size: uint, format: cstring): cint {.importc: "snprintf", header: "<stdio.h>", varargs .}

proc c_exp(a: float64): float64 {.importc: "exp", header: "<math.h>".}
# proc c_exp2(a: cint): cint {.importc: "exp_temp", header: "<math.h>".}
proc c_exp2(a: cint): cint {.importc: "exp_temp", header: "<math2.h>".}

when defined(windows):
  proc alloca(n: int): pointer {.importc, header: "<malloc.h>".}
else:
  proc C_alloca(n: uint): pointer {.importc:"C_alloca", dynlib: "/tmp/d02/liballoca2.dylib".}

proc ffi_fun1(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun3(a1:cint, a2:cint, a3:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib".}
proc ffi_fun2(a1:cint, a2:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}
proc ffi_fun4(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint {.importc, dynlib: "/tmp/d02/libplugin_temp.dylib", varargs.}

proc c_malloc(size:uint):pointer {.importc:"malloc", header: "<stdlib.h>".}

# PRTEMP
proc c_sizeof(size:uint):pointer {.importc:"sizeof", header: "<stdlib.h>".}

proc normal_fun6(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint = discard
proc normal_fun2(a1:cint): cint = discard
proc normal_fun1(): cint = discard
proc normal_fun1b(a1:cint) = discard
proc normal_fun0() = discard
proc normal_fun_v(a1:cint): cint {.varargs.} = discard


template toUncheckedArray*[T](a: pointer): untyped=
  cast[ptr UncheckedArray[T]](a)

# proc fun(): string =
# proc fun(): cint =
proc fun() =
  block:
    c_printf("foo\n")
    c_printf("foo:%d\n", 100)
    c_printf("foo:%d\n", 101.cint)
    c_printf("foo:%d:%d\n", 102.cint, 103.cint)
    let temp = 104.cint
    c_printf("foo:%d:%d:%d\n", 102.cint, 103.cint, temp)
    var temp2 = 105.cint
    c_printf("foo:%g:%s:%d:%d\n", 0.03, "asdf", 103.cint, temp2)

    var a = 123
    var a2 = a.addr
    c_printf("foo2:a=%d\n", a.addr)
    c_printf("foo2:a=%d\n", a2) # TODO: different bw CT RT

    # c_printf("foo2:a=%ul\n", a2)

  block:
    var x = 0.3
    let b = c_exp(x)
    let b2 = int(b*1_000_000) # avoid floating point equality
    doAssert b2 == 1349858
    doAssert c_exp(0.3) == c_exp(x)

  block:
    let n: uint = 50
    # var buffer2: pointer = c_malloc(n)
    # var s: cstring = "hello_world"
    # var age: cint = 25
    # let j = snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)
    # let j = snprintf(buffer2, n, "s1")
    # let j = snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)

    # var temp: cstring = cast[cstring](buffer2)
    # var temp: string

    # var ret: string

  when false:
      when false:
        # let temp2 = toUncheckedArray[char](buffer2)
        var i=0
        when false:
         while true:
          let ai = temp2[i]
          echo type(ai)
          # let ai = buffer2.int + i
          if ai == '\0': break
          ret.add ai
          i.inc

      # return ret
      # return 1234.cint

      # return buffer2
      # return $temp


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

when false:
  type MyFoo {.exportc.} = object
    a: int
    a2: cint
    a3: string

  when false:
   {.emit: """
  template<typename T> size_t getSize(T*a){
    return sizeof(*a);
  }
  """.}

  {.emit: """
  void getSize2(){
    printf("s:%d\n", (int) sizeof(MyFoo)); // IMPROVE
    // return sizeof(*a);
  }
  """.}

proc fun2() =
  when true:
   block:
    let n: uint = 50
    var buffer2: pointer = c_malloc(n)

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
    # var buffer2 = C_alloca(n) # works
    # var buffer2 = cast[ptr UncheckedArray[char]](buffer)

    # var buffer2 = cast[UncheckedArray[char]](buffer)


    # var buffer: array[50, char]
    # var buffer2 = cast[ptr UncheckedArray[char]](buffer)
    # var buffer2 = addr buffer[0]
    # var buffer2: pointer = addr buffer[0]

    # let j = snprintf(buffer2, n, "%s\n", s)
    # let j = snprintf(buffer2, n, "%s:%d", s, 1+2)

    # let j = snprintf(buffer2, n, "s1:%s s2:%s", s, s)
    var age: cint = 25
    let j = snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)

    # let j = snprintf(buffer2, n, "s1:%s s2:%s s3:%d", s, s, age)
    # let j = snprintf(buffer2, n, "%s", s)

    c_printf("ret={%s}\n", buffer2)
    # let temp = Foo.sizeof
    # echo (temp:temp)
    # echo cast[cstring](buffer2)
    
    # echo "{" & $cast[cstring](buffer2) & "}"
    # echo (j, $type(j))

    # let j = snprintf(buffer, 6, "%s\n", s)

    # let j = snprintf(temp, 6, "%s\n", s)
    # # echo buffer
    # # printf("string:\n%s\ncharacter count = %d\n", 
    # #                                  buffer, j); 


proc fun3() =
  block:
    let n: uint = 50
    var buffer2: pointer = c_malloc(n)
    var s: cstring = "geeksforgeeks"
    var age: cint = 25
    let j = snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)
    c_printf("ret={%s}\n", buffer2)


proc fun_bug() =
  block:
    var a = 123
    var a2 = a.addr
  block:
    let n: uint = 50
    var buffer2: pointer = c_malloc(n)

proc fun4() =
  # DATE:D20190211T143540
  let x = 123.0
  let b3 = c_exp(x)
  # let b4 = c_exp(123.0)
  let b4 = c_exp(123)
  echo (b3 == b4)
  let b5 = c_exp2(123)

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
