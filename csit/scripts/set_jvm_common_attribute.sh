#!/bin/bash

cat > ${WORKSPACE}/elasticsearch_startup.sh <<EOF
cd /tmp/elasticsearch
echo "Starting Elasticsearch node"
sudo /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch > /dev/null 2>&1 &
ls -al /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch

EOF

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

    cat > ${WORKSPACE}/elasticsearch.yml <<EOF
    cluster.name: elasticsearch
    network.host: ${!CONTROLLERIP}

EOF
    cat > ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg <<EOF
    host=${!CONTROLLERIP}
    port=9300
    clusterName=elasticsearch

EOF

    echo "Setup ODL_SYSTEM_IP specific config files for ${!CONTROLLERIP} "

    cat ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg
    cat ${WORKSPACE}/elasticsearch.yml


    echo "Copying config files to ${!CONTROLLERIP}"

    scp ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-local.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
    scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-others.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/

    scp ${WORKSPACE}/elasticsearch.yml ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} "sudo mv /tmp/elasticsearch.yml /tmp/elasticsearch/elasticsearch-1.7.5/config/"
    ssh ${!CONTROLLERIP} "cat /tmp/elasticsearch/elasticsearch-1.7.5/config/elasticsearch.yml"

    echo "Copying the elasticsearch_startup script to ${!CONTROLLERIP}"
    cat ${WORKSPACE}/elasticsearch_startup.sh
    scp ${WORKSPACE}/elasticsearch_startup.sh ${!CONTROLLERIP}:/tmp
    ssh ${!CONTROLLERIP} 'bash /tmp/elasticsearch_startup.sh'
    ssh ${!CONTROLLERIP} 'ps aux | grep elasticsearch'

done
