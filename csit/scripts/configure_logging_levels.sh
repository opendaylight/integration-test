#!/bin/bash

LOGGING_MODULE=$1
LOGGING_LEVEL=$2

cat > ${WORKSPACE}/configure_logging.sh <<EOF
    echo "${LOGGING_MODULE} = ${LOGGING_LEVEL}" >> /tmp/\${BUNDLEFOLDER}/etc/org.ops4j.pax.logging.cfg
EOF

echo "Executing the following config file on each ODL controller"
cat ${WORKSPACE}/configure_logging.sh
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Custom logging configurations on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/configure_logging.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/configure_logging.sh'

done
