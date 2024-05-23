#!/bin/bash
TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

if [ "$1" == "start" ]; then
	mem_pid=`pidof memcached`

	if [ -n "$mem_pid" ]; then
		die "memcached already started"
	fi
	
	$WORKSPACE/memcached/memcached -d -p 11211 -m 2048 -c 20000 -u root -l $2

	mem_pid=`pidof memcached`

	if [ $? -ne 0 ]; then
		die "failed to start memcached"
	else
		echo "memcached started, PID: $mem_pid"
	fi

elif [ "$1" == "stop" ]; then
	mem_pid=`pidof memcached`
	if [ -n "$mem_pid" ]; then
		kill $mem_pid

		while [ 1 ]; do
			pidof memcached > /dev/null

			if [ $? -ne 0 ]; then
				echo "memcached stopped"
				break
			fi
		done
	else
		die "oops, memcached was not running"
	fi

else
	echo "tests/memcached.sh [start | stop]"
fi
