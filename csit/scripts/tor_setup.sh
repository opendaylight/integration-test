#!/bin/bash

cat > ${WORKSPACE}/tor_setup.sh <<EOF
echo "TOR software install procedure"
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

