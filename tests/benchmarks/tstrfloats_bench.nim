#[
on OSX:
nim r -d:danger -d:numIter:100_000_00 tests/benchmarks/tstrfloats_bench.nim

toStringSprintf    genFloatCast   11.648684
toStringSprintf    genFloatConv   1.5726399999999998
toStringSprintf    genFloat32Cast 4.996139999999999
toStringSprintf    genFloat32Conv 1.6002259999999993
toStringDragonbox  genFloatCast   0.18426399999999887
toStringDragonbox  genFloatConv   0.1614930000000001
toStringDragonbox  genFloat32Cast 0.1921079999999975
toStringDragonbox  genFloat32Conv 0.12435800000000086
toStringSchubfach  genFloatCast   0.254999999999999
toStringSchubfach  genFloatConv   0.07917600000000036
toStringSchubfach  genFloat32Cast 0.20187899999999814
toStringSchubfach  genFloat32Conv 0.13615599999999972
toStringDragonbox0 genFloatCast   0.2024349999999977
toStringDragonbox0 genFloatConv   0.21805200000000013
toStringDragonbox0 genFloat32Cast 0.1467919999999978
toStringDragonbox0 genFloat32Conv 0.14451999999999998
]#

import std/[times, strfloats, strutils, math, random]
import std/private/asciitables
const numIter {.intdefine.} = 10

var msg = ""

template gen(algo, genFloat) =
  proc main {.gensym.} =
    var buf: array[strFloatBufLen, char]
    var c = 0
    let t = cpuTime()
    for i in 0..<numIter:
      let x = genFloat(i)
      let m = algo(buf, x)
      when true: # debugging
        if i < 10:
          var s = ""
          s.addCharsN(buf[0].addr, m)
          echo s
      c += m
    let t2 = cpuTime() - t
    doAssert c != 0
    let msgi = "$#\t$#\t$#\n" % [astToStr(genFloat), astToStr(algo), $t2]
    echo msgi
    msg.add msgi
  main()

template genFloatCast(i): untyped = cast[float](i)
template genFloatConv(i): untyped = float(i)
template genFloatRand(i): untyped = rand(100.0)
template genFloatRandRound3(i): untyped = round(rand(100.0), 3)

template genFloat32RandRound3(i): untyped = round(rand(100.0).float32, 3)
template genFloat32Cast(i): untyped = cast[float32](i)
template genFloat32Conv(i): untyped = float32(i)

template gen(genFloat) =
  echo astToStr(genFloat)
  # gen(toStringSprintf, genFloat)
  gen(toStringDragonbox, genFloat)
  gen(toStringSchubfach, genFloat)
  gen(toStringDragonbox0, genFloat)

template main =
  gen(genFloatCast)
  gen(genFloatConv)
  gen(genFloatRand)
  gen(genFloatRandRound3)
  gen(genFloat32Cast)
  gen(genFloat32Conv)
  gen(genFloat32RandRound3)
  echo alignTable(msg)

when isMainModule:
  main()
