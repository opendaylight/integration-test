#!/bin/bash

# Installation of Hbase
cat > ${WORKSPACE}/hbasestartup.sh <<EOF
cd /tmp/Hbase
echo "Start the HBase Server"
export JAVA_HOME=/usr
/tmp/Hbase/hbase-0.94.27/bin/start-hbase.sh

EOF
echo "Copy the Hbase startup script to ${ODL_SYSTEM_IP}"
scp ${WORKSPACE}/hbasestartup.sh ${ODL_SYSTEM_IP}:/tmp
ssh ${ODL_SYSTEM_IP} 'bash /tmp/hbasestartup.sh'
# vim: ts=4 sw=4 sts=4 et ft=sh :
