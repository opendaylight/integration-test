#!/bin/bash

WORK_DIR=`pwd`

function bootstrap {
    ## TEMPORAL SOLUTION KERNEL PROBLEMS >>>
    ##??? yum install -y kernel-devel kernel-debug-devel
    curl -O http://dev.centos.org/c7.1511.u/kernel/20161024152721/3.10.0-327.36.3.el7.x86_64/kernel-devel-3.10.0-327.36.3.el7.x86_64.rpm
    rpm -Uvh kernel-devel-3.10.0-327.36.3.el7.x86_64.rpm
    curl -O http://dev.centos.org/c7.1511.u/kernel/20161024152721/3.10.0-327.36.3.el7.x86_64/kernel-debug-devel-3.10.0-327.36.3.el7.x86_64.rpm
    rpm -Uvh kernel-debug-devel-3.10.0-327.36.3.el7.x86_64.rpm
    ##??? yum -y update
    ## TEMPORAL SOLUTION KERNEL PROBLEMS <<<
    rpm -Uvh http://epel.mirror.net.in/epel/7/x86_64/e/epel-release-7-8.noarch.rpm
    yum -y install git dkms vim python-six python-pip bridge-utils
    yum -y install python34 tcpdump
    pip install --upgrade pip
    cd ${WORK_DIR}/dovs
    pip install .
}

function build_ovs {
    [ -e ${WORK_DIR}/ovs_package/openvswitch-2.5.90-1.el7.centos.x86_64.rpm ] && return 0

    yum install -y python-twisted-core gcc make python-devel openssl-devel  \
       graphviz autoconf automake rpm-build \
       redhat-rpm-config libtool python-zope-interface PyQt4                \
       desktop-file-utils groff selinux-policy-devel net-tools

    cd ${WORK_DIR}
    git clone https://github.com/yyang13/ovs_nsh_patches.git
    pushd ovs_nsh_patches && git reset --hard HEAD && popd
    git clone https://github.com/openvswitch/ovs.git
    cd ovs
    git reset --hard 7d433ae57ebb90cd68e8fa948a096f619ac4e2d8
    cp ../ovs_nsh_patches/*.patch ./
    git apply *.patch
    ./boot.sh
    ./configure --disable-shared
    make
    make dist
    make DESTDIR=${WORK_DIR}/ovs_install/openvswitch-2.5.90 install
    cd .. && tar xvzf ovs/openvswitch-2.5.90.tar.gz
    mkdir -p ~/rpmbuild/SOURCES/
    cp ovs/openvswitch-2.5.90.tar.gz cp ~/rpmbuild/SOURCES/
    cd openvswitch-2.5.90
    rpmbuild -bb --without check --without libcapng rhel/openvswitch-fedora.spec
    ## TEMPORAL SOLUTION KERNEL PROBLEMS >>>
    rpmbuild -bb --without check -D "kversion $(uname -r)" rhel/openvswitch-kmod-fedora.spec
    ##??? kernel_version=`sudo yum list kernel-devel | grep kernel-devel | awk '{print $2".x86_64"}'`
    ##??? rpmbuild -bb --without check -D "kversion ${kernel_version}" rhel/openvswitch-kmod-fedora.spec
    ## TEMPORAL SOLUTION KERNEL PROBLEMS <<<
    mkdir -p ${WORK_DIR}/ovs_package
    cp ~/rpmbuild/RPMS/x86_64/openvswitch*.rpm ${WORK_DIR}/ovs_package/
    tar cvzf ${WORK_DIR}/ovs_package/openvswitch-2.5.90.tar.gz -C ${WORK_DIR}/ovs_install .
}

function install_ovs {
    rpm -ivh --nodeps ${WORK_DIR}/ovs_package/openvswitch*.rpm
    yum localinstall ${WORK_DIR}/ovs_package/openvswitch-kmod-2.5.90-1.el7.centos.x86_64.rpm -y
    yum localinstall ${WORK_DIR}/ovs_package/openvswitch-2.5.90-1.el7.centos.x86_64.rpm -y
    systemctl enable openvswitch
    systemctl start openvswitch
}

function build_ovs_docker {
    [ ! -z `docker images | awk '/^docker-ovs:yy / {print $1}'` ] && \
       return 0
    cd ${WORK_DIR}
    git clone https://github.com/socketplane/docker-ovs.git
    cd docker-ovs
    git reset --hard fede8851e05b984e6f850752d5bc604ac4d7a71c
    cp ../docker-ovs.patches/*.patch .
    cp ${WORK_DIR}/ovs_package/openvswitch-2.5.90.tar.gz .
    mkdir host_libs
    cp /usr/lib64/libcrypto.so.10 host_libs/
    cp /usr/lib64/libssl.so.10 host_libs/
    cp /usr/lib64/libgssapi_krb5.so.2 host_libs/
    cp /usr/lib64/libkrb5.so.3 host_libs/
    cp /usr/lib64/libcom_err.so.2 host_libs/
    cp /usr/lib64/libk5crypto.so.3 host_libs/
    cp /usr/lib64/libkrb5support.so.0 host_libs/
    cp /usr/lib64/libkeyutils.so.1 host_libs/
    cp /usr/lib64/libselinux.so.1 host_libs/
    cp /usr/lib64/libpcre.so.1 host_libs/
    cp /usr/lib64/liblzma.so.5 host_libs/
    git apply *.patch || return 1
    docker build -t docker-ovs:yyang .
    return 0
}

function configure_dovs_bridge {
    BRIDGE="dovsbr0"
    BRIDGE_CFG="/etc/sysconfig/network-scripts/ifcfg-${BRIDGE}"
    ETH="eth1"
    ETH_CFG="/etc/sysconfig/network-scripts/ifcfg-${ETH}"
    [ ! -e "$BRIDGE_CFG" ] || return 0
    echo "DEVICE=${BRIDGE}" > "$BRIDGE_CFG"
    echo "TYPE=Bridge" >> "$BRIDGE_CFG"
    echo "BOOTPROTO=dhcp" >> "$BRIDGE_CFG"
    echo "ONBOOT=yes" >> "$BRIDGE_CFG"
    echo "PERSISTENT_DHCLIENT=yes" >> "$BRIDGE_CFG"
    mv "$ETH_CFG" "${ETH_CFG}.old"
    echo "DEVICE=${ETH}" > "$ETH_CFG"
    echo "ONBOOT=yes" >> "$ETH_CFG"
    echo "TYPE=Ethernet" >> "$ETH_CFG"
    echo "BRIDGE=${BRIDGE}" >> "$ETH_CFG"
    systemctl restart network
}

function configure_pipework {
    cd ${WORK_DIR}
    [ ! -e "/usr/local/sbin/pipework" ] || return 0
    git clone https://github.com/jpetazzo/pipework.git
    cd pipework
    git reset --hard HEAD
    cp ../pipework.patches/*.patch .
    git apply *.patch || return 1
    cp pipework /usr/local/sbin
}

bootstrap
build_ovs
install_ovs
build_ovs_docker
configure_dovs_bridge
configure_pipework
