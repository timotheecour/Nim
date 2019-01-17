discard """
  action: run
  exitcode: 1
"""

close stdmsg
writeLine stdmsg, "exception!"
# doAssert 1==2
