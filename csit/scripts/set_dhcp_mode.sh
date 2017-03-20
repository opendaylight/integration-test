#!/bin/bash

ODL_DHCP_ENABLED=true

cat > ${WORKSPACE}/set_dhcp_mode.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*dhcpservice*config.xml"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml
    sed -i s/false/${ODL_DHCP_ENABLED}/ /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-dhcpservice-config.xml

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting Controller based DHCP mode to ${ODL_DHCP_ENABLED} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_dhcp_mode.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_dhcp_mode.sh'

done
