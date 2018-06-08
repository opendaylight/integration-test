#!/bin/bash

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Set OpenFlow TLS on ${!CONTROLLERIP}"
        ssh ${!CONTROLLERIP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/"
        scp ${WORKSPACE}/test/csit/libraries/tls/default-openflow-connection-config.xml ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
        scp ${WORKSPACE}/test/csit/libraries/tls/keystore.p12 ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc
        scp ${WORKSPACE}/test/csit/libraries/tls/truststore.p12 ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc
done
