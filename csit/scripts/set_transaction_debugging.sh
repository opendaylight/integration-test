#!/bin/bash


cat > ${WORKSPACE}/set_sg_mode.sh <<EOF

    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*cluster.datastore.cfg"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg
    echo "transaction-debug-context-enabled=true" >> /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.controller.cluster.datastore.cfg

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_sg_mode.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_sg_mode.sh'

done
