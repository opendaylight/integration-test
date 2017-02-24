#!/bin/bash

# Installation of Elasticsearch
cat > ${WORKSPACE}/elasticsearch.sh <<EOF
cd /tmp/elasticsearch
echo "Start the Elasticsearch Server"
export JAVA_HOME=/usr
cd /tmp/elasticsearch/elasticsearch-1.7.5/bin
sudo /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch
ls -l /tmp/elasticsearch/elasticsearch-1.7.5/bin/elasticsearch

EOF

echo "Copy the Elasticsearch startup script to ${ODL_SYSTEM_IP}"
scp ${WORKSPACE}/elasticsearch.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/elasticsearch.sh'
ssh ${ODL_SYSTEM_IP} 'ps -ef | grep elasticsearch'
