#!/bin/bash


cat > ${WORKSPACE}/set_sg_mode.sh <<EOF

    ls -altr /tmp/${BUNDLEFOLDER}
    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    ls -altr /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    find /tmp/${BUNDLEFOLDER} -name "*aclservice*config.xml"
    cp \$(find /tmp/${BUNDLEFOLDER} -name "*aclservice*config.xml") /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    sed -i s/stateful/${SECURITY_GROUP_MODE}/ /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_sg_mode.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_sg_mode.sh'

done
