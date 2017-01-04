#!/bin/bash

cat > ${WORKSPACE}/tor_setup.sh <<EOF

echo "TOR software install procedure"
uname -a
wget -c http://launchpadlibrarian.net/134102626/apt_0.9.7.5ubuntu5.4_amd64.deb
sudo dpkg -i apt_0.9.7.5ubuntu5.4_amd64.deb 

sudo add-apt-repository -y ppa:sgauthier/openvswitch-dpdk
sudo apt-get update -y --force-yes
sudo apt-get install -y --force-yes openvswitch-switch
sudo apt-get install -y --force-yes openvswitch-vtep
sudo ovs-vswitchd --version

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/tor_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/tor_setup.sh'
done
