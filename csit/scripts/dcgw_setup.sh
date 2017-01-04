#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF
echo "6wind Quagga install procedure "

EOF

echo "Execute 6wind Quagga install procedure in all the ODL VMs"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/dcgw_setup.sh'
done
