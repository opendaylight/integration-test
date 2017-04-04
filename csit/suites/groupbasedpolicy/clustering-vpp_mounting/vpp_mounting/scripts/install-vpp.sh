#! /bin/bash

#install vpp
echo "Installing VPP..."
sysctl -w vm.nr_hugepages=1024
HUGEPAGES=`sysctl -n  vm.nr_hugepages`
if [ $HUGEPAGES != 1024 ]; then
    echo "!!!!!!!!!!!!ERROR: Unable to get 1024 hugepages, only got $HUGEPAGES.  Cannot finish!!!!!!!!!!!!"
    exit
fi
sudo yum -y --nogpgcheck install vpp-lib vpp vpp-devel vpp-plugins
echo "Installing VPP done."