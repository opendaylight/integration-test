#!/bin/bash

WORKSPACE=/tmp/
cat > ${WORKSPACE}/set_of_stats_mode.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/

    cat << EOF2 > /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/openflow-provider-config_openflow-provider-config.xml
<openflow-provider-config xmlns="urn:opendaylight:params:xml:ns:yang:openflow:provider:config">
  <is-statistics-polling-on>false</is-statistics-polling-on>
</openflow-provider-config>
EOF2

    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/openflow-provider-config_openflow-provider-config.xml
EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Disabling openflow statistics polling on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_of_stats_mode.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_of_stats_mode.sh'

done
