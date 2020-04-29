when false:
  ## a user can put this in his $XDG_CONFIG_HOME/nim/config.nims
  when defined(nimHasNimscriptModule) and defined(nimNimsNoimport):
    import system/nimscript

doAssert defined(tfoo2CfgWitness)
doAssert defined(nimHasNimscriptModule)
doAssert defined(nimNimsNoimport) # from tfoo2.nim.cfg
doAssert not declared(ScriptMode)
import system/nimscript
doAssert declared(ScriptMode)

doAssert defined(nimHasNimscriptModule)
{.define(tfoo2NimsWitness1).}
--define:tfoo2NimsWitness2
switch("define", "tfoo2NimsWitness3")
{.define(tfoo2NimsWitness4).}
{.undef(tfoo2NimsWitness4).}

# test for cppDefine used in $nim/config/config.nims
doAssert defined(nimHasCppDefine)
--passc: "-Dtfoo2NimsCpp1" # this would cause a codegen error
cppDefine "tfoo2NimsCpp1" # this prevents codegen error

