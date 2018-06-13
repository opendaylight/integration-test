#!/bin/bash

cat > ${WORKSPACE}/set_single_shard.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/bin
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "custom_shard_config.txt"\`
    if ! [ "\$CONFFILE" ]; then
        echo "No configuration file exists for custom_shard_config.txt - skipping Single Shard configuration"
        exit 0
    fi
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/bin/custom_shard_config.txt
    sed -i "/'inventory'/d" /tmp/${BUNDLEFOLDER}/bin/custom_shard_config.txt
    sed -i "/'topology'/d" /tmp/${BUNDLEFOLDER}/bin/custom_shard_config.txt
    cat /tmp/${BUNDLEFOLDER}/bin/custom_shard_config.txt

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting Single Shard Config on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_single_shard.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash -x /tmp/set_single_shard.sh'

done
