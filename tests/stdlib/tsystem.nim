discard """
  joinable: false
  targets: "c cpp js"
"""

# xxx consolidate / refactor with tests/system/tsystem_misc.nim, etc

template disableVM(body): untyped =
  when nimvm: discard
  else: body

template main() =
  doAssert abs(0) == 0
  doAssert abs(int.high) == int.high
  doAssert abs(-3) == 3
  disableVM: # xxx bug: in vm, we get an un-recoverable program abort.
    when not defined(js): # xxx bug: these should raise in js
      doAssertRaises(OverflowDefect): discard abs(int8.low)
      doAssertRaises(OverflowDefect): discard abs(int32.low)
      doAssertRaises(OverflowDefect): discard abs(int64.low)

static: main()
main()
