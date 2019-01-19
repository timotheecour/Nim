import os
import shutil

def runCmd(cmd):
  print(("runCmd",cmd))
  import subprocess
  # subprocess.check_call(cmd, shell=True) # BUG: this doesn't print anything in azure!
  output = subprocess.check_output(cmd, shell=True)
  # output=output.decode('ascii')
  output=output.decode('utf8')
  print("output:")
  print(output)
  # subprocess.check_call(cmd, shell=True, stdout=subprocess.STDOUT)

def setup():
  print("from setup")
  from sys import platform
  print("platform:" + platform)
  if platform == "linux" or platform == "linux2":
    # linux
    runCmd("sudo apt-get install nim")
    # TODO: 2019-01-19T13:29:45.4186042Z Setting up nim (0.12.0-2) ...
  elif platform == "darwin":
    # OS X
    runCmd("pwd")
    runCmd("echo foo1; sleep 1; echo foo2;sleep 1; echo foo3;")

    runCmd("brew install nim")
    runCmd("which nim")
    runCmd("nim --version")

    # runCmd("cp $(which nim) bin/nim") # IMPROVE
    old_nim = shutil.which('nim')
    print(('old_nim', old_nim))
    assert(old_nim is not None)

    runCmd("pwd")
    runCmd("ls bin")
    shutil.copyfile(old_nim, "bin/nim")
    runCmd("ls bin")
    runCmd("cp " + old_nim + ' ' + "bin/nim")
    runCmd("ls bin")


  elif platform == "win32":
    # Windows...
    # TODO
    pass
  
  runCmd("nim --version")

print("python start")

setup()


print("done")
