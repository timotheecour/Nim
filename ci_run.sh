# for CI

set -u

echo_run(){
  echo "$@" && "$@"
}

run_all(){
  (
    set -e
    echo_run pwd
    # echo imageName:$(imageName)
    echo_run env
    echo_run echo $MY_VAR

    echo_run brew install nim
    echo_run which nim
    echo_run nim --version

    # sh build_all.sh

    #git clone --depth 1 https://github.com/nim-lang/csources.git
    #cd csources
    #sh build.sh
    #cd
  )
}

run_all

