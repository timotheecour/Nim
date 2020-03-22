# adapted from http://ix.io/2eL3

import macros

macro tryCompile*(expr, elseBody: untyped): untyped =
  var name: NimNode

  if expr.kind in nnkCallKinds:
    if expr[0].kind == nnkDotExpr:
      name = expr[0][1]
    else:
      name = expr[0]
  else:
    if expr.kind == nnkDotExpr:
      name = expr[1]
    else:
      name = expr

  expectKind(expr[0], nnkIdent)
  let templateDef = nnkTemplateDef.newTree(
    name,
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      newIdentNode("untyped"),
      nnkIdentDefs.newTree(
        newIdentNode("arg"),
        newIdentNode("untyped"),
        newEmptyNode()
      )
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkStmtList.newTree(
      elseBody
    )
  )

  result = quote do:
    `templateDef`
    `expr`

when isMainModule:
  type
    MyObject = object

  var myInt: int = 123
  var mySeq = @['a','b','c']
  var myString = "abcdef"
  var myObject: MyObject

  doAssert tryCompile(myInt.len, 10) == 10
  doAssert tryCompile(mySeq.len, 11) == 3
  doAssert tryCompile(myString.len, 12) == 6
  doAssert tryCompile(myObject.len, 13) == 13
