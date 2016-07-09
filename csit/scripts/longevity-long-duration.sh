#!/bin/bash
echo "Setup config to ${ODL_SYSTEM_IP}"

cat > ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg <<EOF
period=5000

EOF

cat > ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg <<EOF
host=${ODL_SYSTEM_IP}
port=9300
clusterName=elasticsearch

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

echo "Copying config files to ODL Controller folder"

ssh ${ODL_SYSTEM_IP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"

scp ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/
scp ${WORKSPACE}/org.apache.karaf.decanter.appender.elasticsearch.cfg ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/
scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-local.cfg ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/
scp ${WORKSPACE}/org.apache.karaf.decanter.collector.jmx-others.cfg ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/

cat > ${WORKSPACE}/elasticsearch.yml <<EOF
cluster.name: elasticsearch
network.host: ${ODL_SYSTEM_IP}

EOF

scp ${WORKSPACE}/elasticsearch.yml ${ODL_SYSTEM_IP}:/tmp/
ssh ${ODL_SYSTEM_IP} "sudo mv /tmp/elasticsearch.yml /tmp/elasticsearch/elasticsearch-1.7.5/config/"
ssh ${ODL_SYSTEM_IP} "cat /tmp/elasticsearch/elasticsearch-1.7.5/config/elasticsearch.yml"

cat > ${WORKSPACE}/elasticsearch_startup.sh <<EOF
cd /tmp/elasticsearch
echo "Starting Elasticsearch node"
export JAVA_HOME=/usr
sudo /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch > /dev/null 2>&1 &
ls -al /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch

EOF

echo "Copying the elasticsearch_startup script to ${ODL_SYSTEM_IP}"
cat ${WORKSPACE}/elasticsearch_startup.sh
scp ${WORKSPACE}/elasticsearch_startup.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/elasticsearch_startup.sh'
ssh ${ODL_SYSTEM_IP} 'ps aux | grep elasticsearch'

echo "Waiting for Elasticsearch node to come up"

while true; do
    RESP="\$(curl --user admin:admin -sL -w "%{http_code} %{url_effective}\\n" http://${ODL_SYSTEM_IP}:9200/_cat/indices?v -o /dev/null )"
    echo $RESP
    if [[ \$RESP == *"200"* ]]; then
        echo "Elasticsearch node is up"
        break
    fi
done

ssh ${ODL_SYSTEM_IP} "curl '${ODL_SYSTEM_IP}:9200/_cat/indices?v'"
