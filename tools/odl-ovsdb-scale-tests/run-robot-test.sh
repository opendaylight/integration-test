#!/usr/bin/env bash

echo "Starting Robot test ${SUITES} ..."
pybot -c critical -e exclude \
-v WORKSPACE:${WORKSPACE} \
-v BUNDLEFOLDER:${BUNDLEFOLDER} \
-v ODL_SYSTEM_IP:${ODL_SYSTEM_IP} \
-v ODL_SYSTEM_USER:${ODL_SYSTEM_USER} \
-v TOOLS_SYSTEM_IP:${TOOLS_SYSTEM_IP} \
-v TOOLS_SYSTEM_1_IP:${TOOLS_SYSTEM_1_IP} \
-v TOOLS_SYSTEM_2_IP:${TOOLS_SYSTEM_2_IP} \
-v TOOLS_SYSTEM_3_IP:${TOOLS_SYSTEM_3_IP} \
-v TOOLS_SYSTEM_4_IP:${TOOLS_SYSTEM_4_IP} \
-v TOOLS_SYSTEM_USER:${TOOLS_SYSTEM_USER} \
-v NUM_TOOLS_SYSTEM:${NUM_TOOLS_SYSTEM} \
-v USER_HOME:${HOME} \
-v DEFAULT_LINUX_PROMPT:${DEFAULT_LINUX_PROMPT} \
-v ODL_SYSTEM_PROMPT:${ODL_SYSTEM_PROMPT} \
-v TOOLS_SYSTEM_PROMPT:${TOOLS_SYSTEM_PROMPT} \
${TESTOPTIONS} \
${SUITES} || true

echo "Fetching Karaf log..."
set +e
ssh "${ODL_SYSTEM_IP}" tail --bytes=1M "${ODL_DIR}/${BUNDLEFOLDER}/data/log/karaf.log" > "karaf.log"
sleep 5
ssh "${ODL_SYSTEM_IP}" xz -9ekvv "${ODL_DIR}/${BUNDLEFOLDER}/data/log/karaf.log"
scp "${ODL_SYSTEM_IP}:${ODL_DIR}/${BUNDLEFOLDER}/data/log/karaf.log.xz" .