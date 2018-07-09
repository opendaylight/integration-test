#!/bin/bash

cat > ${WORKSPACE}/set_ovsdb_monitor.sh <<EOF
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*southbound-impl*config.cfg"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.southbound.cfg
    sed -i "s/#skip-monitoring-manager-status = false/skip-monitoring-manager-status = true/" /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.southbound.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.southbound.cfg
EOF

echo "Copying and running running ovsdb config script on ODL Controller(s)"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Setting ovsdb skip-monitoring-manager-status to true on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_ovsdb_monitor.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_ovsdb_monitor.sh'
done
