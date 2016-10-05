#!/bin/bash

echo "Setup config to ${TOOLS_SYSTEM_IP}"
echo "${WORKSPACE}"

ls
ls ${WORKSPACE}
scp ${WORKSPACE}/${BUNDLE} ${TOOLS_SYSTEM_IP}:/tmp/
ssh ${TOOLS_SYSTEM_IP} "cd /tmp/ && unzip -q /tmp/${BUNDLE}"
ssh ${TOOLS_SYSTEM_IP} "ls /tmp/"
ssh ${TOOLS_SYSTEM_IP} "/tmp/${BUNDLEFOLDER}/bin/start"