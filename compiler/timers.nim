## Simpler timer module, with emphasis on ease of use

# todo: allow reporting timers even when `quit` was called; maybe via a quit
# handler (`addQuitProc`)

import times, strutils, tables, strformat, algorithm
include "$nim/lib/system/helpers.nim"
import compiler/asciitables

type TimeType = float

type Timer = ref object
  id: string ## unique id for timer
  duration: TimeType ## total time spent
  count: int ## number of times timer was hit
  info: string # consider using InstantiationInfo

# var timers: Table[string, Timer]
var timers = initTable[string, Timer]()

proc reportTime(time: var TimeType) =
  var time2 = epochTime()
  let duration = time2 - time
  let s = formatFloat(duration, format = ffDecimal, precision = 3)
  echo "elapsed time (s): " & s
  time = time2

proc reportTimer(id: string, time1, time2: TimeType, info: InstantiationInfo) =
  let duration = time2-time1
  # echo id
  # echo timers.contains(id) # BUG: nim should check whether initialized
  # if timers.:
  if id in timers:
  # if false:
    timers[id].duration += duration
    timers[id].count.inc
  else:
    timers[id] = Timer(id:id, duration: duration, count: 1, info: $info)

template withTimer*(msg: string, body)=
  block:
    let time1 = epochTime()
    body
    let time2 = epochTime()
    const info = instantiationInfo(-2)
    # let id = if msg == "": $info else: msg
    let id = $info & msg
    reportTimer(id, time1, time2, info)

template withTimer*(body)=
  withTimer("", body)

proc `$`(a: Timer): string =
  let s = formatFloat(a.duration, format = ffDecimal, precision = 3)
  result = &"{a.info}\tid:{a.id}\td:{s}\tc:{a.count}"

proc timersToStr*(): string =
  var timers2: seq[Timer]
  for k,v in timers:
    timers2.add v
  proc cmp2(a,b: Timer): int = cmp(a.duration, b.duration)
  sort(timers2, cmp2)
  result.add "timers:\n"
  var ret = ""
  for a in timers2:
    ret.add $a & "\n"
  result.add alignTable(ret)


# PRTEMP: conditional
# proc dispTimers() {.noconv.} =
proc dispTimers() {.noconv.} =
  echo timersToStr()

addQuitProc(dispTimers)

when isMainModule:
  import math
  var x = 0.0

  proc test1()=
    for i in 0..<1000:
      withTimer:
        x += exp(- 1.0 * float(i))

  proc fun(a: int) =
    withTimer: test1()
    withTimer($a): test1()

  proc main() =
    fun(10)
    fun(20)
    fun(10)

  main()
  # echo timersToStr()

