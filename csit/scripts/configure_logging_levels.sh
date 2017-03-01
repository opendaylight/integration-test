#!/bin/bash

cat > ${WORKSPACE}/configure_logging.sh <<EOF
    echo "\${LOGGING_MODULE} = \${LOGGING_LEVEL}" >> /tmp/\${BUNDLEFOLDER}/etc/org.ops4j.pax.logging.cfg
    # echo "log4j.logger.org.opendaylight.openflowjava.protocol.impl.util = ERROR" >> /tmp/\${BUNDLEFOLDER}/etc/org.ops4j.pax.logging.cfg
EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Custom logging configurations on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/configure_logging.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/configure_logging.sh'

done
