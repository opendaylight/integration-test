#!/bin/bash

AKKAHBPAUSE=25
REMOTEAKKAHBPAUSE=32
GLOBFACTORY="/tmp/${BUNDLEFOLDER}/system/org/opendaylight/controller/sal-clustering-config/*/sal-clustering-config-*-factoryakkaconf.xml"
GLOBCONF="/tmp/${BUNDLEFOLDER}/system/org/opendaylight/controller/sal-clustering-config/*/sal-clustering-config-*-akkaconf.xml"
echo "The glob patterns have to be resolved on ODL system."
AKKAFACTORY=$(ssh ${ODL_SYSTEM_IP} readlink -e ${GLOBFACTORY})
AKKACONF=$(ssh ${ODL_SYSTEM_IP} readlink -e ${GLOBCONF})

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Set akka acceptable-heartbeat-pause"
    ssh ${!CONTROLLERIP} "sed -ie 's/failure-detector.acceptable-heartbeat-pause = 3 s/failure-detector.acceptable-heartbeat-pause = ${AKKAHBPAUSE}s/g' ${AKKAFACTORY}"
    ssh ${!CONTROLLERIP} "cat ${AKKAFACTORY}"
    echo "Set akka acceptable-heartbeat-pause"
    ssh ${!CONTROLLERIP} "sed -ie 's/# transport-failure-detector/transport-failure-detector/g' ${AKKACONF}"
    ssh ${!CONTROLLERIP} "sed -ie 's/# acceptable-heartbeat-pause = 16s/acceptable-heartbeat-pause = ${REMOTEAKKAHBPAUSE}s/g' ${AKKACONF}"
    ssh ${!CONTROLLERIP} "sed -ie 's/# }/}/g' ${AKKACONF}"
    ssh ${!CONTROLLERIP} "cat ${AKKACONF}"
done
