#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo "DC-Gateway install procedure"
#Create Build directory
    rm -rf /tmp/6wind_quagga_build_dir
    mkdir /tmp/6wind_quagga_build_dir
    cd /tmp/6wind_quagga_build_dir

#Clean the directory if exists
    rm -rf c-capnproto thrift zeromq4-1 quagga zrpcd

echo "Checkout the required opensources"
    git clone https://git-wip-us.apache.org/repos/asf/thrift.git

    git clone https://github.com/zeromq/zeromq4-1.git
    cd zeromq4-1
    git checkout 56b71af22db3
    cd ..

    git clone https://github.com/opensourcerouting/c-capnproto
    cd c-capnproto
    git checkout 332076e52257
    cd ..

    git clone https://github.com/6WIND/quagga.git
    cd quagga
    git checkout quagga_110_mpbgp_capnp
    cd ..

    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd

echo "Create the quagga group and quagga user"

    mkdir -p /opt/quagga/var/run/quagga
    mkdir -p /opt/quagga/etc/init.d/

    HOST_NAME=\`hostname\`
    case \$HOST_NAME in
    *java*)
        yum -y group install "Development Tools"
        yum -y install readline-devel
        yum -y install glib2-devel
        groupadd --system quagga
        adduser --system --gid quagga --home /opt/quagga/var/run/quagga \
                --comment  "Quagga-BGP routing suite" \
                --shell /bin/false quagga
         cp pkgsrc/zrpcd.centos /opt/quagga/etc/init.d/zrpcd
       ;;

    *devstack*)
        echo "6wind quagga is not supported on devstack"
      ;;

    *)
         apt-get install automake bison flex g++ git libboost1.55-all-dev libevent-dev\
                         libssl-dev libtool make pkg-config gawk -y --force-yes
         addgroup --system quagga
         adduser --system --ingroup quagga --home /opt/quagga/var/run/quagga \
             --gecos "Quagga-BGP routing suite" \
             --shell /bin/false quagga
       cp pkgsrc/zrpcd.ubuntu /opt/quagga/etc/init.d/zrpcd
       ;;
    esac

    cd ..
    cd /tmp/6wind_quagga_build_dir


#Checkout Compile and Install thrift
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
    tail -n 2 config.log
    cd ..


#Checkout Compile and Install ZeroMQ
    cd zeromq4-1
    autoreconf -i
    ./configure --without-libsodium --prefix=/opt/quagga
    make
    make install
    tail -n 2 config.log
    cd ..

#Checkout Compile and Install C-capnproto
    cd c-capnproto
    autoreconf -i
    ./configure --prefix=/opt/quagga --without-gtest
    make
    mkdir /opt/quagga/lib -p
    mkdir /opt/quagga/include/c-capnproto -p

    cp -f capn.h /opt/quagga/include/c-capnproto/.
    cp .libs/libcapn.so.1.0.0 .libs/libcapn_c.so.1.0.0
    ln -s /tmp/6wind_quagga_build_dir/c-capnproto/.libs/libcapn_c.so.1.0.0 /tmp/6wind_quagga_build_dir/c-capnproto/.libs/libcapn_c.so
    cp .libs/libcapn.so.1.0.0 /opt/quagga/lib/libcapn_c.so.1.0.0
    ln -s /opt/quagga/lib/libcapn_c.so.1.0.0 /opt/quagga/lib/libcapn_c.so
    tail -n 2 config.log
    cd ..

#Checkout Compile and Install Quagga
    cd quagga
    export ZEROMQ_CFLAGS="-I"/tmp/6wind_quagga_build_dir"/zeromq4-1/include"
    export ZEROMQ_LIBS="-L"/tmp/6wind_quagga_build_dir"/zeromq4-1/.libs/ -lzmq"
    export CAPN_C_CFLAGS='-I'/tmp/6wind_quagga_build_dir'/c-capnproto/ -I'/tmp/6wind_quagga_build_dir'/'
    export CAPN_C_LIBS='-L'/tmp/6wind_quagga_build_dir'/c-capnproto/.libs/ -lcapn_c'
    autoreconf -i
    LIBS='-L'/tmp/6wind_quagga_build_dir'/zeromq4-1/.libs/ -L'/tmp/6wind_quagga_build_dir'/c-capnproto/.libs/' \
    ./configure --with-zeromq --with-ccapnproto --prefix=/opt/quagga --enable-user=quagga \
    --enable-group=quagga --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga \
    --disable-doc --enable-multipath=64
    make
    make install
    cp /opt/quagga/etc/bgpd.conf.sample4 /opt/quagga/etc/bgpd.conf
    mkdir /opt/quagga/var/run/quagga -p
    mkdir /opt/quagga/var/log/quagga -p
    touch /opt/quagga/var/log/quagga/zrpcd.init.log
    chown -R quagga:quagga /opt/quagga/var/run/quagga
    chown -R quagga:quagga /opt/quagga/var/log/quagga
    tail -n 2 config.log
    cd ..

#Checkout Compile and Install ZRPC.
#in addition to above flags, ensure to add below flags
    export QUAGGA_CFLAGS='-I'/tmp/6wind_quagga_build_dir'/quagga/lib/'
    export QUAGGA_LIBS='-L'/tmp/6wind_quagga_build_dir'/quagga/lib/.libs/. -lzebra'
    export THRIFT_CFLAGS="-I"/tmp/6wind_quagga_build_dir"/thrift/lib/c_glib/src/thrift/c_glib/ -I"/tmp/6wind_quagga_build_dir"/thrift/lib/c_glib/src"
    export THRIFT_LIBS="-L'/tmp/6wind_quagga_build_dir'/thrift/lib/c_glib/.libs/ -lthrift_c_glib"

    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd
    touch NEWS README
    autoreconf -i
    LIBS='-L'/tmp/6wind_quagga_build_dir'/zeromq4-1/.libs/ -L'/tmp/6wind_quagga_build_dir'/c-capnproto/.libs/ -L'/tmp/6wind_quagga_build_dir'/quagga/lib/.libs/'\
        ./configure --enable-zrpcd --prefix=/opt/quagga --enable-user=quagga --enable-group=quagga\
    --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga
    make
    make install
    mkdir /opt/quagga/etc/init.d -p

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
    tail -n 2 config.log
    cd ..

EOF

echo "Execute the DC-Gateway install procedure on all the tools and ODL VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Copying the /tmp/dcgw_setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw_setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done
