#!/bin/bash

cat > ${WORKSPACE}/set_bundleresync_flag.sh <<EOF
    export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*openflowplugin*config.cfg"\`
    cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
    sed -i "s/# bundle-based-reconciliation-enabled=false/bundle-based-reconciliation-enabled=true/" /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.opendaylight.openflowplugin.cfg
EOF

echo "Running bundleresync_flag script on ODL Controller(s)"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Enabling bundleresync_flag on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_bundleresync_flag.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_bundleresync_flag.sh'
done

rm ${WORKSPACE}/set_bundleresync_flag.sh
