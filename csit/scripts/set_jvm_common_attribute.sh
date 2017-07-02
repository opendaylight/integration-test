#!/bin/bash

cat > ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-local.cfg <<EOF
type=jmx-local
url=local
object.name=java.lang:type=*,name=*

EOF

cat > ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-others.cfg <<EOF
type=jmx-local
url=local
object.name=java.lang:type=*

EOF


for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP

    echo "Copying config files to ${!CONTROLLERIP}"

    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-local.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-others.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/

done
