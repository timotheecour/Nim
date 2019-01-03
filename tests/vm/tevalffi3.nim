discard """
  cmd: "nim c --experimental:allowFFI $file"
  output: '''
foo
1.349858807576003
'''
"""


#[
PC:125 opcode:opcLdImmInt ra:0,rkNone rb:0,rkNone rc:128,
PC:126 opcode:opcFJmp ra:0,rkInt rb:5,rkNone rc:128,
PC:131 opcode:opcFJmp ra:0,rkInt rb:2,rkNone rc:128,
PC:133 opcode:opcFJmp ra:0,rkInt rb:2,rkNone rc:128,
PC:135 opcode:opcFJmp ra:0,rkInt rb:5,rkNone rc:128,
PC:140 opcode:opcFJmp ra:0,rkInt rb:2,rkNone rc:128,
PC:142 opcode:opcEof ra:0,rkInt rb:0,rkInt rc:0,rkInt
142     LdConst r0, fun_bug (14)        #tevalffi3:22
143     IndCall r0, r0, nargs:1 #tevalffi3:22
144     Eof     r0, r0, r0      #tevalffi3:22

PC:142 opcode:opcLdConst ra:0,rkNone rb:14, rc:128,
PC:143 opcode:opcIndCall ra:0,rkNode rb:0,rkNode rc:1,
145     LdImmInt        r1, 123 #tevalffi3:13
146     LdNull  r2, 3   #tevalffi3:14
147     AddrReg r3, r1, r0      #tevalffi3:14
148     AsgnRef r2, r3, r1      #tevalffi3:14
149     LdImmInt        r4, 50  #tevalffi3:16
150     LdNull  r5, 4   #tevalffi3:18
151     LdConst r6, c_malloc (15)       #tevalffi3:18
152     AsgnInt r7, r4, r0      #tevalffi3:18
153     IndCallAsgn     r3, r6, nargs:2 #tevalffi3:18
154     AsgnComplex     r5, r3, r1      #tevalffi3:18
155     Ret     r0, r0, r0      #tevalffi3:12
156     Eof     r0, r0, r0      #tevalffi3:12

PC:145 opcode:opcLdImmInt ra:1,rkNone rb:123, rc:128,
PC:146 opcode:opcLdNull ra:2,rkNone rb:3,rkNone rc:128,
PC:147 opcode:opcAddrReg ra:3,rkNone rb:1,rkInt rc:0,rkNone
PC:148 opcode:opcAsgnRef ra:2,rkNode rb:3,rkRegisterAddr rc:1,rkInt
PC:149 opcode:opcLdImmInt ra:4,rkNone rb:50, rc:128,
PC:150 opcode:opcLdNull ra:5,rkNone rb:4,rkInt rc:128,
PC:151 opcode:opcLdConst ra:6,rkNone rb:15, rc:128,
PC:152 opcode:opcAsgnInt ra:7,rkNone rb:4,rkInt rc:0,rkNone
PC:153 opcode:opcIndCallAsgn ra:3,rkRegisterAddr rb:6,rkNode rc:2,rkRegisterAddr
$nimc_D/compiler/vm.nim:219:10 n.kind:TNodeKind=nkIntLit; dest.kind:TRegisterKind=rkRegisterAddr;
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
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1925) evalStaticStmt
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1915) evalConstExprAux
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(1040) rawExecute
/Users/timothee/git_clone/nim/Nim/compiler/vm.nim(226) putIntoReg
/Users/timothee/git_clone/nim/Nim/lib/system/assign.nim(250) FieldDiscriminantCheck
/Users/timothee/git_clone/nim/Nim/lib/system.nim(2980) sysFatal
Error: unhandled exception: assignment to discriminant changes object branch [FieldError]

]#

proc c_malloc(size:uint):pointer {.importc:"malloc", header: "<stdlib.h>".}

proc fun_bug() =
  block:
    var a = 123
    var a2 = a.addr
  block:
    let n: uint = 50
    # var buffer2: pointer = c_malloc(n)
    var buffer2 = c_malloc(n)

proc main() =
  static:
    fun_bug()
main()
