#!/bin/bash

set -o xtrace
#: <<'END'

# bootstrap_fedora 
WORK_DIR=`pwd`
APT="sudo yum install -y git vim autoconf automake libtool systemd-units rpm-build openssl openssl-devel groff graphviz selinux-policy-devel python python-twisted-core python-zope-interface python-twisted-web PyQt4 python-six desktop-file-utils procps-ng"
if $APT; then 
  echo "Pacakges installed correctly"
else
  echo "Installation of pacakges failed"
  exit 1
fi

cd $WORK_DIR
[ -e configure-ovs.sh ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/configure-ovs.sh
chmod a+x configure-ovs.sh
[ -e supervisord.conf ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/supervisord.conf

git clone https://github.com/yyang13/ovs_nsh_patches.git
git clone https://github.com/openvswitch/ovs.git
cd ovs
git reset --hard 7d433ae57ebb90cd68e8fa948a096f619ac4e2d8
cp ../ovs_nsh_patches/*.patch ./
git apply *.patch

#compile ovs
./boot.sh
./configure --with-linux=/lib/modules/`uname -r`/build --prefix=/usr/local
make rpm-fedora RPMBUILD_OPT="--without check"
make DESTDIR=$WORK_DIR/ovs_install/openvswitch_2.5.90-1 install

#copy rpms and installation
mkdir -p $WORK_DIR/ovs_package
find . -name "*.rpm"|xargs -I[] cp [] $WORK_DIR/ovs_package
tar cvzf $WORK_DIR/ovs_package/openvswitch_2.5.90-1.tgz -C $WORK_DIR/ovs_install . 

#END
#WORK_DIR=`pwd`
#cd $WORK_DIR/ovs_package
#Remove until the END!!!!!

# install_ovs
cd $WORK_DIR/ovs_package
sudo yum --nogpgcheck -y install `find . -regex "\./openvswitch-[0-9,.,-].*"`

#start ovs
sudo /sbin/service openvswitch start

# build_ovs_docker 
cd $WORK_DIR
if [ -z `sudo docker images | awk '/^ovs-docker / {print $1}'` ];  
 then
   sudo docker build -t ovs-docker .
fi



