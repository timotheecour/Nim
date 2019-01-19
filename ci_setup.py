import os
from shutil import copyfile

def runCmd(cmd):
  print(("runCmd",cmd))
  import subprocess
  subprocess.check_call(cmd, shell=True)

def setup():
  print("from python")
  from sys import platform
  print("platform:" + platform)
  if platform == "linux" or platform == "linux2":
    # linux
    runCmd("apt-get install nim")
  elif platform == "darwin":
    # OS X
    runCmd("brew install nim")
    runCmd("which nim")
    runCmd("nim --version")
    # runCmd("cp $(which nim) bin/nim") # IMPROVE

    old_nim = shutil.which('nim')
    assert(old_nim is not None)
    copyfile(old_nim, "bin/nim")
  elif platform == "win32":
    # Windows...
    # TODO
    pass
setup()

