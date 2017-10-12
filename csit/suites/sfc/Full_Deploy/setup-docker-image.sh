#!/bin/bash

set -o xtrace
set -o nounset #Do not allow for unset variables
#set -e #Exit script if a command fails

# bootstrap_centos
WORK_DIR=`pwd`

APT="sudo yum install -y python-devel python wget"
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

#download rpms and installation
mkdir -p $WORK_DIR/ovs_package
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B20dtomeEJsVR0dSUnVJbkp5SFk' -O ovs_package/openvswitch_2.6.1_el7_centos_rpms.tgz
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=0B20dtomeEJsVMWZOelp1dW5uMDA' -O ovs_package/openvswitch_2.6.1_el7_centos.tgz

# install_ovs
cd $WORK_DIR/ovs_package
CMD='sudo yum list installed openvswitch'
if $CMD; then
  echo "openvswitch already installed"
else
  tar xvzf openvswitch_2.6.1_el7_centos_rpms.tgz
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
if [ -z `sudo docker images | awk '/^ovs-docker / {print $1}'` ];
 then
   sudo docker build -t ovs-docker .
fi



