discard """
  action: run
  exitcode: 1
  targets: "c cpp"
  disabled: "openbsd"
  disabled: "netbsd"
"""

close stdmsg
writeLine stdmsg, "exception!"

when false:
  # was there a 2nd issue/subtelty here?
  const m = "exception!"
  discard writeBuffer(stdmsg, cstring(m), m.len)
