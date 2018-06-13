#!/bin/bash

cat > ${WORKSPACE}/set_single_shard.sh <<EOF

    cp /tmp/modules.conf /tmp/${BUNDLEFOLDER}/configuration/initial/modules.conf
    cp /tmp/module-shards.conf /tmp/${BUNDLEFOLDER}/configuration/initial/module-shards.conf
    cat /tmp/${BUNDLEFOLDER}/configuration/initial/modules.conf
    echo ******************
    cat /tmp/${BUNDLEFOLDER}/configuration/initial/modules-shard.conf

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting Single Shard Config on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/test/csit/libraries/netvirt/modules.conf ${!CONTROLLERIP}:/tmp/
        scp ${WORKSPACE}/test/csit/libraries/netvirt/module-shards.conf ${!CONTROLLERIP}:/tmp/
        scp ${WORKSPACE}/set_single_shard.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash -x /tmp/set_single_shard.sh'

done
