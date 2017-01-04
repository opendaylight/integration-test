#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo '---> Download compile and install the 6Wind Quagga'
#Install the required softwares for building quagga
    sudo yum -y group install "Development Tools"
    sudo yum -y install readline-devel
    sudo yum -y install glib2-devel

#Create Build directory
    export CURRENT_FOLDER=`pwd`
    export BUILD_FOLDER="${CURRENT_FOLDER}/6wind_quagga_build_dir"
    rm -rf "${BUILD_FOLDER}"
    mkdir -p "${BUILD_FOLDER}"
    cd "${BUILD_FOLDER}"

#Clean the directory if exists
    sudo rm -rf c-capnproto thrift zeromq4-1 quagga zrpcd

#Checkout Compile and Install thrift
    git clone https://git-wip-us.apache.org/repos/asf/thrift.git
    cd thrift
    touch NEWS README AUTHORS ChangeLog

    autoreconf -i
    ./configure --without-qt4 --without-qt6 --without-csharp --without-java\
    --without-erlang --without-nodejs --without-perl --without-python\
    --without-php --without-php_extension --without-dart --without-ruby\
    --without-haskell --without-go --without-haxe --without-d\
    --prefix=/opt/quagga
    make
    sudo make install
    cd ..

#Checkout Compile and Install ZeroMQ
    git clone https://github.com/zeromq/zeromq4-1.git
    cd zeromq4-1
    git checkout 56b71af22db3
    autoreconf -i
    ./configure --without-libsodium --prefix=/opt/quagga
    make
    sudo make install
    cd ..

#Checkout Compile and Install C-capnproto
    git clone https://github.com/opensourcerouting/c-capnproto
    cd c-capnproto
    git checkout 332076e52257
    autoreconf -i
    ./configure --prefix=/opt/quagga --without-gtest
    make
    sudo mkdir /opt/quagga/lib -p
    sudo mkdir /opt/quagga/include/c-capnproto -p

    sudo cp -f capn.h /opt/quagga/include/c-capnproto/.
    sudo cp .libs/libcapn.so.1.0.0 .libs/libcapn_c.so.1.0.0
    sudo ln -s $BUILD_FOLDER/c-capnproto/.libs/libcapn_c.so.1.0.0 $BUILD_FOLDER/c-capnproto/.libs/libcapn_c.so
    sudo cp .libs/libcapn.so.1.0.0 /opt/quagga/lib/libcapn_c.so.1.0.0
    sudo ln -s /opt/quagga/lib/libcapn_c.so.1.0.0 /opt/quagga/lib/libcapn_c.so
    cd ..

#Checkout Compile and Install Quagga
    git clone https://github.com/6WIND/quagga.git
    cd quagga
    git checkout quagga_110_mpbgp_capnp
    export ZEROMQ_CFLAGS="-I"$BUILD_FOLDER"/zeromq4-1/include"
    export ZEROMQ_LIBS="-L"$BUILD_FOLDER"/zeromq4-1/.libs/ -lzmq"
    export CAPN_C_CFLAGS='-I'$BUILD_FOLDER'/c-capnproto/ -I'$BUILD_FOLDER'/'
    export CAPN_C_LIBS='-L'$BUILD_FOLDER'/c-capnproto/.libs/ -lcapn_c'
    autoreconf -i
    LIBS='-L'$BUILD_FOLDER'/zeromq4-1/.libs/ -L'$BUILD_FOLDER'/c-capnproto/.libs/' \
    ./configure --with-zeromq --with-ccapnproto --prefix=/opt/quagga --enable-user=quagga \
    --enable-group=quagga --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga \
    --disable-doc --enable-multipath=64
    make
    sudo make install
    sudo cp /opt/quagga/etc/bgpd.conf.sample4 /opt/quagga/etc/bgpd.conf
    sudo mkdir /opt/quagga/var/run/quagga -p
    sudo mkdir /opt/quagga/var/log/quagga -p
    sudo touch /opt/quagga/var/log/quagga/zrpcd.init.log
    sudo groupadd  quagga
    sudo adduser --system --gid quagga --home-dir /opt/quagga/var/run/quagga --comment "Quagga-BGP routing suite" --shell /bin/false quagga

    sudo chown -R quagga:quagga /opt/quagga/var/run/quagga
    sudo chown -R quagga:quagga /opt/quagga/var/log/quagga
    cd ..

#Checkout Compile and Install ZRPC.
#in addition to above flags, ensure to add below flags
    export QUAGGA_CFLAGS='-I'$BUILD_FOLDER'/quagga/lib/'
    export QUAGGA_LIBS='-L'$BUILD_FOLDER'/quagga/lib/.libs/. -lzebra'
    export THRIFT_CFLAGS="-I"$BUILD_FOLDER"/thrift/lib/c_glib/src/thrift/c_glib/ -I"$BUILD_FOLDER"/thrift/lib/c_glib/src"
    export THRIFT_LIBS="-L'$BUILD_FOLDER'/thrift/lib/c_glib/.libs/ -lthrift_c_glib"

    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd
    touch NEWS README
    autoreconf -i
    LIBS='-L'$BUILD_FOLDER'/zeromq4-1/.libs/ -L'$BUILD_FOLDER'/c-capnproto/.libs/ -L'$BUILD_FOLDER'/quagga/lib/.libs/'\
	./configure --enable-zrpcd --prefix=/opt/quagga --enable-user=quagga --enable-group=quagga\
    --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga
    make
    sudo make install
    sudo mkdir /opt/quagga/etc/init.d -p
    sudo cp pkgsrc/zrpcd.ubuntu /opt/quagga/etc/init.d/zrpcd
    sudo chmod +x /opt/quagga/etc/init.d/zrpcd

    sudo echo "hostname bgpd" >> /opt/quagga/etc/bgpd.conf
    sudo echo "password sdncbgpc" >> /opt/quagga/etc/bgpd.conf
    sudo echo "service advanced-vty" >> /opt/quagga/etc/bgpd.conf
    sudo echo "log stdout" >> /opt/quagga/etc/bgpd.conf
    sudo echo "line vty" >> /opt/quagga/etc/bgpd.conf
    sudo echo " exec-timeout 0 0 " >> /opt/quagga/etc/bgpd.conf
    sudo echo "debug bgp " >> /opt/quagga/etc/bgpd.conf
    sudo echo "debug bgp updates" >> /opt/quagga/etc/bgpd.conf
    sudo echo "debug bgp events" >> /opt/quagga/etc/bgpd.conf
    sudo echo "debug bgp fsm" >> /opt/quagga/etc/bgpd.conf
