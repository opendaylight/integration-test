#!/bin/bash
echo "Setup long duration config to ${ODL_SYSTEM_IP}"

cat > ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg <<EOF
period=120000

EOF

echo "Copying config files to ODL Controller folder"

ssh ${ODL_SYSTEM_IP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"

scp ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/
