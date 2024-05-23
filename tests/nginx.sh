#!/bin/bash
TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

if [ "$1" == "start" ]; then
	mem_pid=`pidof nginx`

	if [ -n "$mem_pid" ]; then
		die "nginx already started"
	fi
	
	sudo $WORKSPACE/install/nginx/sbin/nginx

	mem_pid=`pidof nginx`

	if [ $? -ne 0 ]; then
		die "failed to start nginx"
	else
		echo "nginx started, PID: $mem_pid"
	fi

elif [ "$1" == "stop" ]; then
	mem_pid=`pidof nginx`
	if [ -n "$mem_pid" ]; then
		sudo kill $mem_pid

		while [ 1 ]; do
			pidof nginx > /dev/null

			if [ $? -ne 0 ]; then
				echo "nginx stopped"
				break
			fi
			sleep 1
		done
	else
		die "oops, nginx was not running"
	fi

else
	echo "tests/nginx.sh [start | stop]"
fi
