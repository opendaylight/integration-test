#!/bin/bash

GROUP_ADD_MOD_ENABLED=${GROUP_ADD_MOD_ENABLED:-false}

cat > ${WORKSPACE}/set_group_add_mod_enabled.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*openflow*config.xml"\`
    if ! [ "\$CONFFILE" ]; then
        echo "No configuration file exists for *openflow*config.xml - skipping group-add-mod-enabled configuration"
        exit 0
    fi
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/default-openflow-connection-config.xml
    sed -i "s#<group-add-mod-enabled>.*</group-add-mod-enabled>#<group-add-mod-enabled>${GROUP_ADD_MOD_ENABLED}</group-add-mod-enabled>#" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/default-openflow-connection-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/default-openflow-connection-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting group-add-mod-enabled mode to ${GROUP_ADD_MOD_ENABLED} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_group_add_mod_enabled.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_group_add_mod_enabled.sh'

done