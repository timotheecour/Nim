#[
on OSX:
nim r -d:danger -d:numIter:100_000_00 tests/benchmarks/tstrfloats_bench.nim
("toStringSprintf", "genFloatCast", 11.956240000000001)
("toStringSprintf", "genFloatConf", 1.581176000000001)
("toStringDragonbox", "genFloatCast", 0.1652149999999999)
("toStringDragonbox", "genFloatConf", 0.15221700000000027)
]#

import std/[times, strfloats]

const numIter {.intdefine.} = 10

template gen(algo, genFloat) =
  proc main {.gensym.} =
    var buf: array[strFloatBufLen, char]
    var c = 0
    let t = cpuTime()
    for i in 0..<numIter:
      let x = genFloat(i)
      let m = algo(buf, x)
      when false: # debugging
        var s = ""
        s.addCharsN(buf[0].addr, m)
        echo s
      c += m
    let t2 = cpuTime() - t
    doAssert c != 0
    echo (astToStr(algo), astToStr(genFloat), t2)
  main()

template genFloatCast(i): untyped = cast[float](i)
template genFloatConf(i): untyped = float(i)

template genFloat32Cast(i): untyped = cast[float32](i)
template genFloat32Conf(i): untyped = float32(i)

template gen(algo) =
  gen(algo, genFloatCast)
  gen(algo, genFloatConf)
  gen(algo, genFloat32Cast)
  gen(algo, genFloat32Conf)

template main =
  gen(toStringSprintf)
  gen(toStringDragonbox)
  gen(toStringDragonbox0)

when isMainModule:
  main()
