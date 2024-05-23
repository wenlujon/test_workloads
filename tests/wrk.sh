#!/bin/bash

TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

install_package wrk

if [ $1 == "long" ]; then
	wrk -t 32 -c 1000 -d 30 --latency http://$2
elif [ $1 == "short" ]; then
 	wrk -t 32 -c 1000 -d 30  -H 'Connection: close'  --latency http://$2
else
	echo "tests/wrk.sh [long | short] [ip]"
fi
