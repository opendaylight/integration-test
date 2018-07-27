#!/bin/bash

set -o xtrace
set -o nounset #Do not allow for unset variables
set -e #Exit script if a command fails

function build_ovs() {
    OVS_VERSION=$1
    K_VERSION=$(uname -r)

    if [[ "${OVS_VERSION}" != "2.6.1" && "${OVS_VERSION}" != "2.9.2" ]]; then
        echo "Unsupported OVS version ${OVS_VERSION}"
        exit 1
    fi

    echo "Building OVS ${OVS_VERSION}"

    # install running kernel devel packages
    sudo yum -y install centos-release yum-utils @'Development Tools' rpm-build
    REPO=$(repoquery --enablerepo=C* -i kernel-devel-${K_VERSION} | grep Repository | sed 's/Repo.*:[ \t]*//')
    sudo yum -y --enablerepo=${REPO} install kernel-{devel,debug-devel,headers}-${K_VERSION}

    TMP=$(mktemp -d)
    pushd ${TMP}

    git clone https://github.com/openvswitch/ovs.git
    cd ovs
    git checkout v${OVS_VERSION}

    if [[ "${OVS_VERSION}" == "2.6.1" ]]; then
        echo "Will apply nsh patches for OVS version 2.6.1"
        git clone https://github.com/yyang13/ovs_nsh_patches.git ../ovs_nsh_patches
        git apply ../ovs_nsh_patches/v2.6.1_centos7/*.patch
    fi

    sed -e 's/@VERSION@/0.0.1/' rhel/openvswitch-fedora.spec.in > /tmp/ovs.spec
    sudo yum-builddep -y /tmp/ovs.spec
    rm /tmp/ovs.spec
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-linux=/lib/modules/${K_VERSION}/build
    make rpm-fedora RPMBUILD_OPT="--without check"
    # we dont need the kernel module (yet)
    # make rpm-fedora-kmod RPMBUILD_OPT="-D 'kversion ${K_VERSION}'"
    make DESTDIR=${TMP}/ovs_install/openvswitch_${OVS_VERSION} install

    popd

    # copy rpms and installation
    mkdir -p ovs_package
    find ${TMP}/ovs/rpm/rpmbuild/RPMS -name "*.rpm" | xargs -i cp {} ovs_package/
    tar cvzf ovs_package/openvswitch_${OVS_VERSION}.tgz -C ${TMP}/ovs_install .

    rm -rf ${TMP}
}

ODL_STREAM=$1

# build ovs
[ "${ODL_STREAM}" == "oxygen" ] && build_ovs 2.6.1 || build_ovs 2.9.2
wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/configure-ovs.sh
wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/supervisord.conf
wget https://pypi.python.org/packages/source/s/supervisor-stdout/supervisor-stdout-0.1.1.tar.gz --no-check-certificate

# install ovs
sudo yum -y install ovs_package/*.rpm
sudo systemctl enable openvswitch
sudo systemctl start openvswitch
sudo ovs-vsctl show

# prepare libraries for docker image in busybox
cp /usr/lib64/libcrypto.so.10 .
cp /usr/lib64/libssl.so.10 .
cp /usr/lib64/libgssapi_krb5.so.2 .
cp /usr/lib64/libkrb5.so.3 .
cp /usr/lib64/libcom_err.so.2 .
cp /usr/lib64/libk5crypto.so.3 .
cp /usr/lib64/libkrb5support.so.0 .
cp /usr/lib64/libkeyutils.so.1 .
cp /usr/lib64/libselinux.so.1 .
cp /usr/lib64/libpcre.so.1 .
cp /usr/lib64/liblzma.so.5 .

# build_ovs_docker
sudo docker build -t ovs-docker .

