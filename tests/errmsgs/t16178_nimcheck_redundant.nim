discard """
cmd: '''nim check --hints:off $file'''
action: reject
nimoutFull: true
nimout: '''
t16178_nimcheck_redundant.nim(32, 11) Error: undeclared identifier: 'bad5'
t16178_nimcheck_redundant.nim(36, 11) Error: expression 'error' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(40, 11) Error: expression 'error' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(44, 15) Error: expression 'error' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(49, 12) Error: undeclared field: 'f1' for type t16178_nimcheck_redundant.A [type declared in t16178_nimcheck_redundant.nim(47, 8)]
t16178_nimcheck_redundant.nim(49, 12) Error: expression 'error' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(50, 12) Error: undeclared field: 'f2' for type t16178_nimcheck_redundant.A [type declared in t16178_nimcheck_redundant.nim(47, 8)]
t16178_nimcheck_redundant.nim(50, 12) Error: expression 'error' has no type (or is ambiguous)
t16178_nimcheck_redundant.nim(51, 8) Error: attempting to call undeclared routine: 'f3='
t16178_nimcheck_redundant.nim(52, 8) Error: attempting to call undeclared routine: 'f4='
'''
"""












# line 30
block:
  let a = bad5(1)

block: # bug #12741
  macro foo = discard
  let x = foo

block:
  macro foo2 = discard
  discard foo2

block:
  macro foo3() = discard
  discard foo3()

block:
  type A = object
  var a = A()
  discard a.f1
  discard a.f2
  a.f3 = 0
  a.f4 = 0
