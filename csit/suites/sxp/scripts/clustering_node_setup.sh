#!/bin/bash
WORK_DIR="/tmp"

echo "Extracting the new controller... [${TOOLS_SYSTEM_IP}]"
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${ACTUALBUNDLEURL} -P ${WORK_DIR}
ssh ${TOOLS_SYSTEM_IP} unzip -q ${WORK_DIR}/${BUNDLE} -d ${WORK_DIR}

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} /tmp/${BUNDLEFOLDER}/bin/start
