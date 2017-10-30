#!/bin/bash

ODL_AUTO_CONFIG_TRANSPORT_ZONES=${ODL_AUTO_CONFIG_TRANSPORT_ZONES:-false}

cat > ${WORKSPACE}/set_netvirt_tz.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*elanmanager*config.xml"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    sed -i "s/<auto-config-transport-zones>.*</<auto-config-transport-zones>${ODL_AUTO_CONFIG_TRANSPORT_ZONES}</g" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting Netvirt elanmanager auto config transport zone mode to ${ODL_AUTO_CONFIG_TRANSPORT_ZONES} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_netvirt_tz.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_netvirt_tz.sh'

done
