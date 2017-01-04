#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF
#!/bin/bash

echo '---> Download compile and install the 6Wind Quagga'
#Install the required softwares for building quagga
    yum -y group install "Development Tools"
    yum -y install readline-devel
    yum -y install glib2-devel

#Create Build directory
    cd /tmp

#Clean the directory if exists
    rm -rf c-capnproto thrift zeromq4-1 quagga zrpcd

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
    make install
    cd ..

#Checkout Compile and Install ZeroMQ
    git clone https://github.com/zeromq/zeromq4-1.git
    cd zeromq4-1
    git checkout 56b71af22db3
    autoreconf -i
    ./configure --without-libsodium --prefix=/opt/quagga
    make
     make install
    cd ..

#Checkout Compile and Install C-capnproto
    git clone https://github.com/opensourcerouting/c-capnproto
    cd c-capnproto
    git checkout 332076e52257
    autoreconf -i
    ./configure --prefix=/opt/quagga --without-gtest
    make
    mkdir /opt/quagga/lib -p
    mkdir /opt/quagga/include/c-capnproto -p

    cp  capn.h /opt/quagga/include/c-capnproto/.
    cp .libs/libcapn.so.1.0.0 .libs/libcapn_c.so.1.0.0
    ln -s /tmp/c-capnproto/.libs/libcapn_c.so.1.0.0 /tmp/c-capnproto/.libs/libcapn_c.so
    cp .libs/libcapn.so.1.0.0 /opt/quagga/lib/libcapn_c.so.1.0.0
    ln -s /opt/quagga/lib/libcapn_c.so.1.0.0 /opt/quagga/lib/libcapn_c.so
    cd ..

#Checkout Compile and Install Quagga
    git clone https://github.com/6WIND/quagga.git
    cd quagga
    git checkout quagga_110_mpbgp_capnp
    export ZEROMQ_CFLAGS="-I/tmp/zeromq4-1/include"
    export ZEROMQ_LIBS="-L/tmp/zeromq4-1/.libs/ -lzmq"
    export CAPN_C_CFLAGS="-I/tmp/c-capnproto/ -I/tmp/"
    export CAPN_C_LIBS="-L/tmp/c-capnproto/.libs/ -lcapn_c"
    autoreconf -i
    LIBS='-L/tmp/zeromq4-1/.libs/ -L/tmp/c-capnproto/.libs/' \
    ./configure --with-zeromq --with-ccapnproto --prefix=/opt/quagga --enable-user=quagga \
    --enable-group=quagga --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga \
    --disable-doc --enable-multipath=64
    make
    make install
    cp /opt/quagga/etc/bgpd.conf.sample4 /opt/quagga/etc/bgpd.conf
    mkdir /opt/quagga/var/run/quagga -p
    mkdir /opt/quagga/var/log/quagga -p
    touch /opt/quagga/var/log/quagga/zrpcd.init.log
    groupadd  quagga
    adduser --system --gid quagga --home-dir /opt/quagga/var/run/quagga --comment "Quagga-BGP routing suite" --shell /bin/false quagga

    chown -R quagga:quagga /opt/quagga/var/run/quagga
    chown -R quagga:quagga /opt/quagga/var/log/quagga
    cd ..

#Checkout Compile and Install ZRPC.
#in addition to above flags, ensure to add below flags
    export QUAGGA_CFLAGS='-I/tmp/quagga/lib/'
    export QUAGGA_LIBS='-L/tmp/quagga/lib/.libs/. -lzebra'
    export THRIFT_CFLAGS="-I/tmp/thrift/lib/c_glib/src/thrift/c_glib/ -I/tmp/thrift/lib/c_glib/src"
    export THRIFT_LIBS="-L/tmp/thrift/lib/c_glib/.libs/ -lthrift_c_glib"

    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd
    touch NEWS README
    autoreconf -i
    LIBS='-L/tmp/zeromq4-1/.libs/ -L/tmp/c-capnproto/.libs/ -L/tmp/quagga/lib/.libs/'\
    ./configure --enable-zrpcd --prefix=/opt/quagga --enable-user=quagga --enable-group=quagga\
    --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga
    make
    make install
    mkdir /opt/quagga/etc/init.d -p
    cp pkgsrc/zrpcd.ubuntu /opt/quagga/etc/init.d/zrpcd
    chmod +x /opt/quagga/etc/init.d/zrpcd

    echo "hostname bgpd" >> /opt/quagga/etc/bgpd.conf
    echo "password sdncbgpc" >> /opt/quagga/etc/bgpd.conf
    echo "service advanced-vty" >> /opt/quagga/etc/bgpd.conf
    echo "log stdout" >> /opt/quagga/etc/bgpd.conf
    echo "line vty" >> /opt/quagga/etc/bgpd.conf
    echo " exec-timeout 0 0 " >> /opt/quagga/etc/bgpd.conf
    echo "debug bgp " >> /opt/quagga/etc/bgpd.conf
    echo "debug bgp updates" >> /opt/quagga/etc/bgpd.conf
    echo "debug bgp events" >> /opt/quagga/etc/bgpd.conf
    echo "debug bgp fsm" >> /opt/quagga/etc/bgpd.conf
EOF

echo "Execute 6wind Quagga install procedure in all the ODL VMs"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done
