#!/bin/bash


TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

pushd $TEST_DIR
cd ..
WORKSPACE=`pwd`
popd


die() {
        echo "$1"
        exit 1
}

HUGEPAGE=0
MYSQL_HOME=$WORKSPACE/install/mysql_install_8.0.33
START_SERVER=1

while getopts n:ludo flag
do
    case "${flag}" in
        n) NUM_TMS=${OPTARG};;
        d) START_SERVER=0;;
        l)
                HUGEPAGE=1
                MYSQL_HOME=/mysql_data/mysql_install_huge;;
        o)
                HUGEPAGE=1
                MYSQL_HOME=/mysql_data/mysql_install_huge_lto;;
    esac
done


MYSQL_BIN=$MYSQL_HOME/bin
MYSQL_PLUGIN=$MYSQL_HOME/lib/plugin
MYSQL_DATA=$WORKSPACE/data/mysql_data
MYSQL_CNF_FILE=$WORKSPACE/config/my.cnf
MYSQL_USER=`id -un`

if [ ! -d $MYSQL_DATA ]; then
        mkdir -p $MYSQL_DATA
fi

start_mysql_server() {
        rm -rf $MYSQL_DATA/*
        PORT=3003


        if [ $HUGEPAGE -eq 1 ]; then
                HUGETLB_ELFMAP=RW $MYSQL_BIN/mysqld \
                        --initialize-insecure \
                        --basedir=$MYSQL_HOME \
                        --datadir=$MYSQL_DATA \
                        --default_authentication_plugin=mysql_native_password \
                        --log-error-verbosity=3 || die "failed to start mysqld 1"
                HUGETLB_ELFMAP=RW $MYSQL_BIN/mysqld \
                        --defaults-file=$MYSQL_CNF_FILE \
                        --basedir=$MYSQL_HOME \
                        --datadir=$MYSQL_DATA \
                        --socket=$MYSQL_HOME/mysql.sock \
                        --port=$PORT \
                        --log-error=$MYSQL_HOME/log.err \
                        --log-error-verbosity=3 \
                        --secure-file-priv="" \
                        --plugin-dir=$MYSQL_PLUGIN \
                        --user=$MYSQL_USER \
                        2>&1 &

        else
                $MYSQL_BIN/mysqld \
                --initialize-insecure \
                --basedir=$MYSQL_HOME \
                --datadir=$MYSQL_DATA \
                --default_authentication_plugin=mysql_native_password \
                --log-error-verbosity=3 || die "failed to start mysqld 1"

                $MYSQL_BIN/mysqld \
                        --defaults-file=$MYSQL_CNF_FILE \
                        --basedir=$MYSQL_HOME \
                        --datadir=$MYSQL_DATA \
                        --socket=$MYSQL_HOME/mysql.sock \
                        --port=$PORT \
                        --log-error=$MYSQL_HOME/log.err \
                        --log-error-verbosity=3 \
                        --secure-file-priv="" \
                        --plugin-dir=$MYSQL_PLUGIN \
                        --user=$MYSQL_USER \
                        2>&1 &
        fi

        i=0
        while [ 1 ]; do
                if [ -e $MYSQL_HOME/mysql.sock ]; then
                        echo "mysqld started"
                        break
                else
                        i=$((i+1))
                        echo "waiting for mysql to be started, $i seconds elapsed"
                        sleep 1
                fi
        done

        echo "ready to create mysql user"

        # create mysql user
        $MYSQL_BIN/mysql \
                -S $MYSQL_HOME/mysql.sock \
                -uroot \
                -e "use mysql; \
                update user set user.Host='%' where user.User='root'; \
                FLUSH PRIVILEGES; \
                CREATE DATABASE IF NOT EXISTS sysdb; \
                create user sysbench@'%' identified by 'password'; \
                grant all privileges on sysdb.* to sysbench@'%';" || die "failed to create mysql user"

        echo "start mysql done"
}

stop_mysql_server() {
        $MYSQL_BIN/mysql -S $MYSQL_HOME/mysql.sock -uroot -e "DROP DATABASE sysdb;"

        $MYSQL_BIN/mysqladmin -S $MYSQL_HOME/mysql.sock -uroot shutdown || die "failed to stop mysql server"

        while [ 1 ]; do
                ps -ef |grep mysqld | grep -v grep > /dev/null
                if [ $? -ne 0 ]; then
                        echo "mysqld stopped"
                        break
                else
                        sleep 1
                fi
        done

        #rm -rf $MYSQL_HOME/mysql/datadir/*
        #rm -rf $MYSQL_HOME/undo/*
}



if [ $START_SERVER -eq 1 ]; then
        start_mysql_server
else
        stop_mysql_server
fi
