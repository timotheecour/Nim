#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implementation of:
## * `singly linked lists <#SinglyLinkedList>`_
## * `doubly linked lists <#DoublyLinkedList>`_
## * `singly linked rings <#SinglyLinkedRing>`_ (circular lists)
## * `doubly linked rings <#DoublyLinkedRing>`_ (circular lists)
##
## # Basic Usage
## Because it makes no sense to do otherwise, the `next` and `prev` pointers
## are not hidden from you and can be manipulated directly for efficiency.

## ## Lists
runnableExamples:
  var
    l = initDoublyLinkedList[int]()
    a = newDoublyLinkedNode[int](3)
    b = newDoublyLinkedNode[int](7)
    c = newDoublyLinkedNode[int](9)

  l.add(a)
  l.add(b)
  l.prepend(c)

  assert a.next == b
  assert a.prev == c
  assert c.next == a
  assert c.next.next == b
  assert c.prev == nil
  assert b.next == nil

## ## Rings
runnableExamples:
  var
    l = initSinglyLinkedRing[int]()
    a = newSinglyLinkedNode[int](3)
    b = newSinglyLinkedNode[int](7)
    c = newSinglyLinkedNode[int](9)

  l.add(a)
  l.add(b)
  l.prepend(c)

  assert c.next == a
  assert a.next == b
  assert c.next.next == b
  assert b.next == c
  assert c.next.next.next == c

## # See also
## * `deques module <deques.html>`_ for double-ended queues
## * `sharedlist module <sharedlist.html>`_ for shared singly-linked lists

import std/private/since

when not defined(nimHasCursor):
  {.pragma: cursor.}

type
  DoublyLinkedNodeObj*[T] = object ## \
    ## A node a doubly linked list consists of.
    ##
    ## It consists of a `value` field, and pointers to `next` and `prev`.
    next*: <//>(ref DoublyLinkedNodeObj[T])
    prev* {.cursor.}: ref DoublyLinkedNodeObj[T]
    value*: T
  DoublyLinkedNode*[T] = ref DoublyLinkedNodeObj[T]

  SinglyLinkedNodeObj*[T] = object ## \
    ## A node a singly linked list consists of.
    ##
    ## It consists of a `value` field, and a pointer to `next`.
    next*: <//>(ref SinglyLinkedNodeObj[T])
    value*: T
  SinglyLinkedNode*[T] = ref SinglyLinkedNodeObj[T]

  SinglyLinkedNodePtr*[T] = object
    next*: ptr SinglyLinkedNodePtr[T]
    value*: T

  SinglyLinkedList*[T] = object ## \
    ## A singly linked list.
    ##
    ## Use `initSinglyLinkedList proc <#initSinglyLinkedList>`_ to create
    ## a new empty list.
    head*: <//>(SinglyLinkedNode[T])
    tail* {.cursor.}: SinglyLinkedNode[T]

  SinglyLinkedListPtr*[T] = object
    head*: ptr SinglyLinkedNodePtr[T]
    tail*: ptr SinglyLinkedNodePtr[T]

  DoublyLinkedList*[T] = object ## \
    ## A doubly linked list.
    ##
    ## Use `initDoublyLinkedList proc <#initDoublyLinkedList>`_ to create
    ## a new empty list.
    head*: <//>(DoublyLinkedNode[T])
    tail* {.cursor.}: DoublyLinkedNode[T]

  SinglyLinkedRing*[T] = object ## \
    ## A singly linked ring.
    ##
    ## Use `initSinglyLinkedRing proc <#initSinglyLinkedRing>`_ to create
    ## a new empty ring.
    head*: <//>(SinglyLinkedNode[T])
    tail* {.cursor.}: SinglyLinkedNode[T]

  DoublyLinkedRing*[T] = object ## \
    ## A doubly linked ring.
    ##
    ## Use `initDoublyLinkedRing proc <#initDoublyLinkedRing>`_ to create
    ## a new empty ring.
    head*: DoublyLinkedNode[T]

  SomeLinkedList*[T] = SinglyLinkedList[T] | DoublyLinkedList[T] | SinglyLinkedListPtr[T]

  SomeLinkedRing*[T] = SinglyLinkedRing[T] | DoublyLinkedRing[T]

  SomeLinkedCollection*[T] = SomeLinkedList[T] | SomeLinkedRing[T]

  SomeLinkedNode*[T] = SinglyLinkedNode[T] | DoublyLinkedNode[T]

proc initSinglyLinkedList*[T](): SinglyLinkedList[T] =
  ## Creates a new singly linked list that is empty.
  runnableExamples:
    var a = initSinglyLinkedList[int]()
  discard

proc initSinglyLinkedListPtr*[T](): SinglyLinkedListPtr[T] =
  discard

proc initDoublyLinkedList*[T](): DoublyLinkedList[T] =
  ## Creates a new doubly linked list that is empty.
  runnableExamples:
    var a = initDoublyLinkedList[int]()
  discard

proc initSinglyLinkedRing*[T](): SinglyLinkedRing[T] =
  ## Creates a new singly linked ring that is empty.
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
  discard

proc initDoublyLinkedRing*[T](): DoublyLinkedRing[T] =
  ## Creates a new doubly linked ring that is empty.
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
  discard

proc newDoublyLinkedNode*[T](value: T): <//>(DoublyLinkedNode[T]) =
  ## Creates a new doubly linked node with the given `value`.
  runnableExamples:
    var n = newDoublyLinkedNode[int](5)
    assert n.value == 5

  new(result)
  result.value = value

proc newSinglyLinkedNode*[T](value: T): <//>(SinglyLinkedNode[T]) =
  ## Creates a new singly linked node with the given `value`.
  runnableExamples:
    var n = newSinglyLinkedNode[int](5)
    assert n.value == 5

  new(result)
  result.value = value

func toSinglyLinkedList*[T](elems: openArray[T]): SinglyLinkedList[T] {.since: (1, 5, 1).} =
  ## Creates a new `SinglyLinkedList` from members of `elems`.
  runnableExamples:
    import sequtils
    let a = [1, 2, 3, 4, 5].toSinglyLinkedList
    assert a.toSeq == [1, 2, 3, 4, 5]
  result = initSinglyLinkedList[T]()
  for elem in elems.items:
    result.add(elem)

func toDoublyLinkedList*[T](elems: openArray[T]): DoublyLinkedList[T] {.since: (1, 5, 1).} =
  ## Creates a new `DoublyLinkedList` from members of `elems`.
  runnableExamples:
    import sequtils
    let a = [1, 2, 3, 4, 5].toDoublyLinkedList
    assert a.toSeq == [1, 2, 3, 4, 5]
  result = initDoublyLinkedList[T]()
  for elem in elems.items:
    result.add(elem)

template itemsListImpl() {.dirty.} =
  var it = L.head
  while it != nil:
    yield it.value
    it = it.next

template itemsRingImpl() {.dirty.} =
  var it = L.head
  if it != nil:
    while true:
      yield it.value
      it = it.next
      if it == L.head: break

iterator items*[T](L: SomeLinkedList[T]): T =
  ## Yields every value of `L`.
  ##
  ## See also:
  ## * `mitems iterator <#mitems.i,SomeLinkedList[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedList[T]>`_
  runnableExamples:
    from std/sugar import collect
    from std/sequtils import toSeq
    let a = collect(initSinglyLinkedList):
      for i in 1..3: 10*i
    doAssert toSeq(items(a)) == toSeq(a)
    doAssert toSeq(a) == @[10, 20, 30]
  itemsListImpl()

iterator items*[T](L: SomeLinkedRing[T]): T =
  ## Yields every value of `L`.
  ##
  ## See also:
  ## * `mitems iterator <#mitems.i,SomeLinkedRing[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedRing[T]>`_
  runnableExamples:
    from std/sugar import collect
    from std/sequtils import toSeq
    let a = collect(initSinglyLinkedRing):
      for i in 1 .. 3: 10 * i
    doAssert toSeq(items(a)) == toSeq(a)
    doAssert toSeq(a) == @[10, 20, 30]
  itemsRingImpl()

iterator mitems*[T](L: var SomeLinkedList[T]): var T =
  ## Yields every value of `L` so that you can modify it.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedList[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedList[T]>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    for i in 1 .. 5:
      a.add(10 * i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5 * x - 1
    assert $a == "[49, 99, 149, 199, 249]"
  itemsListImpl()

iterator mitems*[T](L: var SomeLinkedRing[T]): var T =
  ## Yields every value of `L` so that you can modify it.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedRing[T]>`_
  ## * `nodes iterator <#nodes.i,SomeLinkedRing[T]>`_
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    for i in 1 .. 5:
      a.add(10 * i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in mitems(a):
      x = 5 * x - 1
    assert $a == "[49, 99, 149, 199, 249]"
  itemsRingImpl()

iterator nodes*[T](L: SomeLinkedList[T]): SomeLinkedNode[T] =
  ## Iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedList[T]>`_
  ## * `mitems iterator <#mitems.i,SomeLinkedList[T]>`_
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    for i in 1 .. 5:
      a.add(10 * i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in nodes(a):
      if x.value == 30:
        a.remove(x)
      else:
        x.value = 5 * x.value - 1
    assert $a == "[49, 99, 199, 249]"

  var it = L.head
  while it != nil:
    var nxt = it.next
    yield it
    it = nxt

iterator nodes*[T](L: SomeLinkedRing[T]): SomeLinkedNode[T] =
  ## Iterates over every node of `x`. Removing the current node from the
  ## list during traversal is supported.
  ##
  ## See also:
  ## * `items iterator <#items.i,SomeLinkedRing[T]>`_
  ## * `mitems iterator <#mitems.i,SomeLinkedRing[T]>`_
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    for i in 1 .. 5:
      a.add(10 * i)
    assert $a == "[10, 20, 30, 40, 50]"
    for x in nodes(a):
      if x.value == 30:
        a.remove(x)
      else:
        x.value = 5 * x.value - 1
    assert $a == "[49, 99, 199, 249]"

  var it = L.head
  if it != nil:
    while true:
      var nxt = it.next
      yield it
      it = nxt
      if it == L.head: break

proc `$`*[T](L: SomeLinkedCollection[T]): string =
  ## Turns a list into its string representation for logging and printing.
  result = "["
  for x in nodes(L):
    if result.len > 1: result.add(", ")
    result.addQuoted(x.value)
  result.add("]")

proc find*[T](L: SomeLinkedCollection[T], value: T): SomeLinkedNode[T] =
  ## Searches in the list for a value. Returns `nil` if the value does not
  ## exist.
  ##
  ## See also:
  ## * `contains proc <#contains,SomeLinkedCollection[T],T>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.add(9)
    a.add(8)
    assert a.find(9).value == 9
    assert a.find(1) == nil

  for x in nodes(L):
    if x.value == value: return x

proc contains*[T](L: SomeLinkedCollection[T], value: T): bool {.inline.} =
  ## Searches in the list for a value. Returns `false` if the value does not
  ## exist, `true` otherwise.
  ##
  ## See also:
  ## * `find proc <#find,SomeLinkedCollection[T],T>`_
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.add(9)
    a.add(8)
    assert a.contains(9)
    assert 8 in a
    assert(not a.contains(1))
    assert 2 notin a

  result = find(L, value) != nil

proc prepend*[T: SomeLinkedList](a: var T, b: T) {.since: (1, 5, 1).} =
  ## Prepends a shallow copy of `b` to the beginning of `a`.
  ##
  ## See also:
  ## * `prependMoved proc <#prependMoved,SinglyLinkedList[T],SinglyLinkedList[T]>`_
  ## * `prependMoved proc <#prependMoved,DoublyLinkedList[T],DoublyLinkedList[T]>`_
  ##   for moving the second list instead of copying
  runnableExamples:
    import sequtils
    var a = [4, 5].toSinglyLinkedList
    let b = [1, 2, 3].toSinglyLinkedList
    a.prepend b
    assert a.toSeq == [1, 2, 3, 4, 5]
    assert b.toSeq == [1, 2, 3]
    a.prepend a
    assert a.toSeq == [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  var tmp = b.copy
  tmp.addMoved a
  a = tmp

proc prependMoved*[T: SomeLinkedList](a, b: var T) {.since: (1, 5, 1).} =
  ## Moves `b` before the head of `a`. Efficiency: O(1).
  ## Note that `b` becomes empty after the operation unless it has the same address as `a`.
  ## Self-prepending results in a cycle.
  ##
  ## See also:
  ## * `prepend proc <#prepend,T,T>`_
  ##   for prepending a copy of a list
  runnableExamples:
    import std/[sequtils, enumerate, sugar]
    var
      a = [4, 5].toSinglyLinkedList
      b = [1, 2, 3].toSinglyLinkedList
      c = [0, 1].toSinglyLinkedList
    a.prependMoved b
    assert a.toSeq == [1, 2, 3, 4, 5]
    assert b.toSeq == []
    c.prependMoved c
    let s = collect:
      for i, ci in enumerate(c):
        if i == 6: break
        ci
    assert s == [0, 1, 0, 1, 0, 1]
  b.addMoved a
  when defined(js): # XXX: swap broken in js; bug #16771
    (b, a) = (a, b)
  else: swap a, b

# proc add*[T](L: var (SinglyLinkedList[T] | SinglyLinkedListPtr[T]), n: type(L.tail)) {.inline.} = # xxx make this work
proc add*[T](L: var (SinglyLinkedList[T] | SinglyLinkedListPtr[T]),
             n: SinglyLinkedNode[T] | ptr SinglyLinkedNodePtr[T]) {.inline.} =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedList[int]()
      n = newSinglyLinkedNode[int](9)
    a.add(n)
    assert a.contains(9)

  n.next = nil
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc add*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.add(9)
    a.add(8)
    assert a.contains(9)
  add(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedList[T],
                 n: SinglyLinkedNode[T]) {.inline.} =
  ## Prepends (adds to the beginning) a node to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedList[int]()
      n = newSinglyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  n.next = L.head
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var SinglyLinkedList[T], value: T) {.inline.} =
  ## Prepends (adds to the beginning) a node to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,SinglyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  runnableExamples:
    var a = initSinglyLinkedList[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newSinglyLinkedNode(value))

func copy*[T](a: SinglyLinkedList[T]): SinglyLinkedList[T] {.since: (1, 5, 1).} =
  ## Creates a shallow copy of `a`.
  runnableExamples:
    import sequtils
    type Foo = ref object
      x: int
    var
      f = Foo(x: 1)
      a = [f].toSinglyLinkedList
    let b = a.copy
    a.add [f].toSinglyLinkedList
    assert a.toSeq == [f, f]
    assert b.toSeq == [f] # b isn't modified...
    f.x = 42
    assert a.head.value.x == 42
    assert b.head.value.x == 42 # ... but the elements are not deep copied

    let c = [1, 2, 3].toSinglyLinkedList
    assert $c == $c.copy
  result = initSinglyLinkedList[T]()
  for x in a.items:
    result.add(x)

proc addMoved*[T](a, b: var SinglyLinkedList[T]) {.since: (1, 5, 1).} =
  ## Moves `b` to the end of `a`. Efficiency: O(1).
  ## Note that `b` becomes empty after the operation unless it has the same address as `a`.
  ## Self-adding results in a cycle.
  ##
  ## See also:
  ## * `add proc <#add,T,T>`_
  ##   for adding a copy of a list
  runnableExamples:
    import std/[sequtils, enumerate, sugar]
    var
      a = [1, 2, 3].toSinglyLinkedList
      b = [4, 5].toSinglyLinkedList
      c = [0, 1].toSinglyLinkedList
    a.addMoved b
    assert a.toSeq == [1, 2, 3, 4, 5]
    assert b.toSeq == []
    c.addMoved c
    let s = collect:
      for i, ci in enumerate(c):
        if i == 6: break
        ci
    assert s == [0, 1, 0, 1, 0, 1]
  if a.tail != nil:
    a.tail.next = b.head
  a.tail = b.tail
  if a.head == nil:
    a.head = b.head
  if a.addr != b.addr:
    b.head = nil
    b.tail = nil

proc add*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedList[int]()
      n = newDoublyLinkedNode[int](9)
    a.add(n)
    assert a.contains(9)

  n.next = nil
  n.prev = L.tail
  if L.tail != nil:
    assert(L.tail.next == nil)
    L.tail.next = n
  L.tail = n
  if L.head == nil: L.head = n

proc add*[T](L: var DoublyLinkedList[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    a.add(9)
    a.add(8)
    assert a.contains(9)
  add(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedList[int]()
      n = newDoublyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  n.prev = nil
  n.next = L.head
  if L.head != nil:
    assert(L.head.prev == nil)
    L.head.prev = n
  L.head = n
  if L.tail == nil: L.tail = n

proc prepend*[T](L: var DoublyLinkedList[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,DoublyLinkedList[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `remove proc <#remove,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedList[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newDoublyLinkedNode(value))

func copy*[T](a: DoublyLinkedList[T]): DoublyLinkedList[T] {.since: (1, 5, 1).} =
  ## Creates a shallow copy of `a`.
  runnableExamples:
    type Foo = ref object
      x: int
    var f = Foo(x: 1)
    let
      a = [f].toDoublyLinkedList
      b = a.copy
    f.x = 42
    assert a.head.value.x == 42
    assert b.head.value.x == 42

    let c = [1, 2, 3].toDoublyLinkedList
    assert $c == $c.copy
  result = initDoublyLinkedList[T]()
  for x in a.items:
    result.add(x)

proc addMoved*[T](a, b: var DoublyLinkedList[T]) {.since: (1, 5, 1).} =
  ## Moves `b` to the end of `a`. Efficiency: O(1).
  ## Note that `b` becomes empty after the operation unless it has the same address as `a`.
  ## Self-adding results in a cycle.
  ##
  ## See also:
  ## * `add proc <#add,T,T>`_
  ##   for adding a copy of a list
  runnableExamples:
    import std/[sequtils, enumerate, sugar]
    var
      a = [1, 2, 3].toDoublyLinkedList
      b = [4, 5].toDoublyLinkedList
      c = [0, 1].toDoublyLinkedList
    a.addMoved b
    assert a.toSeq == [1, 2, 3, 4, 5]
    assert b.toSeq == []
    c.addMoved c
    let s = collect:
      for i, ci in enumerate(c):
        if i == 6: break
        ci
    assert s == [0, 1, 0, 1, 0, 1]
  if b.head != nil:
    b.head.prev = a.tail
  if a.tail != nil:
    a.tail.next = b.head
  a.tail = b.tail
  if a.head == nil:
    a.head = b.head
  if a.addr != b.addr:
    b.head = nil
    b.tail = nil

proc add*[T: SomeLinkedList](a: var T, b: T) {.since: (1, 5, 1).} =
  ## Appends a shallow copy of `b` to the end of `a`.
  ##
  ## See also:
  ## * `addMoved proc <#addMoved,SinglyLinkedList[T],SinglyLinkedList[T]>`_
  ## * `addMoved proc <#addMoved,DoublyLinkedList[T],DoublyLinkedList[T]>`_
  ##   for moving the second list instead of copying
  runnableExamples:
    import sequtils
    var a = [1, 2, 3].toSinglyLinkedList
    let b = [4, 5].toSinglyLinkedList
    a.add b
    assert a.toSeq == [1, 2, 3, 4, 5]
    assert b.toSeq == [4, 5]
    a.add a
    assert a.toSeq == [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
  var tmp = b.copy
  a.addMoved tmp

proc remove*[T](L: var SinglyLinkedList[T], n: SinglyLinkedNode[T]): bool {.discardable.} =
  ## Removes a node `n` from `L`.
  ## Returns `true` if `n` was found in `L`.
  ## Efficiency: O(n); the list is traversed until `n` is found.
  ## Attempting to remove an element not contained in the list is a no-op.
  ## When the list is cyclic, the cycle is preserved after removal.
  runnableExamples:
    import std/[sequtils, enumerate, sugar]
    var a = [0, 1, 2].toSinglyLinkedList
    let n = a.head.next
    doAssert n.value == 1
    doAssert a.remove(n) == true
    doAssert a.toSeq == [0, 2]
    doAssert a.remove(n) == false
    doAssert a.toSeq == [0, 2]
    a.addMoved a # cycle: [0, 2, 0, 2, ...]
    a.remove a.head
    let s = collect:
      for i, ai in enumerate(a):
        if i == 4: break
        ai
    doAssert s == [2, 2, 2, 2]

  if n == L.head:
    L.head = n.next
    if L.tail.next == n:
      L.tail.next = L.head # restore cycle
  else:
    var prev = L.head
    while prev.next != n and prev.next != nil:
      prev = prev.next
    if prev.next == nil:
      return false
    prev.next = n.next
  true

proc remove*[T](L: var DoublyLinkedList[T], n: DoublyLinkedNode[T]) =
  ## Removes a node `n` from `L`. Efficiency: O(1).
  ## This function assumes, for the sake of efficiency, that `n` is contained in `L`,
  ## otherwise the effects are undefined.
  ## When the list is cyclic, the cycle is preserved after removal.
  runnableExamples:
    import std/[sequtils, enumerate, sugar]
    var a = [0, 1, 2].toSinglyLinkedList
    let n = a.head.next
    doAssert n.value == 1
    a.remove n
    doAssert a.toSeq == [0, 2]
    a.remove n
    doAssert a.toSeq == [0, 2]
    a.addMoved a # cycle: [0, 2, 0, 2, ...]
    a.remove a.head
    let s = collect:
      for i, ai in enumerate(a):
        if i == 4: break
        ai
    doAssert s == [2, 2, 2, 2]

  if n == L.tail: L.tail = n.prev
  if n == L.head: L.head = n.next
  if n.next != nil: n.next.prev = n.prev
  if n.prev != nil: n.prev.next = n.next



proc add*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedRing[int]()
      n = newSinglyLinkedNode[int](9)
    a.add(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
    L.tail = n
  else:
    n.next = n
    L.head = n
    L.tail = n

proc add*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    a.add(9)
    a.add(8)
    assert a.contains(9)
  add(L, newSinglyLinkedNode(value))

proc prepend*[T](L: var SinglyLinkedRing[T], n: SinglyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],T>`_ for prepending a value
  runnableExamples:
    var
      a = initSinglyLinkedRing[int]()
      n = newSinglyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    assert(L.tail != nil)
    L.tail.next = n
  else:
    n.next = n
    L.tail = n
  L.head = n

proc prepend*[T](L: var SinglyLinkedRing[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,SinglyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,SinglyLinkedRing[T],SinglyLinkedNode[T]>`_
  ##   for prepending a node
  runnableExamples:
    var a = initSinglyLinkedRing[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newSinglyLinkedNode(value))



proc add*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Appends (adds to the end) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](9)
    a.add(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    n.prev = L.head.prev
    L.head.prev.next = n
    L.head.prev = n
  else:
    n.prev = n
    n.next = n
    L.head = n

proc add*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Appends (adds to the end) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    a.add(9)
    a.add(8)
    assert a.contains(9)
  add(L, newDoublyLinkedNode(value))

proc prepend*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Prepends (adds to the beginning) a node `n` to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],T>`_ for prepending a value
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](9)
    a.prepend(n)
    assert a.contains(9)

  if L.head != nil:
    n.next = L.head
    n.prev = L.head.prev
    L.head.prev.next = n
    L.head.prev = n
  else:
    n.prev = n
    n.next = n
  L.head = n

proc prepend*[T](L: var DoublyLinkedRing[T], value: T) =
  ## Prepends (adds to the beginning) a value to `L`. Efficiency: O(1).
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for appending a node
  ## * `add proc <#add,DoublyLinkedRing[T],T>`_ for appending a value
  ## * `prepend proc <#prepend,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for prepending a node
  ## * `remove proc <#remove,DoublyLinkedRing[T],DoublyLinkedNode[T]>`_
  ##   for removing a node
  runnableExamples:
    var a = initDoublyLinkedRing[int]()
    a.prepend(9)
    a.prepend(8)
    assert a.contains(9)
  prepend(L, newDoublyLinkedNode(value))

proc remove*[T](L: var DoublyLinkedRing[T], n: DoublyLinkedNode[T]) =
  ## Removes `n` from `L`. Efficiency: O(1).
  runnableExamples:
    var
      a = initDoublyLinkedRing[int]()
      n = newDoublyLinkedNode[int](5)
    a.add(n)
    assert 5 in a
    a.remove(n)
    assert 5 notin a

  n.next.prev = n.prev
  n.prev.next = n.next
  if n == L.head:
    var p = L.head.prev
    if p == L.head:
      # only one element left:
      L.head = nil
    else:
      L.head = L.head.prev

proc append*[T](a: var (SinglyLinkedList[T] | SinglyLinkedRing[T]),
                b: SinglyLinkedList[T] | SinglyLinkedNode[T] | T) =
  ## Alias for `a.add(b)`.
  ##
  ## See also:
  ## * `add proc <#add,SinglyLinkedList[T],SinglyLinkedNode[T]>`_
  ## * `add proc <#add,SinglyLinkedList[T],T>`_
  ## * `add proc <#add,T,T>`_
  a.add b

proc append*[T](a: var (DoublyLinkedList[T] | DoublyLinkedRing[T]),
                b: DoublyLinkedList[T] | DoublyLinkedNode[T] | T) =
  ## Alias for `a.add(b)`.
  ##
  ## See also:
  ## * `add proc <#add,DoublyLinkedList[T],DoublyLinkedNode[T]>`_
  ## * `add proc <#add,DoublyLinkedList[T],T>`_
  ## * `add proc <#add,T,T>`_
  a.add b

proc appendMoved*[T: SomeLinkedList](a, b: var T) {.since: (1, 5, 1).} =
  ## Alias for `a.addMoved(b)`.
  ##
  ## See also:
  ## * `addMoved proc <#addMoved,SinglyLinkedList[T],SinglyLinkedList[T]>`_
  ## * `addMoved proc <#addMoved,DoublyLinkedList[T],DoublyLinkedList[T]>`_
  a.addMoved b
