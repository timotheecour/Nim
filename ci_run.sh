# for CI

set -u

echo_run(){
  echo "$@" && "$@"
}

install_nim_bootstarp(){
  # this doesn't seem to work wrt D20190119T040042
  # export NIM_LIB_PREFIX=$(pwd)

  (
    set -e
    echo_run pwd
    # echo imageName:$(imageName)
    echo_run env
    echo_run echo $MY_VAR

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        # echo linux
        echo_run apt-get install nim
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      echo_run brew install nim
      echo_run which nim
      echo_run nim --version

      # HACK, avoids:
      # koch.nim(27, 8) Error: cannot open file: /usr/local/Cellar/nim/0.19.0/nim/tools/ciutils
      # note: setting `NIM_LIB_PREFIX` doesn't work
      echo_run cp $(which nim) bin/nim
    else
        echo unknown
    fi

    # sh build_all.sh
    #git clone --depth 1 https://github.com/nim-lang/csources.git
    #cd csources
    #sh build.sh
    #cd
  )
}

install_nim_bootstarp
