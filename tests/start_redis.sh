#!/bin/bash

TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd



$WORKSPACE/redis/src/redis-server $WORKSPACE/redis/redis.conf
