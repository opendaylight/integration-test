set -o xtrace

# bootstrap_ubuntu 
WORK_DIR=`pwd`
sudo apt-get update
APT="sudo apt-get install --no-install-recommends -y"
$APT git dkms vim python-six
cd $WORK_DIR
[ -e configure-ovs.sh ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/configure-ovs.sh
chmod a+x configure-ovs.sh
[ -e supervisord.conf ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/supervisord.conf

# $build_ovs 
if [ -e $WORK_DIR/ovs_package/openvswitch-datapath-dkms_2.5.90-1_all.deb ] && \
    [ -e $WORK_DIR/ovs_package/openvswitch-common_2.5.90-1_amd64.deb ] && \
    [ -e $WORK_DIR/ovs_package/openvswitch-switch_2.5.90-1_amd64.deb ] && \
    [ -e $WORK_DIR/ovs_package/openvswitch_2.5.90-1.tgz ]
 then : 
 else
   
  APT="sudo apt-get install --no-install-recommends -y"
  $APT build-essential fakeroot devscripts equivs linux-headers-generic 
  git clone https://github.com/yyang13/ovs_nsh_patches.git
  git clone https://github.com/openvswitch/ovs.git
  cd ovs
  git reset --hard 7d433ae57ebb90cd68e8fa948a096f619ac4e2d8
  cp ../ovs_nsh_patches/*.patch ./
  git apply *.patch
  mk-build-deps -i -t 'apt-get --no-install-recommends -y'
  ./boot.sh
  ./configure --with-linux=/lib/modules/`uname -r`/build --prefix=/usr/local
  make
  make DESTDIR=$WORK_DIR/ovs_install/openvswitch_2.5.90-1 install
  DEB_BUILD_OPTIONS='nocheck' fakeroot debian/rules binary
  mkdir -p $WORK_DIR/ovs_package
  tar cvzf $WORK_DIR/ovs_package/openvswitch_2.5.90-1.tgz -C $WORK_DIR/ovs_install . 
  cp ../*.deb $WORK_DIR/ovs_package/

fi


# install_ovs
cd $WORK_DIR/ovs_package
sudo dpkg -EG -i openvswitch-datapath-dkms_2.5.90-1_all.deb \
   openvswitch-common_2.5.90-1_amd64.deb openvswitch-switch_2.5.90-1_amd64.deb


# build_ovs_docker 
cd $WORK_DIR
[ -z `docker images | awk '/^ovs-docker / {print $1}'` ] && \ 
   sudo docker build -t ovs-docker .
exit 0



