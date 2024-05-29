#!/bin/bash
TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd

source $WORKSPACE/scripts/lib.sh

install_package default-jre

if [ ! -d ycsb-0.17.0 ]; then
	curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz || die "failed to download ycsb"
	tar xfvz ycsb-0.17.0.tar.gz
fi

cd $WORKSPACE/ycsb-0.17.0
if [ "$2" == "ins" ]; then
	OP_CNT=5000000

	./bin/ycsb.sh load mongodb -s -P workloads/workloada -p operationcount=$OP_CNT -threads 64 -p mongodb.url="mongodb://$1:27017/ali" | tee workloada.txt
	./bin/ycsb.sh run mongodb -s -P workloads/workloada  -p operationcount=$OP_CNT -threads 64 -p mongodb.url="mongodb://$1:27017/ali" | tee workloada.txt
else
	REC_CNT=6000000
	OP_CNT=5000000

	./bin/ycsb.sh load mongodb -s -P workloads/workloada -p recordcount=$REC_CNT -p operationcount=$OP_CNT -threads 64 -p mongodb.url="mongodb://$1:27017/ali" | tee workloada.txt
	./bin/ycsb.sh run mongodb -s -P workloads/workloada -p recordcount=$REC_CNT -p operationcount=$OP_CNT -threads 64 -p mongodb.url="mongodb://$1:27017/ali" | tee workloada.txt
fi
