discard """
  action: run
  exitcode: 1
"""

when defined(case1):
  close stdmsg
  writeLine stdmsg, "exception!"
else:
  doAssert 1==2
