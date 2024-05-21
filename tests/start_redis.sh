#!/bin/bash

TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

install_package numactl
numactl -C 0 $WORKSPACE/redis/src/redis-server $WORKSPACE/redis/redis.conf
