#!/bin/bash

cat > ${WORKSPACE}/set_ovsdb_inactivity_probe.sh <<EOF
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*elanmanager*config.xml"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    sed -i "/  <\!--/d" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    sed -i "/  -->/d" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    sed -i "s/<controller-max-backoff>5000<\/controller-max-backoff>/<controller-max-backoff>5000<\/controller-max-backoff>/" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    sed -i "s/<controller-inactivity-probe>5000<\/controller-inactivity-probe>/<controller-inactivity-probe>30000<\/controller-inactivity-probe>/" /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-elanmanager-config.xml

EOF

echo "Copying and running running elanmanager config script on ODL Controller(s)"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Setting ovsdb inactivity_probe to 30s on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_ovsdb_inactivity_probe.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_ovsdb_inactivity_probe.sh'
done
