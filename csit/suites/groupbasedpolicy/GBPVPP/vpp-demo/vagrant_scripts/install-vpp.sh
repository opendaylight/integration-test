#! /bin/bash

#install vpp
echo "Installing VPP..."
sudo apt-get update --allow-unauthenticated
sudo apt-get -y -f install --allow-unauthenticated
sysctl -w vm.nr_hugepages=1024
HUGEPAGES=`sysctl -n  vm.nr_hugepages`
if [ $HUGEPAGES != 1024 ]; then
    echo "!!!!!!!!!!!!ERROR: Unable to get 1024 hugepages, only got $HUGEPAGES.  Cannot finish!!!!!!!!!!!!"
    exit
fi
sudo apt-get install -y --allow-unauthenticated vpp-lib vpp vpp-dev vpp-dpdk-dkms
echo "Installing VPP done."
#sudo service vpp start