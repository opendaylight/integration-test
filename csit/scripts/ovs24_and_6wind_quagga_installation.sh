#!/bin/bash


cat > ${WORKSPACE}/ovs24_and_6wind_quagga_installation.sh <<EOF

echo "Hello ovs24_and_6wind_quagga_installation.sh"

# vim: sw=4 ts=4 sts=4 et tw=72 :

# Ensure that necessary variables are set to enable noninteractive mode in
# commands.
export DEBIAN_FRONTEND=noninteractive

# To handle the prompt style that is expected all over the environment
# with how use use robotframework we need to make sure that it is
# consistent for any of the users that are created during dynamic spin
# ups
sudo echo 'PS1="[\u@\h \W]> "' >> /etc/skel/.bashrc

mkdir apt
cd apt
wget -c http://archive.ubuntu.com/ubuntu/pool/main/a/apt/apt_0.8.16~exp12ubuntu10.21_amd64.deb
chmod 777 apt_0.8.16~exp12ubuntu10.21_amd64.deb
sudo dpkg -i apt_0.8.16~exp12ubuntu10.21_amd64.deb
cd ..


echo '---> Install OpenVSwitch 2.4.0'
wget -c http://openvswitch.org/releases/openvswitch-2.4.0.tar.gz
tar -zxvf openvswitch-2.4.0.tar.gz
cd openvswitch-2.4.0
./configure --prefix=/usr --with-linux=/lib/modules/`uname -r`/build
make -j4
sudo make install
sudo make modules_install
sudo rmmod openvswitch
sudo depmod -a
sudo ovs-vswitchd --version
cd ..

#echo '---> Installing mininet 2.2.2'
#git clone git://github.com/mininet/mininet
#cd mininet
#git checkout -b 2.2.2 2.2.2
#cd ..
#sudo mininet/util/install.sh -nf

#echo '---> Installing MT-Cbench'
#sudo apt-get install -y --force-yes build-essential snmp libsnmp-dev snmpd libpcap-dev \
#autoconf make automake libtool libconfig-dev libssl-dev libffi-dev libssl-doc pkg-config
#git clone https://github.com/intracom-telecom-sdn/mtcbench.git
#mtcbench/build_mtcbench.sh
#sudo cp mtcbench/oflops/cbench/cbench /usr/local/bin/

#echo '---> Installing exabgp'
#sudo apt-get install -y --force-yes exabgp

echo '---> All Python package installation should happen in virtualenv'
#sudo apt-get install -y --force-yes python-virtualenv python-pip

echo '---> Install OVS 2.4 Python module'
wget -c https://pypi.python.org/packages/2f/8a/358cad389613865ee255c7540f9ea2c2f98376c2d9cd723f5cf30390d928/ovs-2.4.0.tar.gz#md5=9097ced87a88e67fbc3d4b92c16e6b71
tar -zxvf ovs-2.4.0.tar.gz
cd ovs-2.4.0
sudo mkdir -p /var/run/openvswitch/
sudo python setup.py install
cd ..

echo '---> Download compile and install the 6wind Quagga'
#Install the required softwares for building quagga
    sudo apt-get install automake bison flex g++ git libboost1.55-all-dev libevent-dev\
    libssl-dev libtool make pkg-config gawk -y --force-yes  -qq

#Create Build directory
    export CURRENT_FOLDER=`pwd`
    export BUILD_FOLDER="${CURRENT_FOLDER}/6wind_quagga_build_dir"
    rm -rf ${BUILD_FOLDER}
    mkdir -p ${BUILD_FOLDER}
    cd ${BUILD_FOLDER}

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

    sudo cp capn.h /opt/quagga/include/c-capnproto/.
    cp .libs/libcapn.so.1.0.0 .libs/libcapn_c.so.1.0.0
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
    sudo addgroup --system quagga
    sudo addgroup --system quagga
    sudo adduser --system --ingroup quagga --home /opt/quagga/var/run/quagga \
             --gecos "Quagga-BGP routing suite" \
             --shell /bin/false quagga  >/dev/null
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

EOF

echo "Installing OVS 2.4 and 6wind Quagga"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/ovs24_and_6wind_quagga_installation.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/ovs24_and_6wind_quagga_installation.sh'

done
