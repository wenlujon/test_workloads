#!/bin/bash

if [ "$1" == "redis" ]; then
	memtier_benchmark -s $2 -p 9400 -t 8 --test-time=300 -c 10 --ratio=1:1 --pipeline=1 -d 32 --key-maximum=100000 --run-count 1 --out-file pipeline1_8core_g8m_2x_9400
elif [ "$1" == "memcached" ]; then
	memtier_benchmark -s $2 -p 11211 --protocol=memcache_text --test-time=300 --clients=100 --threads=5 --ratio=1:1 --key-pattern=R:R --key-minimum=16 --key-maximum=16 --data-size=128 --run-count=1 --out-file memcached_g8m
else
	echo "$0 [ redis | memcached ] [ip]"
	exit 0
fi
