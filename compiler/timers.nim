## Simpler timer module, with emphasis on ease of use

# todo: allow reporting timers even when `quit` was called; maybe via a quit
# handler (`addQuitProc`)

import times, strutils
include $nimc_D/lib/system/helpers.nim
include "$nim/lib/system/helpers.nim"

type Timer = object
  id: string ## unique id for timer
  duration: float ## total time spent
  count: int ## number of times timer was hit

proc reportTime(time: var float) =
  var time2 = epochTime()
  let duration = time2 - time
  let s = formatFloat(duration, format = ffDecimal, precision = 3)
  echo "elapsed time (s): " & s
  time = time2

proc reportTimer(time1, time2: float, )

template withTimer(body)=
  block:
    let time = epochTime()
    body
    let time2 = epochTime()
    reportTimer(time, time2, instantiationInfo(-2))
