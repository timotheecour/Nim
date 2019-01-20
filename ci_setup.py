import os
import shutil

def runCmd(cmd):
  # D20190120T053813
  print(("runCmd",cmd))
  import subprocess
  subprocess.check_call(cmd, shell=True)

def buildNimCsources():
  runCmd("git clone --depth 1 https://github.com/nim-lang/csources.git")
  runCmd("cd csources && sh build.sh")

def setup():
  print("from setup")
  from sys import platform
  print("platform:" + platform)
  if platform == "linux" or platform == "linux2": # linux
    # runCmd("sudo apt-get install nim") # too old: 0.12.0-2 on ubunty 16.04
    # todo: maybe linux brew for nim as well?
    buildNimCsources()
  elif platform == "darwin": # OSX
    runCmd("pwd")
    runCmd("brew install nim")
    print(shutil.which('nim'))

    old_nim = shutil.which('nim')
    print(('old_nim', old_nim))
    assert(old_nim is not None)
    shutil.copy(old_nim, "bin/nim")

  elif platform == "win32": # windows
    # TODO
    pass
  
  runCmd("bin/nim --version")

print("python script v3")

setup()

print("done")
