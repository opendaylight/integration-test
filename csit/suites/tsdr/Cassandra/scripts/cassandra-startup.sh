#!/bin/bash

# Installation of Cassandra
cat > ${WORKSPACE}/cassandrastartup.sh <<EOF
cd /tmp/cassandra
echo "Start the Cassandra Server"
export JAVA_HOME=/usr
sudo /tmp/cassandra/apache-cassandra-2.1.14/bin/cassandra
ls -l /tmp/cassandra/apache-cassandra-2.1.14/bin/cassandra

EOF
echo "Copy the Cassanra startup script to ${ODL_SYSTEM_IP}"
scp ${WORKSPACE}/cassandrastartup.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/cassandrastartup.sh'
ssh ${ODL_SYSTEM_IP} 'ps -ef | grep cassandra'
# vim: ts=4 sw=4 sts=4 et ft=sh :
