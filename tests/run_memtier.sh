#!/bin/bash

memtier_benchmark -s $1 -p 9400 -t 8 --test-time=300 -c 10 --ratio=1:1 --pipeline=1 -d 32 --key-maximum=100000 --run-count 1 --out-file pipeline1_8core_g8m_2x_9400
