# for CI

set -e
set -u

echo_run(){
  echo "$@" && "$@"
}

run_all(){
  (
    echo $0
    echo $SHELL
    echo_run pwd
    # echo pwd:$(pwd)
    # echo imageName:$(imageName)
    # echo_run echo $(imageName)
    # doesn't work: echo imageName2:${imageName}
    # echo "env:"
    echo_run env

    echo_run echo $MY_VAR

    # note: node too old, gives SyntaxError: Unexpected token function
    # v6.16.0
    # /usr/local/bin/node
    # Updating Homebrew...

    echo_run node --version
    echo_run which node
    # brew upgrade node
    echo_run brew install node || brew link --overwrite node
    echo_run which node
    echo_run node --version
    echo_run echo "ok1"
  )
}

run_all

