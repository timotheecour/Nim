import std/macros

macro overloadExistsImpl(x: typed): bool =
  newLit(x != nil)

template overloadExists*(a: untyped): bool =
  overloadExistsImpl(resolveSymbol(a))

type InstantiationInfo = type(instantiationInfo())

proc toStr(info: InstantiationInfo | LineInfo): string =
  const offset = 1
  result = info.filename & ":" & $info.line & ":" & $(info.column + offset)

proc inspectImpl*(s: var string, a: NimNode, resolveLet: bool) =
  var a = a
  if resolveLet:
    a = a.getImpl
    a = a[2]
  case a.kind
  of nnkClosedSymChoice:
    s.add "closedSymChoice:"
    for ai in a:
      s.add "\n  "
      inspectImpl(s, ai, false)
  of nnkSym:
    var a2 = a.getImpl
    const callables = {nnkProcDef, nnkMethodDef, nnkConverterDef, nnkMacroDef, nnkTemplateDef, nnkIteratorDef}
    if a2.kind in callables:
      let a20=a2
      a2 = newTree(a20.kind)
      for i, ai in a20:
        a2.add if i notin [6]: ai else: newEmptyNode()
    s.add a2.lineInfoObj.toStr & " " & a2.repr
  else: error($a.kind, a) # Error: nnkNilLit when couldn't resolve

macro inspect*(a: typed, resolveLet: static bool = false): untyped =
  var a = a
  if a.kind == nnkTupleConstr:
    a = a[0]
  var s: string
  s.add a.lineInfoObj.toStr & ": "
  s.add a.repr & " = "
  inspectImpl(s, a, resolveLet)
  when defined(nimTestsResolvesDebug):
    echo s

template inspect2*(a: untyped): untyped = inspect(resolveSymbol(a))

macro fieldExistsImpl(a: typed): bool =
  newLit(a.symKind == nskField)

template fieldExists*(a: untyped): untyped = fieldExistsImpl(resolveSymbol(a))

macro canImportImpl(a: typed): bool =
  newLit(a.symKind == nskModule)

# can't work like that...
template canImport*(a: untyped): untyped = canImportImpl(resolveSymbol(a))

macro inspect3*(a: typed): untyped =
  echo (a.repr, a.kind, a.typeKind)
  echo a.symKind
  var a2 = a.getImpl
  echo a2.kind
  # echo a.sym.kind

# macro getSymImpl(a: typed): NimSym =
type SymWrap = object
  s: NimSym
type SymWrap2 = object
  s: int
type SymWrap3[T] = object
  s: NimSym
# macro getSymImpl(a: typed): NimSym =

type SymWrap4*[sym] = object

# type SymWrap4b*[sym] = object
#   sym2: sym

type SymWrap4b* = object
  # sym2: T
  sym2: NimSym

macro getSymImpl(a: typed): untyped =
  # NimSym
  let x = a.symbol
  result = quote do:
    SymWrap4[`x`]

template getSym*(a: untyped): untyped = getSymImpl(resolveSymbol(a))

type SymInt* = distinct int
macro getSymImpl2(a: typed): untyped =
  # NimSym
  let x = cast[int](a.symbol)
  result = quote do:
    # SymWrap4b[`x`](sym2: `x`)
    # SymWrap4b(sym2: `x`)
    `x`.SymInt

template getSym2*(a: untyped): untyped = getSymImpl2(resolveSymbol(a))
