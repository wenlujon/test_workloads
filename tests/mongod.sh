#!/bin/bash
TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

CONFIG=$WORKSPACE/config/mongod.conf
DATADIR=$WORKSPACE

if [ "$1" == "start" ]; then
	pid=`pidof mongod`

	if [ -n "$pid" ]; then
		die "mongod already started"
	fi

	rm -rf $DATADIR/mongo_data/*
	mkdir -p $DATADIR/mongo_data/data
	mkdir -p $DATADIR/mongo_data/log
	mkdir -p $DATADIR/mongo_data/config
	echo "dbpath=$DATADIR/mongo_data/data" > $CONFIG
	echo "logpath=$DATADIR/mongo_data/log/mongod.log" >> $CONFIG
	echo "pidfilepath=$DATADIR/mongo_data/data/node1.pid" >> $CONFIG
	echo "fork=true" >> $CONFIG
	echo "bind_ip=$2" >> $CONFIG
	echo "port=27017" >> $CONFIG
	
	$WORKSPACE/install/mongo/bin/mongod -f $CONFIG --wiredTigerCacheSizeGB=20 || die "failed to start mongod"

	pid=`pidof mongod`

	if [ $? -ne 0 ]; then
		die "failed to start mongod"
	else
		echo "mongod started, PID: $pid"
	fi

elif [ "$1" == "stop" ]; then
	pid=`pidof mongod`
	if [ -n "$pid" ]; then
		kill $pid

		while [ 1 ]; do
			pidof mongod > /dev/null

			if [ $? -ne 0 ]; then
				echo "mongod stopped"
				break
			fi
		done
	else
		die "oops, mongod was not running"
	fi

else
	echo "tests/mongod.sh [start | stop]"
fi
