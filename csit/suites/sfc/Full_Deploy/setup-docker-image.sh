set -o xtrace

# bootstrap_fedora 
WORK_DIR=`pwd`
APT="sudo yum install -y"
$APT git dkms vim python-six dh-autoreconf.noarch rpm-build openssl-devel python-twisted-core python-zope-interface PyQt4 groff graphviz selinux-policy-devel libcap-ng-devel python-twisted-web fakeroot devscripts

cd $WORK_DIR
[ -e configure-ovs.sh ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/configure-ovs.sh
chmod a+x configure-ovs.sh
[ -e supervisord.conf ] || \
   wget https://raw.githubusercontent.com/socketplane/docker-ovs/master/supervisord.conf

# $build_ovs 
#if [ -e $WORK_DIR/ovs_package/openvswitch-datapath-dkms_2.5.90-1_all.deb ] && \
#    [ -e $WORK_DIR/ovs_package/openvswitch-common_2.5.90-1_amd64.deb ] && \
#    [ -e $WORK_DIR/ovs_package/openvswitch-switch_2.5.90-1_amd64.deb ] && \
#    [ -e $WORK_DIR/ovs_package/openvswitch_2.5.90-1.tgz ]
# then : 
# else
   
#  APT="sudo yum install -y"
#  $APT fakeroot devscripts 
git clone https://github.com/yyang13/ovs_nsh_patches.git
git clone https://github.com/openvswitch/ovs.git
cd ovs
git reset --hard 7d433ae57ebb90cd68e8fa948a096f619ac4e2d8
cp ../ovs_nsh_patches/*.patch ./
git apply *.patch
#  sudo mk-build-deps -i -t 'sudo yum -y'
./boot.sh
./configure
# --with-linux=/lib/modules/`uname -r`/build --prefix=/usr/local
#  make
#  make DESTDIR=$WORK_DIR/ovs_install/openvswitch_2.5.90-1 install
make rpm-fedora RPMBUILD_OPT="--without check"
#  DEB_BUILD_OPTIONS='nocheck' fakeroot debian/rules binary
mkdir -p $WORK_DIR/ovs_package
find . -name "*.rpm"|xargs -I[] cp [] $WORK_DIR/ovs_package
#  tar cvzf $WORK_DIR/ovs_package/openvswitch_2.5.90-1.tgz -C $WORK_DIR/ovs_install . 
#  cp ../*.deb $WORK_DIR/ovs_package/
#fi



# install_ovs
cd $WORK_DIR/ovs_package
find|sudo xargs -I[] rpm -i []

sudo /sbin/service openvswitch start


# build_ovs_docker 
cd $WORK_DIR
if [ -z `sudo docker images | awk '/^ovs-docker / {print $1}'` ];  
 then
   sudo docker build -t ovs-docker .
fi



