#!/bin/bash

for ID in `seq 1 ${NUM_ODL_SYSTEM}`
do
    IP="ODL_SYSTEM_${ID}_IP"
    ssh ${!IP} "sudo yum install -y iputils net-tools"
    scp ${WORKSPACE}/test/csit/suites/sxp/scripts/arping ${!IP}:/tmp/arping
    ssh ${!IP} "sudo chmod +x /tmp/arping"
    ssh ${!IP} "sudo ln -s /tmp/arping /bin/arping"
    ssh ${!IP} "sudo ln -s /sbin/ifconfig /bin/ifconfig"
done

