##[
This module contains routines for lazy or online algorithms; unlike sequtils
it uses iterators, avoiding un-necessary allocations.
]##

import std/sets

iterator iota*(n: int): int =
  ## Yields 0..<n
  runnableExamples:
    assert toSeq(3.iota) == @[0, 1, 2]
    assert toSeq(0.iota) == @[]
  for i in 0..<n: yield i

template isUnique*[T](a: iterable[T]): bool =
  ## Returns whether `a` contains only unique elements.
  runnableExamples:
    assert isUnique(iota(10))
    assert not isUnique(@[10, 11, 10])
  var s: HashSet[T]
  var ret = true
  for ai in a:
    if containsOrIncl(s, ai):
      ret = false
      break
  ret

proc isUnique*[T](a: openArray[T]): bool =
  ## Overload
  isUnique(items(a))

template toSeq*[T](a: iterable[T]): seq[T] =
  var ret: seq[T]
  for ai in a:
    add(ret, ai)
  ret

template toSeq*[T](a: iterable[T], capacity: int): seq[T] =
  ## Overload that accepts an initial capacity, allowing more efficient code
  ## when a guess about number of items in `a` is known.
  runnableExamples:
    assert toSeq(3.iota, 10) == @[0, 1, 2] # overprovision
    assert toSeq(3.iota, 1) == @[0, 1, 2] # underprovision
  var ret = newSeq[T](capacity)
  var i = 0
  for ai in a:
    if i < capacity:
      ret[i] = ai
    else:
      add(ret, ai)
    inc i
  ret.setLen i
  ret

template firstN*[T](a: iterable[T], n: int): seq[T] =
  ## Aka `take` in other languages.
  runnableExamples:
    assert firstN(4.iota, 2) == @[0, 1]
    doAssertRaises(IndexDefect): discard firstN(4.iota, 5)
  var ret = newSeq[T](n)
  var i = 0
  for ai in a:
    if i < n:
      ret[i] = ai
      inc i
    else:
      break
  if i != n:
    raise newException(IndexDefect, "`a` has less than " & $i & " elements")
  ret


import std/macros
macro filterIt*(x: ForLoopStmt): untyped =
  runnableExamples:
    # echo toSeq(filterIt(10.iota, it mod 2 == 0))
    for ai in filterIt(10.iota, it mod 2 == 0):
      echo ai
  # xxx instead, can we allow `iterable` as template return type? it would compose better
  let body = x[^1]
  let ai2 = x[^3]
  let elems = x[^2]
  let a = elems[1]
  let pred = elems[2]
  result = quote do:
    for it {.inject.} in `a`:
      template body2(`ai2`) = `body`
      if `pred`:
        body2(it)

#[

# template firstN*[T](a: iterable[T], n: int): seq[T] =
# template filter*[T](a: iterable[T], pred: untyped): untyped =
# iterator filterIt*[T](a: iterable[T], pred: untyped): auto =
template filterIt*[T](a: iterable[T], pred: untyped): untyped =
  runnableExamples:
    # echo filterIt(10.iota, it mod 2 == 0)
    for ai in filterIt(10.iota, it mod 2 == 0):
      echo ai
  # for it {.inject.} in a:
  #   if pred:
  #     yield it
  iterator impl(): auto {.closure.} =
    for it {.inject.} in a:
      if pred:
        yield it
  # impl()
  # impl()
  impl

]#

