#!/bin/bash


cat > ${WORKSPACE}/set_itm_direct_tunnels.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*ifm*config.xml"\`
    echo "Conf file path"
    echo $CONFFILE
    export NATCONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*natservice*config.xml"\`
    echo "NAT Conf file path"
    echo $NATCONFFILE
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-ifm-config.xml
    sed -i 's/itm-direct-tunnels>false/itm-direct-tunnels>${ENABLE_ITM_DIRECT_TUNNELS}/g' /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-ifm-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/genius-ifm-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting itm-direct-tunnels to ${ENABLE_ITM_DIRECT_TUNNELS} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_itm_direct_tunnels.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_itm_direct_tunnels.sh'

done
