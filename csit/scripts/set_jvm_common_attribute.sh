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
    CLUSTERNAME=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12`

    cat > ${WORKSPACE}/elasticsearch.yml <<EOF
    cluster.name: ${CLUSTERNAME}
    network.host: ${!CONTROLLERIP}
    discovery.zen.ping.multicast.enabled: false

EOF
    cat > ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg <<EOF
    host=${!CONTROLLERIP}
    port=9300
    clusterName=${CLUSTERNAME}

EOF
    echo "Copying config files to ${!CONTROLLERIP}"
    scp ${WORKSPACE}/elasticsearch.yml ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-local.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-others.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/

done
