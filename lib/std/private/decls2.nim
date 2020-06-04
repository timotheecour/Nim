##[
unstable API, internal use only for now.
candidate for merging in std/decls
]##

proc byLent*[T](a: var T): lent T =
  ## caveat: see https://github.com/nim-lang/Nim/issues/14557
  ## use case: convert a var to a lent to help with overload resolution, see
  ## https://github.com/timotheecour/Nim/issues/287
  a
