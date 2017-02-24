#!/bin/bash

# Installation of Elasticsearch.
cat > ${WORKSPACE}/elasticsearch.sh <<EOF
EL_PATH=/tmp/elasticsearch/elasticsearch-1.7.5
LOG_FILE=$EL_PATH/logs/elasticsearch.log

echo "Start the Elasticsearch Server"
export JAVA_HOME=/usr

rm $LOG_FILE
cd $EL_PATH/bin

sudo $EL_PATH/bin/elasticsearch -d
echo "Check status of the Elasticsearch Server"

sleep 2
while : ;do
    [[ -f "$LOG_FILE" ]] && grep -q "started" "$LOG_FILE" && echo "Elastic search has been started" && break
done
less $LOG_FILE | grep started

EOF

echo "Copy the Elasticsearch startup script to ${ODL_SYSTEM_IP}"
scp ${WORKSPACE}/elasticsearch.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/elasticsearch.sh'
ssh ${ODL_SYSTEM_IP} 'ps -ef | grep elasticsearch'
