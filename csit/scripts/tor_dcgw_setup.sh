#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo "6wind Quagga install procedure "
/bin/ls /usr/bin/{apt*,dpkg*}

EOF

echo "Execute 6wind Quagga install procedure in all the ODL VMs"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/dcgw_setup.sh'

done


cat > ${WORKSPACE}/tor_setup.sh <<EOF

echo "TOR software nstall procedure "
add-apt-repository -y ppa:sgauthier/openvswitch-dpdk
apt-get update -y --force-yes
apt-get install -y --force-yes openvswitch-switch
apt-get install openvswitch-vtep

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/tor_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/tor_setup.sh'

done
