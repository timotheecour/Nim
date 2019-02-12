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

template toUncheckedArray*[T](a: pointer): untyped=
  cast[ptr UncheckedArray[T]](a)

proc normal_fun6(a1:cint, a2:cint, a3:cint, a4:cint, a5:cint): cint = discard
proc normal_fun2(a1:cint): cint = discard
proc normal_fun1(): cint = discard
proc normal_fun1b(a1:cint) = discard
proc normal_fun0() = discard
proc normal_fun_v(a1:cint): cint {.varargs.} = discard

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

    var age: cint = 25
    let j = snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)
    c_printf("ret={%s}\n", buffer2)
    # let temp = Foo.sizeof
    # echo (temp:temp)
    # echo cast[cstring](buffer2)
    
    # echo "{" & $cast[cstring](buffer2) & "}"
    # echo (j, $type(j))

  block:
    var a: seq[char]
    a.setLen 10
    for i in 0..<len(a): a[i] = 'a'
    var a2 = a[0].addr
    # var a2 = a.addr
    echo a2[]

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


  block: # c_snprintf, c_malloc, c_free
    let n: uint = 50
    # var buffer0 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    # var buffer2: cstring = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    # var buffer2: pointer = c_malloc(n)

    var buffer0: seq[char]
    buffer0.setLen n+100
    for i in 0..<len(buffer0): buffer0[i] = char(ord('a')+i)
    # var buffer2: pointer = buffer0[1].addr
    # var buffer2 = buffer0[1].addr
    # var buffer2 = cast[pointer](buffer0[0].addr)
    # var buffer2 = cast[pointer](buffer0[0].unsafeAddr)
    # var buffer2 = cast[pointer](buffer0.addr)
    # var buffer2 = cast[ptr](buffer0.addr)
    # var buffer2 = buffer0[1].addr # ptr char
    var buffer1 = cast[int](buffer0[1].addr)
    echo buffer1
    var buffer2 = cast[pointer](buffer1+10)

    # echo type(buffer2)
    # var buffer2 = cast[ptr](buffer0[0].addr)
    # echo buffer2
    # echo buffer2[]


    # var buffer2: pointer = buffer0[0].addr
    # var buffer2: pointer = buffer0[0].unsafeAddr
    var s: cstring = "foobar"
    var age: cint = 25
    let j = c_snprintf(buffer2, n, "s1:%s s2:%s age:%d pi:%g", s, s, age, 3.14)
    c_printf("ret={%s}\n", buffer2)
    # c_free(buffer2) # CHECKME: not sure it has an effect

    # var temp: cstring = cast[cstring](buffer2)


proc fun6()=
  # var buffer = newStringOfCap(50)
  # var buffer = newStringOfCap(50)
  var buffer: string
  buffer.setLen 50
  let temp = addr buffer[0]


when false: # sizeof cannot work
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
