#!/bin/bash

# Installation of Hbase
cat > ${WORKSPACE}/hbasestartup.sh <<EOF

mkdir -p /tmp/Hbase
cd /tmp/Hbase
wget --no-verbose https://archive.apache.org/dist/hbase/hbase-0.94.15/hbase-0.94.15.tar.gz
echo "Installing the Hbase Server..."
tar -xvf hbase*.tar.gz
echo "Start the HBase Server"
export JAVA_HOME=/usr
/tmp/Hbase/hbase-0.94.15/bin/start-hbase.sh

EOF
echo "Copy the Hbase startup script to ${ODL_SYSTEM_IP}"
scp ${WORKSPACE}/hbasestartup.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/hbasestartup.sh'
# vim: ts=4 sw=4 sts=4 et ft=sh :
