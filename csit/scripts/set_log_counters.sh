#!/bin/bash


cat > ${WORKSPACE}/set_log_counters.sh <<EOF

    mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*counters-impl*countersconf.cfg"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.counters.cfg
    sed -i s/^writelog=.*/writelog=true/ /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.counters.cfg
    sed -i s/^interval=.*/interval=1000/ /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.counters.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.counters.cfg

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting log counters to enabled with interval of 1s on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_log_counters.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_log_counters.sh'

done
