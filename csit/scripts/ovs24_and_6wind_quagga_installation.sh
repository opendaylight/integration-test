#!/bin/bash


cat > ${WORKSPACE}/ovs24_and_6wind_quagga_installation.sh <<EOF

echo "Hello ovs24_and_6wind_quagga_installation.sh"

/bin/ls /usr/bin/{apt*,dpkg*}

EOF

echo "Installing OVS 2.4 and 6wind Quagga"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/ovs24_and_6wind_quagga_installation.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/ovs24_and_6wind_quagga_installation.sh'

done
