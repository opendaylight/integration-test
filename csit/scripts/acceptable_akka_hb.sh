#!/bin/bash

AKKAHBPAUSE=10
AKKAFACTORY=/tmp/${BUNDLEFOLDER}/system/org/opendaylight/controller/sal-clustering-config/*/sal-clustering-config-*-factoryakkaconf.xml

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Set akka acceptable-heartbeat-pause"
    ssh ${!CONTROLLERIP} "sed -ie 's/failure-detector.acceptable-heartbeat-pause = .*/failure-detector.acceptable-heartbeat-pause = ${AKKAHBPAUSE} s/g' ${AKKAFACTORY}"
    ssh ${!CONTROLLERIP} "cat ${AKKAFACTORY}"
done
