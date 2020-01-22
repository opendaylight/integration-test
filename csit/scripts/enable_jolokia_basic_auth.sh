#!/bin/bash


cat > ${WORKSPACE}/enable_jolokia_basic_auth.sh <<EOF

    #export CONFFILE=\`find /tmp/${BUNDLEFOLDER} -name "*org.jolokia.osgi.cfg"\`
    #cp \$CONFFILE /tmp/${BUNDLEFOLDER}/etc/org.jolokia.osgi.cfg
    echo "org.jolokia.authMode=basic" >> /tmp/${BUNDLEFOLDER}/etc/org.jolokia.osgi.cfg
    echo "org.jolokia.user=admin" >> /tmp/${BUNDLEFOLDER}/etc/org.jolokia.osgi.cfg
    echo "org.jolokia.password=admin" >> /tmp/${BUNDLEFOLDER}/etc/org.jolokia.osgi.cfg
    cat /tmp/${BUNDLEFOLDER}/etc/org.jolokia.osgi.cfg

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Enabling jolokia basic auth with default values on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/enable_jolokia_basic_auth.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/enable_jolokia_basic_auth.sh'

done
