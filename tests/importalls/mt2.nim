from ./m1 {.all.} as m import foo1, Foo5 {.fields.}
from ./m1 {.all.} as m2 import foo7
# from ./m1 {.all.} as m2 import foo1 # PRTEMP: Error: redefinition of 'm2'; pr

doAssert foo1 == 2
doAssert m.foo1 == 2
doAssert m.foo2 == 2
doAssert compiles(foo1)
doAssert compiles(m.foo2)
doAssert not compiles(foo2)
doAssert not compiles(m3h2)
doAssert m.foo3 == 2
doAssert m.foo6() == 2
doAssert m.foo6b() == 2
doAssert foo7() == 2
doAssert m2.foo6b() == 2
doAssert not compiles(foo10())
doAssert compiles(m.Foo5)
doAssert not compiles(m.Foo11)
doAssert not compiles(m.kg1b)
doAssert not compiles(m.foo12())

## field access
var x = m.Foo5(z1: "foo", z2: m.kg1)
doAssert x.z1 == "foo"

var f0: m.Foo5
f0.z3 = 3
doAssert f0.z3 == 3
var f = m.initFoo5(z3=3)
doAssert f.z3 == 3
doAssert m.z3(f) == 30
