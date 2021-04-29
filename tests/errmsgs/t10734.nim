discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t10734.nim(19, 1) Error: invalid indentation
t10734.nim(19, 6) Error: invalid indentation
t10734.nim(20, 7) Error: expression expected, but found '[EOF]'
t10734.nim(18, 5) Error: 'proc' is not a concrete type; for a callback without parameters use 'proc()'
t10734.nim(19, 6) Error: undeclared identifier: 'p'
t10734.nim(19, 6) Error: expression 'error p' has no type (or is ambiguous)
t10734.nim(19, 6) Error: 'error p' cannot be assigned to
'''
"""


type
  T = object
    a:
proc p =
  case