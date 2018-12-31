discard """
  cmd: "nim $target --contextLines:2 $options $file"
  outputsub: '''
tstacktrace_with_source.nim(29, 5)  in tstacktrace_with_source: 
  
* main()
tstacktrace_with_source.nim(27, 36)  in main: 
  proc main()=
*   if foo1(1) > 0: discard foo1(foo1(2))
tstacktrace_with_source.nim(23, 11)  in foo1: 
  proc foo1(a: int): auto =
*   doAssert a < 4
'''
exitcode: "1"
"""




## line 20

proc foo1(a: int): auto =
  doAssert a < 4
  result = a * 2

proc main()=
  if foo1(1) > 0: discard foo1(foo1(2))

main()
