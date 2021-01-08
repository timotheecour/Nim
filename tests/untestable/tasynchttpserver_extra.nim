#[
adapted from the runnableExamples in asynchttpserver.nim

## works on linux

## TODO
* support osx + other platforms; the missing part is `/proc/{pid}/fd`
maybe something based on lsof could work
* turn this into a proper test that doesn't require user interaction

* D20210107T122027:here BUG: why -1 in `result = int(fdLim.rlim_cur) - 1`  in asyncdispatch.maxDescriptors ?
]#

when true:
  # This example will create an HTTP server on port 8080. The server will
  # respond to all requests with a `200 OK` response code and "Hello World"
  # as the response body.
  import asynchttpserver
  import asyncdispatch
  import os, osproc, strformat, strutils

  proc getCmdOutput(cmd: string): string =
    var (outp, status) = execCmdEx(cmd)
    doAssert status == 0, cmd
    doAssert status == 0
    outp.stripLineEnd
    result = outp

  proc getNumOpenFiles(): int =
    let pid = getCurrentProcessId()
    # xxx remove the pipe so that we only spawn 1 process, not 2, leading to 3 extra fds, not 6
    let s = getCmdOutput fmt"ls -1 /proc/{pid}/fd | wc -l"
    result = s.parseInt

  proc getNumOpenFilesMax(): int =
    # this could potentially change over time
    when false:
      result = getCmdOutput(fmt"ulimit -Sn").parseInt
    result = maxDescriptors() + 1 # + 1 because of D20210107T122027

  proc shouldAcceptRequest2(numFdPerRequest = 1): bool =
    let num = getNumOpenFiles()
    let numMax = getNumOpenFilesMax()
    let numExtra = 6 # because of `getNumOpenFiles`
    result = num + numFdPerRequest + numExtra <= numMax
    echo ("shouldAcceptRequest2", num, numMax, result)

  var count = 0
  proc main {.async.} =
    const port = 8080
    var server = newAsyncHttpServer()
    proc cb(req: Request) {.async.} =
      let count2 = atomicInc(count) # count.inc would be buggy
      echo (count2, req.reqMethod, req.url, req.headers)
      let headers = {"Date": "Tue, 29 Apr 2014 23:40:08 GMT",
          "Content-type": "text/plain; charset=utf-8"}
      await sleepAsync(5_000)
      await req.respond(Http200, &"Hello World: {count2}\n", headers.newHttpHeaders())

    echo fmt"test this with: curl localhost:{port}/"
    server.listen Port(port)
    while true:
      if shouldAcceptRequest2(1):
        await server.acceptRequest(cb)
      else:
        # too many files opened, likely caused by too many concurrent connections (`maxFDs` exceeded)
        poll()

  asyncCheck main()
  runForever()
