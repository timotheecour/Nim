#[
D20190829T103518
]#

import compiler/ast
import compiler/semdata

proc semRegisterCompilerCallback*(c: PContext; n: PNode; flags: TExprFlags): PNode {.exportc.}

import compiler/compilerext

import compiler/magicsys
import compiler/sem
import compiler/msgs
import compiler/modulegraphs
import compiler/lineinfos
import compiler/vmdef
import compiler/vmgen

import timn/nimimport/extend

type Data = ref object
  numDef: int
  numDef2: int
  numUsage: int
  numUsage2: int

var data0: Data

proc toHookArg(c: PContext, s: PSym, info: TLineInfo): PNode =
  result = newSymNode(s)
  result.typ = sysTypeFromName(c.graph, info, "NimNode")
  result.flags.incl nfPreserve

proc garbageCollectVM(c: PContext, n: PNode) =
  #[
  note:
  not sure we could eval in a new context to avoid D20190829T151843, other stuff needs
  to be in scope, etc
  ]#
  let vm = PCtx(c.graph.vm)
  doAssert vm.constantCounts.len == vm.constants.len
  for i in 0 ..< vm.constants.len:
    # BUGFIX: starting from previous len instead of 0 was wrong; maybe bc code can execute other stuff inside or reentrant?
    if sameConstant(vm.constants[i], n):
      doAssert vm.constantCounts[i] > 0
      vm.constantCounts[i].dec
      if vm.constantCounts[i] == 0:
        vm.constants[i] = nil
    # echo0If i, vm.constants[i], n, vm.constantCounts[i]

proc semRegisterCompilerCallback*(c: PContext; n: PNode; flags: TExprFlags): PNode =
  if data0 == nil: data0 = Data()
  #[
  SEE also:
  let num = registerCallback(vm, name ; callback: VmCallback)
  ]#
  let nKind = semStaticExpr(c, n[1])
  if nKind.kind != nkIntLit:
    localError(c.config, n.info, $(nKind.kind))
    return nil
  let kindVM = CompilerCallback(nKind.intVal)
  case kindVM
  of kIsMainModuleCallback:
    c.graph.registerMainModuleHook = proc(file: string): bool =
      let nCall = newNodeI(nkCall, n.info)
      nCall.addSon(n[2])
      let arg = newStrNode(file, n.info)
      nCall.addSon(arg)
      let ret = semStaticExpr(c, nCall)
      case ret.intVal # IMPROVE
      of 0: return false
      of 1: return true
      else: doAssert false, $(ret.intVal, n.info)

  of kDiagnostic:
    let vm = PCtx(c.graph.vm)
    let msg = $(data0[])
    echo0If vm.constants.len, msg

  of kDiagnostic2:
    # TODO: just in a range?
    let vm = PCtx(c.graph.vm)
    for i in 0 ..< vm.constants.len:
      echo0If i, vm.constants[i], vm.constantCounts[i]

  of kOnUsageHook:
    # TODO: FACTOR onDefinitionHook
    c.graph.onUsageHook = proc(graph: ModuleGraph; s: PSym; info: TLineInfo) =
      data0.numUsage.inc
      # echo0If s
      var count {.threadVar.}: int
      if count > 0:
        # echo0If "reentrant, skipping" # TODO: could add to a queue
        return
      data0.numUsage2.inc
      count.inc
      defer:
        count.dec

      let nCall = newNodeI(nkCall, n.info)
      nCall.addSon n[2]
      nCall.addSon toHookArg(c, s, n.info)
      # CHECKME: somehow `newIntNode(nkIntLit, someint)` doesn't increase the number of constants, unlike newStrNode
      let argInfo=newStrNode(graph.config$info, info)
      nCall.addSon argInfo

      let ret = semExpr(c, nCall) # note: semStaticExpr doesn't seem needed (will still run in vm though)
      garbageCollectVM(c, argInfo)

  of kOnDefinition:
    c.graph.onDefinitionHook = proc(graph: ModuleGraph; s: PSym; info: TLineInfo) =
      data0.numDef.inc
      let filter = {skProc} # TODO: hook-customize
      if s.kind notin filter:
        return
      data0.numDef2.inc

      let nCall = newNodeI(nkCall, n.info)
      nCall.addSon n[2]
      nCall.addSon toHookArg(c, s, n.info)
      let ret = semExpr(c, nCall) # or semStaticExpr?
      # TOOD: auto convert ret

  result = c.graph.emptyNode
