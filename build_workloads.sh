#!/bin/bash
WORKSPACE=`pwd`

source $WORKSPACE/scripts/lib.sh

if [ ! -d $WORKSPACE/install ]; then
        mkdir $WORKSPACE/install
fi

ARCH=`lscpu | grep Architecture | awk '{print $2}'`

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

	if [ "$ARCH" == "aarch64" ]; then

		cmake -DCMAKE_C_FLAGS="-g -O3 -mcpu=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
			-DCMAKE_CXX_FLAGS="-g -O3 -mcpu=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
			-DCMAKE_INSTALL_PREFIX=$WORKSPACE/install/mysql_install_8.0.33 \
			-DWITH_BOOST=$WORKSPACE/boost_1_77_0/ .. || die "failed to cmake"
	elif [ "$ARCH" == "x86_64" ]; then
		cmake -DCMAKE_C_FLAGS="-g -O3 -march=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
			-DCMAKE_CXX_FLAGS="-g -O3 -march=native -fno-reorder-blocks-and-partition -Wl,--emit-relocs" \
			-DCMAKE_INSTALL_PREFIX=$WORKSPACE/install/mysql_install_8.0.33 \
			-DWITH_BOOST=$WORKSPACE/boost_1_77_0/ .. || die "failed to cmake"
	else
		die "unsupported arch $ARCH"
	fi

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

build_redis() {
	if [ ! -d redis ]; then
		git clone --recursive --depth 1 --branch 6.0.9 https://github.com/redis/redis.git || die "failed to clone redis"
		cd redis
		patch -p1 < $WORKSPACE/patches/redis.patch || die "failed to patch redis"
	else
		cd redis
	fi
	make -j $(nproc) || die "failed to build redis"

	sed -i "s/^port 6379/port 9400/" redis.conf
	sed -i 's/^bind 127.*$/bind 0\.0\.0\.0 ::1/' redis.conf
	sed -i "s/^daemonize no/daemonize yes/" redis.conf
	sed -i "s/^# maxclients 10000/maxclients 10000/" redis.conf
	echo 'save ""' >> redis.conf
}

build_memtier() {
	for package in build-essential autoconf automake libpcre3-dev libevent-dev pkg-config zlib1g-dev libssl-dev git; do
		install_package $package
	done
	if [ ! -d memtier_benchmark ]; then
		git clone https://github.com/RedisLabs/memtier_benchmark.git || die "failed to clone memtier"
	fi
	cd memtier_benchmark
	autoreconf -ivf || die "failed to autoreconf memtier"
	./configure || die "failed to configure memtier"
	make -j $(nproc) || die "failed to build memtier"
	sudo make install || die "failed to install memtier"
}

build_memcached() {
	for package in autotools-dev automake libevent-dev; do
		install_package $package
	done
	module="memcached"
	if [ ! -d memcached ]; then
		git clone https://github.com/memcached/memcached.git || die "failed to clone $module"
		cd memcached
		./autogen.sh || die "failed to autogen $module"
		./configure || die "failed to configure $module"
		patch -p0 < $WORKSPACE/patches/memcached.patch || die "failed to patch $module"
	else
		cd memcached
	fi

	make -j $(nproc) || die "failed to make $module"
}

build_nginx() {
	if [ ! -d nginx ]; then
		pushd /tmp
		apt source nginx
		mv nginx-* $WORKSPACE/nginx
		popd
		cd nginx
		CFLAGS="-fno-reorder-blocks-and-partition" \
			CXXFLAGS="-fno-reorder-blocks-and-partition" \
			./configure --without-http_rewrite_module --prefix=$WORKSPACE/install/nginx || die "failed to configure nginx"
		patch -p0 < $WORKSPACE/patches/nginx.patch || die "failed to patch nginx"
	else
		cd nginx
	fi

	make -j $(nproc) || die "failed to make nginx"
	make -j $(nproc) install || die "failed to make nginx"
}

build_mongo() {
	for package in libcurl4-openssl-dev python3 python-is-python3; do
		install_package $package
	done
	if [ ! -d mongo ]; then
		git clone https://github.com/mongodb/mongo.git || die "failed to clone mongo"
		cd mongo
		git checkout r7.0.5
		python -m pip install -r etc/pip/compile-requirements.txt || die "failed to install requirements for mongo"
		#patch -p1 < $WORKSPACE/patches/mongo.patch || die "failed to patch mongo"
	else
		cd mongo
	fi

	python3 buildscripts/scons.py DESTDIR=$WORKSPACE/install/mongo install-mongod \
		CCFLAGS="-fno-reorder-blocks-and-partition -mcpu=native -O3 -w" \
		LINKFLAGS="-Wl,--emit-relocs" \
		--disable-warnings-as-errors || die "failed to build mongo"
}

build_gcc() {
	install_package flex

	if [ ! -d gcc-11.4.0 ]; then
		wget https://ftp.gwdg.de/pub/misc/gcc/releases/gcc-11.4.0/gcc-11.4.0.tar.gz && tar -xzvf gcc-11.4.0.tar.gz
		cd gcc-11.4.0
		./contrib/download_prerequisites
		mkdir build
		cd build
		../configure -v --build=aarch64-linux-gnu \
			--host=aarch64-linux-gnu \
			--target=aarch64-linux-gnu \
			--enable-checking=release \
			--enable-languages=c,c++ \
			--disable-multilib || die "failed to configure gcc, stage 1"

		../configure --prefix=$WORKSPACE/install/gcc-11 \
			--disable-multilib \
			--program-suffix=-11 \
			--program-prefix=aarch64-linux-gnu-  \
			--enable-languages=c,c++ \
			--with-gcc-major-version-only \
			--enable-checking=release || die "failed to configure gcc, stage 2"
	else
		cd gcc-11.4.0
	fi

	make -j $(nproc) || die "failed to make gcc"
	make -j $(nproc) install || die "failed to install gcc"
}


build_fdo() {
	for package in cmake ninja-build protobuf-compiler libprotobuf-dev libunwind-dev libgflags-dev libssl-dev libelf-dev; do
		install_package $package
	done

	if [ ! -d autofdo ]; then
		git clone --recursive https://github.com/google/autofdo.git || die "failed to pull autofdo"
		cd autofdo
		mkdir build
		cd build
		cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=. ../ || die "failed to cmake autofdo"

	else
		cd autofdo/build
	fi

	ninja || die "failed to build autofdo"

	cd ../..
}

build_all() {
        build_mysql
        build_sysbench
        build_bolt
	build_redis
	build_memtier
	build_memcached
	build_nginx
	build_mongo
	build_gcc
	build_fdo
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
  "redis")
    build_redis
    ;;
  "memtier")
    build_memtier
    ;;
  "memcached")
    build_memcached
    ;;
  "nginx")
    build_nginx
    ;;
  "mongo")
    build_mongo
    ;;
  "gcc")
    build_gcc
    ;;
  "fdo")
    build_fdo
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

