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
    cd thrift
    git checkout 0.10.0
    wget https://issues.apache.org/jira/secure/attachment/12840511/0002-THRIFT-3986-using-autoreconf-i-fails-because-of-miss.patch
    wget https://issues.apache.org/jira/secure/attachment/12840512/0001-THRIFT-3987-externalise-declaration-of-thrift-server.patch
    git apply 0002-THRIFT-3986-using-autoreconf-i-fails-because-of-miss.patch
    git apply 0001-THRIFT-3987-externalise-declaration-of-thrift-server.patch
    cd ..

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
        yum -y install readline readline-devel glib2-devel autoconf* bison* \
               libevent-devel zlib-devel openssl-devel  boost*
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
         #apt-get build-dep automake bison flex g++ git libboost1.55-all-dev libevent-dev\
         #    libssl-dev libtool make pkg-config gawk libreadline-dev -y --force-yes 
         apt-get install automake bison flex g++ git libboost1.55-all-dev libevent-dev\
             libssl-dev libtool make pkg-config gawk libreadline-dev -y --force-yes

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
    echo "Thrift building started ......."
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
    echo "ZeroMQ building started ......."
    cd zeromq4-1
    autoreconf -i
    ./configure --without-libsodium --prefix=/opt/quagga
    make
    make install
    tail -n 2 config.log
    cd ..

#Checkout Compile and Install C-capnproto
    echo "C-capnproto building started ......."
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
    echo "Quagga building started ......."
    find / -name "*readline*"
    cd quagga
    export ZEROMQ_CFLAGS="-I/tmp/6wind_quagga_build_dir/zeromq4-1/include"
    export ZEROMQ_LIBS="-L/tmp/6wind_quagga_build_dir/zeromq4-1/.libs/ -lzmq"
    export CAPN_C_CFLAGS="-I/tmp/6wind_quagga_build_dir/c-capnproto/ -I/tmp/6wind_quagga_build_dir/"
    export CAPN_C_LIBS="-L/tmp/6wind_quagga_build_dir/c-capnproto/.libs/ -lcapn_c"
    autoreconf -i
    LIBS="-L/tmp/6wind_quagga_build_dir/zeromq4-1/.libs/ -L/tmp/6wind_quagga_build_dir/c-capnproto/.libs/" \
    ./configure --with-zeromq --with-ccapnproto --prefix=/opt/quagga --enable-user=quagga \
    --enable-group=quagga --enable-vty-group=quagga --localstatedir=/opt/quagga/var/run/quagga \
    --disable-doc --enable-multipath=64
    make
    make install
    #cp /opt/quagga/etc/bgpd.conf.sample4 /opt/quagga/etc/bgpd.conf 
    cp /tmp/6wind_quagga_build_dir/quagga/bgpd/bgpd.conf.sample4 /opt/quagga/etc/bgpd.conf 
    mkdir /opt/quagga/var/run/quagga -p
    mkdir /opt/quagga/var/log/quagga -p
    touch /opt/quagga/var/log/quagga/zrpcd.init.log
    chown -R quagga:quagga /opt/quagga/var/run/quagga
    chown -R quagga:quagga /opt/quagga/var/log/quagga
    tail -n 2 config.log
    cd ..

#Checkout Compile and Install ZRPC.
    echo "ZRPC building started ......."
#in addition to above flags, ensure to add below flags
    export QUAGGA_CFLAGS="-I/tmp/6wind_quagga_build_dir/quagga/lib/"
    export QUAGGA_LIBS="-L/tmp/6wind_quagga_build_dir/quagga/lib/.libs/. -lzebra"
    export THRIFT_CFLAGS="-I/tmp/6wind_quagga_build_dir/thrift/lib/c_glib/src/thrift/c_glib/ -I/tmp/6wind_quagga_build_dir/thrift/lib/c_glib/src"
    export THRIFT_LIBS="-L/tmp/6wind_quagga_build_dir/thrift/lib/c_glib/.libs/ -lthrift_c_glib"

    cd zrpcd
    touch NEWS README
    autoreconf -i
    LIBS="-L/tmp/6wind_quagga_build_dir/zeromq4-1/.libs/ -L/tmp/6wind_quagga_build_dir/c-capnproto/.libs/ \
          -L/tmp/6wind_quagga_build_dir/quagga/lib/.libs/" \
          ./configure --enable-zrpcd --prefix=/opt/quagga --enable-user=quagga --enable-group=quagga \
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

    echo "Quagga install status on \$HOST_NAME"
    for i in \`find . -name config.log\`
    do
     echo "The file name is \$i"
     tail -n 1  \$i
    done

EOF

echo "Execute the DC-Gateway install procedure on all the tools VMS"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Copying the /tmp/dcgw_setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done

echo "Execute the DC-Gateway install procedure on all the ODL VMS"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw_setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done

