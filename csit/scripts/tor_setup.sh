#!/bin/bash

cat > ${WORKSPACE}/tor_setup.sh <<EOF

echo "TOR software install procedure"
add-apt-repository -y ppa:sgauthier/openvswitch-dpdk
apt-get update -y --force-yes
apt-get install -y --force-yes openvswitch-switch
apt-get install -y --force-yes openvswitch-vtep
ovs-vswitchd --version

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/tor_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo /tmp/tor_setup.sh'
done
