#!/bin/bash

echo "Setup config to ${TOOLS_SYSTEM_IP}"

scp ${BUNDLE} ${TOOLS_SYSTEM_IP}:/tmp/
ssh ${TOOLS_SYSTEM_IP} "unzip -q /tmp/${BUNDLE}"
ssh ${TOOLS_SYSTEM_IP} "${BUNDLEFOLDER}/bin/start"