type GoodImportcType {.importc: "signed char", nodecl.} = char
  # "good" in sense the sizeof will match
type BadImportcType {.importc: "unsigned char", nodecl.} = uint64
  # "sizeof" check will fail

## ensures cgen
discard GoodImportcType.default
discard BadImportcType.default
