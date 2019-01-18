{.nosystem.}

type
  int* {.magic: Int.} ## default integer type; bitwidth depends on
                      ## architecture, but is always the same as a pointer
  int8* {.magic: Int8.} ## signed 8 bit integer type
  int16* {.magic: Int16.} ## signed 16 bit integer type
  int32* {.magic: Int32.} ## signed 32 bit integer type
  int64* {.magic: Int64.} ## signed 64 bit integer type
  uint* {.magic: UInt.} ## unsigned default integer type
  uint8* {.magic: UInt8.} ## unsigned 8 bit integer type
  uint16* {.magic: UInt16.} ## unsigned 16 bit integer type
  uint32* {.magic: UInt32.} ## unsigned 32 bit integer type
  uint64* {.magic: UInt64.} ## unsigned 64 bit integer type
  float* {.magic: Float.} ## default floating point type
  float32* {.magic: Float32.} ## 32 bit floating point type
  float64* {.magic: Float.} ## 64 bit floating point type

# 'float64' is now an alias to 'float'; this solves many problems
