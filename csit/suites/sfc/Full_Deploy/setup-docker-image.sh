#!/bin/bash

set -o xtrace
set -o nounset #Do not allow for unset variables
#set -e #Exit script if a command fails

# bootstrap_centos
WORK_DIR=`pwd`
if sudo yum install -y "kernel-devel-uname-r == $(uname -r)"; then
   echo "Kernel-devel installed correctly"
else
   echo "Warning: Errors issued when installing kernel-devel"
fi

APT="sudo yum install -y git kernel-debug-devel kernel-headers python-devel vim autoconf automake libtool systemd-units rpm-build openssl openssl-devel groff graphviz selinux-policy-devel python python-twisted-core python-zope-interface python-twisted-web PyQt4 python-six desktop-file-utils procps-ng wget"
if $APT; then
  echo "Pacakges installed correctly"
else
  echo "Installation of packages failed"
  exit 1
fi

cd $WORK_DIR
[ -e configure-ovs.sh ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/configure-ovs.sh
chmod a+x configure-ovs.sh
[ -e supervisord.conf ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/supervisord.conf

[ -e supervisor-stdout/supervisor-stdout-0.1.1.tar.gz ] || \
   wget https://pypi.python.org/packages/source/s/supervisor-stdout/supervisor-stdout-0.1.1.tar.gz --no-check-certificate

[ -e ovs_nsh_patches ] || \
   git clone https://github.com/yyang13/ovs_nsh_patches.git
[ -e ovs ] || \
   git clone https://github.com/openvswitch/ovs.git

cd ovs
git config user.email "yi.y.yang@intel.com"
git config user.name "Yi Yang"
git checkout -b v2.6.1 v2.6.1
git am ../ovs_nsh_patches/v2.6.1/*.patch

#compile ovs
./boot.sh
./configure --with-linux=/lib/modules/`uname -r`/build --prefix=/usr/local
make rpm-fedora RPMBUILD_OPT="--without check --without libcapng"
make DESTDIR=$WORK_DIR/ovs_install/openvswitch_2.6.1 install

#copy rpms and installation
mkdir -p $WORK_DIR/ovs_package
find . -name "*.rpm"|xargs -I[] cp [] $WORK_DIR/ovs_package
tar cvzf $WORK_DIR/ovs_package/openvswitch_2.6.1.tgz -C $WORK_DIR/ovs_install .

# install_ovs
cd $WORK_DIR/ovs_package
CMD='sudo yum list installed openvswitch'
if $CMD; then
  echo "openvswitch already installed"
else
  sudo yum --nogpgcheck -y install `find . -regex "\./openvswitch-[0-9,.,-].*"`
fi

#start ovs
sudo /sbin/service openvswitch start

#prepare libraries for docker image in busybox
cd $WORK_DIR
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
cd $WORK_DIR
sudo docker --version
if [ -z `sudo docker images | awk '/^ovs-docker / {print $1}'` ];
 then
   sudo docker build -t ovs-docker .
fi



