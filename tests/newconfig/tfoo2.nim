doAssert defined(nimHasNimscriptModule)
doAssert defined(tfoo2NimsWitness1)
doAssert defined(tfoo2NimsWitness2)
doAssert defined(tfoo2NimsWitness3)
doAssert not defined(tfoo2NimsWitness4)

block: # cppDefine
  proc fun(tfoo2NimsCpp1: int) =
    doAssert tfoo2NimsCpp1 == 1
  fun(tfoo2NimsCpp1 = 1)
