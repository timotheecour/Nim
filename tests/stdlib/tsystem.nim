discard """
  joinable: false
  targets: "c cpp js"
"""

# xxx consolidate / refactor with tests/system/tsystem_misc.nim, etc

template disableVM(body): untyped =
  when nimvm: discard
  else: body

template main() =
  doAssert abs(-3) == 3
  disableVM:
    doAssertRaises(OverflowDefect): discard abs(int8.low)
    doAssertRaises(OverflowDefect): discard abs(int32.low)
    when not defined(js):
      doAssertRaises(OverflowDefect): discard abs(int64.low)

static: main()
main()
