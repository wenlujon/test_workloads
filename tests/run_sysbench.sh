#!/bin/bash

#affinity="taskset -c 0-15"
affinity=""
SERVERIP=$1
PORT=3003
#sync && echo 3 > /proc/sys/vm/drop_caches
#mode=oltp_read_only
mode=oltp_write_only
#mode=oltp_read_write

warmup_time=60
run_time=300
#run_time=120


for nthread in 256
do
        echo "${time} $mode Testing Ali config on mysql-8.0.25: nthread ${nthread}"

        $affinity sysbench $mode --db-ps-mode=auto --mysql-host=$SERVERIP --mysql-port=$PORT --mysql-user=sysbench --mysql-password=password --mysql-db=sysdb --tables=100 --table_size=400000 --time=300 --report-interval=1 --threads=64 cleanup
        echo "===> finish cleanup"
        sleep 1

        $affinity sysbench $mode --db-ps-mode=auto --mysql-host=$SERVERIP --mysql-port=$PORT --mysql-user=sysbench --mysql-password=password --mysql-db=sysdb --tables=100 --table_size=400000 --time=300 --report-interval=1 --threads=64 prepare
        echo "===> finish prepare"
        sleep 1

        $affinity sysbench $mode --db-ps-mode=auto --mysql-host=$SERVERIP --mysql-port=$PORT --mysql-user=sysbench --mysql-password=password --mysql-db=sysdb --tables=100 --table_size=400000 --warmup-time=${warmup_time} --time=${run_time} --report-interval=10 --threads=${nthread} run

        echo "===> finish run"
        sleep 1
done

