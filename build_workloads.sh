#!/bin/bash
WORKSPACE=`pwd`

source $WORKSPACE/scripts/lib.sh

if [ ! -d $WORKSPACE/install ]; then
        mkdir $WORKSPACE/install
fi

MYSQL_INSTALL_DIR=$WORKSPACE/install/mysql_install_8.0.33
build_mysql() {
        for package in git cmake g++ openssl libssl-dev libncurses5-dev libtirpc-dev rpcsvc-proto bison pkg-config; do
                install_package $package
        done


        if [ ! -d boost_1_77_0 ]; then
                wget https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.gz && tar xzvf boost_1_77_0.tar.gz
        fi

        if [ ! -d mysql-server ]; then
                git clone https://github.com/mysql/mysql-server || die "failed to clone mysql"
                cd mysql-server
                git checkout mysql-8.0.33
                git submodule update --recursive
                mkdir build
        else
                cd mysql-server
        fi

        cd build

        cmake -DCMAKE_C_FLAGS="-g -O3 -mcpu=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
                -DCMAKE_CXX_FLAGS="-g -O3 -mcpu=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
                -DCMAKE_INSTALL_PREFIX=$WORKSPACE/install/mysql_install_8.0.33 \
                -DWITH_BOOST=$WORKSPACE/boost_1_77_0/ .. || die "failed to cmake"

        make -j $(nproc) || die "failed to make"

        make -j $(nproc) install || die "failed to make install"

        cd ../..
}

build_sysbench() {
        for package in make automake libtool pkg-config libaio-dev libmysqlclient-dev libssl-dev; do
                install_package $package
        done

        if [ ! -d sysbench ]; then
                git clone https://github.com/akopytov/sysbench || die "failed to clone mysql"
                cd sysbench
                ./autogen.sh || die "failed to autogen"

        else
                cd sysbench
        fi


        ./configure --with-mysql-includes=$MYSQL_INSTALL_DIR/include --with-mysql-libs=$MYSQL_INSTALL_DIR/lib --prefix=$WORKSPACE/install/sysbench || die "failed to configure mysql"

        make -j $(nproc) || die "failed to make"
        make -j $(nproc) install || die "failed to make install"

        cd ..
}

build_bolt() {

        install_package ninja-build
        if [ ! -d llvm-project ]; then
                git clone https://github.com/llvm/llvm-project.git
                mkdir $WORKSPACE/install/llvm-install
        fi
        cd $WORKSPACE/install/llvm-install

        cmake -G Ninja $WORKSPACE/llvm-project/llvm -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
                -DCMAKE_BUILD_TYPE=Release \
                -DLLVM_ENABLE_ASSERTIONS=ON \
                -DLLVM_ENABLE_PROJECTS="bolt" || die "failed to cmake"
        ninja bolt || die "failed to build bolt"

}
build_all() {
        build_mysql
        build_sysbench
        build_bolt
}


SECONDS=0


case "$1" in
  "mysql")
    build_mysql
    ;;
  "sysbench")
    build_sysbench
    ;;
  "bolt")
    build_bolt
    ;;
  "")
    build_all
    ;;
  *)
    echo "The first command-line option is: $1"
    ;;
esac


ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo "build done, $ELAPSED"

