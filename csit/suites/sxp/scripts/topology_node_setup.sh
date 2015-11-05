#!/bin/bash

echo "Setup config to ${ODL_SYSTEM_IP}"
ssh ${ODL_SYSTEM_IP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"

if [ "${BRANCH#*/}" == "lithium" ]; then
    LI_FIX="<notification-service>\n<type xmlns:binding=\"urn:opendaylight:params:xml:ns:yang:controller:md:sal:binding\">\nbinding:binding-notification-service\n</type>\n<name>binding-notification-broker</name>\n</notification-service>";
    sed -i "36i $LI_FIX" ${WORKSPACE}/test/csit/suites/sxp/basic/22-sxp-controller-one-node.xml;
fi

scp ${WORKSPACE}/test/csit/suites/sxp/topology/22-sxp-controller-one-node.xml ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/
