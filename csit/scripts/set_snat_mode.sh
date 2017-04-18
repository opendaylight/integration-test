#!/bin/bash

ODL_NAT_MODE=${ODL_NAT_MODE:-controller} # The current alternative to 'controller' is 'conntrack'

cat > ${WORKSPACE}/set_snat_mode.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*natservice*config.xml"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    sed -i s/<nat-mode>.*</nat-mode>/<nat-mode>${ODL_NAT_MODE}</nat-mode>/ /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-natservice-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting SNAT mode to ${ODL_NAT_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_snat_mode.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_snat_mode.sh'

done
