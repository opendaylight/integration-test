#!/bin/bash

ODL_DEF_TZ_ENABLED=${ODL_DEF_TZ_ENABLED:-true}

cat > ${WORKSPACE}/set_genius_itm_config.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*itm*config.xml"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-itm-config.xml
    sed -i "s/<def-tz-enabled>.*</<def-tz-enabled>${ODL_DEF_TZ_ENABLED}</g" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-itm-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-itm-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting Netvirt genius default tz enabled to ${ODL_DEF_TZ_ENABLED} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_genius_itm_config.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_genius_itm_config.sh'

done
