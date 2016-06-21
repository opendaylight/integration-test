set -o xtrace

# bootstrap_fedora 
WORK_DIR=`pwd`
APT="sudo yum install -y"
$APT git dkms vim python-six autoconf automake libtool rpm-build openssl-devel python-twisted-core python-zope-interface PyQt4 groff graphviz selinux-policy-devel libcap-ng-devel python-twisted-web fakeroot devscripts
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
./configure
make rpm-fedora RPMBUILD_OPT="--without check"

#copy rpms
mkdir -p $WORK_DIR/ovs_package
find . -name "*.rpm"|xargs -I[] cp [] $WORK_DIR/ovs_package

# install_ovs
cd $WORK_DIR/ovs_package
find|xargs -I[] sudo rpm -i []

#start ovs
sudo /sbin/service openvswitch start

# build_ovs_docker 
cd $WORK_DIR
if [ -z `sudo docker images | awk '/^ovs-docker / {print $1}'` ];  
 then
   sudo docker build -t ovs-docker .
fi



