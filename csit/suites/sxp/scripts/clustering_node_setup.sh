#!/bin/bash

echo "Setup config to ${TOOLS_SYSTEM_IP}"

scp /tmp/${BUNDLE} ${TOOLS_SYSTEM_IP}:/tmp/
ssh ${TOOLS_SYSTEM_IP} "cd /tmp/ && unzip -q /tmp/${BUNDLE}"
ssh ${TOOLS_SYSTEM_IP} "/tmp/${BUNDLEFOLDER}/bin/start"