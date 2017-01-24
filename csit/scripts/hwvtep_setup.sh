#!/bin/bash

cat > ${WORKSPACE}/hwvtep_setup.sh <<EOF
echo "HWVTEP software install procedure"
echo '---> Install OpenVSwitch 2.5.0'
add-apt-repository -y ppa:sgauthier/openvswitch-dpdk
apt-get update -y --force-yes
apt-get install -y --force-yes openvswitch-switch openvswitch-vtep

echo '---> All Python package installation should happen in virtualenv'
apt-get install -y --force-yes python-virtualenv python-pip

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/hwvtep_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/hwvtep_setup.sh'
done
