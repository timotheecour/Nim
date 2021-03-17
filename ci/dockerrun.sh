. ci/funs.sh
echo_run pwd
echo_run apt-get update
echo_run apt-get install -y software-properties-common
echo_run add-apt-repository -y ppa:git-core/ppa
echo_run apt-get update
echo_run apt-get install -yq cmake make gcc g++ git curl

echo_run sh build_all.sh
echo_run ./koch runCI
