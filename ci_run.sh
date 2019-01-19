# for CI

set -u

echo_run(){
  echo "$@" && "$@"
}

run_all(){
  # doesn't seem to work wrt D20190119T040042
  # export NIM_LIB_PREFIX=$(pwd)

  (
    set -e
    echo_run pwd
    # echo imageName:$(imageName)
    echo_run env
    echo_run echo $MY_VAR

    echo_run brew install nim
    echo_run which nim
    echo_run nim --version

    # HACK, avoids: D20190119T040047:here
    # koch.nim(27, 8) Error: cannot open file: /usr/local/Cellar/nim/0.19.0/nim/tools/ciutils
    # maybe use 

    echo_run cp $(which nim) bin/nim

    # sh build_all.sh

    #git clone --depth 1 https://github.com/nim-lang/csources.git
    #cd csources
    #sh build.sh
    #cd
  )
}

run_all

