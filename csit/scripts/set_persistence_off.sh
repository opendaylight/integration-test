#!/bin/bash

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Disable persistence in member-${i} with IP address ${!CONTROLLERIP}"
    ssh ${!CONTROLLERIP} "bash /tmp/${BUNDLEFOLDER}/bin/set_persistence.sh off"
done
