#!/bin/bash

echo "Add single shard config file"
cat > ${WORKSPACE}/custom_shard_config.txt <<EOF
FRIENDLY_MODULE_NAMES[1]='toaster'
MODULE_NAMESPACES[1]='http://netconfcentral.org/ns/toaster'
EOF

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    CONTROLLERLIST+=" ${!CONTROLLERIP}"
done

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copy shard config to member-${i} with IP address ${!CONTROLLERIP}"
    scp ${WORKSPACE}/custom_shard_config.txt ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/bin
    ssh ${!CONTROLLERIP} "bash /tmp/${BUNDLEFOLDER}/bin/cluster_configure.sh $i $CONTROLLERLIST"
done
