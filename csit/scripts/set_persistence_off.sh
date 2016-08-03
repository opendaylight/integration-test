#!/bin/bash
echo "off" > persistence.txt

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copy persistence config to member-${i} with IP address ${!CONTROLLERIP}"
    scp ${WORKSPACE}/persistence.txt ${!CONTROLLERIP}:/tmp/
done
