#!/bin/bash

cat > ${WORKSPACE}/set_ofp_stats.sh <<EOF
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*openflowplugin*config.cfg"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
    sed -i "s/# is-statistics-polling-on=true/is-statistics-polling-on=false/" /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
EOF

echo "Running ofp config script on ODL Controller(s)"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting ofp stats to disabled on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_ofp_stats.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_ofp_stats.sh'
done

rm ${WORKSPACE}/set_ofp_stats.sh
