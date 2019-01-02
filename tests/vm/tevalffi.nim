discard """
  cmd: "nim c --experimental:allowFFI --rangeChecks:on $file"
  output: '''
foo
1.349858807576003
'''
"""

# todo: this has no effect (unlike `--experimental:allowFFI`)
# {.push experimental: "allowFFI".}

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>",
  varargs, discardable.}
proc c_exp(a: float64): float64 {.importc: "exp", header: "<math.h>".}

proc fun() =
  {.push experimental: "allowFFI".}
  c_printf("foo\n")
  var x = 0.3
  let b = c_exp(x)
  echo b

proc main() =
  static: fun()

main()
