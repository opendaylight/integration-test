#!/bin/bash

# Installation of Hbase
cat > ${WORKSPACE}/hbasestartup.sh <<EOF
cd /tmp/Hbase
echo "Start the HBase Server"
export JAVA_HOME=/usr
/tmp/Hbase/hbase-0.94.15/bin/start-hbase.sh

EOF
echo "Copy the Hbase startup script to ${CONTROLLER0}"
scp ${WORKSPACE}/hbasestartup.sh ${CONTROLLER0}:/tmp
ssh ${CONTROLLER0} 'bash /tmp/hbasestartup.sh'
# vim: ts=4 sw=4 sts=4 et ft=sh :
