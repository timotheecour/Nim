type CompilerCallback* = enum
  # RENAME those
  kIsMainModuleCallback,
  kOnDefinition,
  kOnUsageHook,
  kDiagnostic,
  kDiagnostic2,

when defined(nimRegisterCompilerCallback):
  proc registerCompilerCallback*(kind: CompilerCallback, fun: proc) {.magic: "RegisterCompilerCallback".}
  proc registerCompilerCallback*(kind: CompilerCallback) {.magic: "RegisterCompilerCallback".}

when defined(nimHasRegisterModule):
  proc registerModuleImpl(path: string): string {.magic: "RegisterModule", compileTime.}
  template registerModule*(path: string) =
    const ignore = registerModuleImpl(path)

when defined(nimHasRegisterModule) and appType != "lib": # fixes D20190611T002352
  registerModule "./semcompilerhook"
