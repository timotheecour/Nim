discard """
  cmd: "nim c --experimental:allowFFI $file"
  output: '''
foo
1.349858807576003
'''
"""

#[

$nim_dev_temp_X.3 c --experimental:allowFFI --errormax:1 --debugger:native tests/vm/tevalffi2.nim

/Users/timothee/git_clone/nim/Nim/compiler/nim.nim(109) nim
/Users/timothee/git_clone/nim/Nim/compiler/nim.nim(73) handleCmdLine
/Users/timothee/git_clone/nim/Nim/compiler/cmdlinehelper.nim(92) loadConfigsAndRunMainCommand
/Users/timothee/git_clone/nim/Nim/compiler/main.nim(172) mainCommand
/Users/timothee/git_clone/nim/Nim/compiler/main.nim(78) commandCompileToC
/Users/timothee/git_clone/nim/Nim/compiler/modules.nim(134) compileProject
/Users/timothee/git_clone/nim/Nim/compiler/modules.nim(79) compileModule
/Users/timothee/git_clone/nim/Nim/compiler/passes.nim(200) processModule
/Users/timothee/git_clone/nim/Nim/compiler/passes.nim(86) processTopLevelStmt
/Users/timothee/git_clone/nim/Nim/compiler/sem.nim(604) myProcess
/Users/timothee/git_clone/nim/Nim/compiler/sem.nim(572) semStmtAndGenerateGenerics
/Users/timothee/git_clone/nim/Nim/compiler/semstmts.nim(2052) semStmt
/Users/timothee/git_clone/nim/Nim/compiler/semexprs.nim(919) semExprNoType
/Users/timothee/git_clone/nim/Nim/compiler/semexprs.nim(2591) semExpr
/Users/timothee/git_clone/nim/Nim/compiler/semstmts.nim(1828) semProc
/Users/timothee/git_clone/nim/Nim/compiler/semstmts.nim(1756) semProcAux
/Users/timothee/git_clone/nim/Nim/compiler/semexprs.nim(1617) semProcBody
/Users/timothee/git_clone/nim/Nim/compiler/semexprs.nim(2573) semExpr
/Users/timothee/git_clone/nim/Nim/compiler/semstmts.nim(1992) semStmtList
/Users/timothee/git_clone/nim/Nim/compiler/semexprs.nim(2625) semExpr
/Users/timothee/git_clone/nim/Nim/compiler/semstmts.nim(1944) semStaticStmt
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1913) evalStaticStmt
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1903) evalConstExprAux
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1033) rawExecute
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(226) putIntoReg
/Users/timothee/git_clone/nim/Nim/lib/system/assign.nim(250) FieldDiscriminantCheck
/Users/timothee/git_clone/nim/Nim/lib/system.nim(2976) sysFatal
Error: unhandled exception: assignment to discriminant changes object branch [FieldError]
]#

proc c_printf2(frmt: cstring, a0: pointer): void {.importc: "printf", header: "<stdio.h>", varargs.}

proc C_alloca(n: uint): pointer {.importc:"C_alloca", dynlib: "/tmp/d02/liballoca2.dylib".}

proc fun() =
  block:
    var a = 123
    c_printf2("foo2:a={%d}\n", a.addr)
  block:
    let n: uint = 50
    var buffer2 = C_alloca(n)

proc main() =
  static:
    fun()
  fun()

main()
