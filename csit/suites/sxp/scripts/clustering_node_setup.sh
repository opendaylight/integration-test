#!/bin/bash

echo "Download and start Karaf in ${TOOLS_SYSTEM_IP}"
echo "Extracting the new controller..."
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${ACTUALBUNDLEURL} -P /tmp/
ls /tmp/
ssh ${TOOLS_SYSTEM_IP} ls /tmp/
ssh ${TOOLS_SYSTEM_IP} unzip -q /tmp/${BUNDLE}
echo "Configuring the startup features..."
#TODO
echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} /tmp/${BUNDLEFOLDER}/bin/start