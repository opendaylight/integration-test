#!/bin/bash

cat > ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg <<EOF
period=5000

EOF

echo "Copying config files to ODL Controller folder"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Setup long duration config to ${!CONTROLLERIP}"
        ssh ${!CONTROLLERIP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"
        scp ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
done
