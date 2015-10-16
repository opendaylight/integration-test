#!/bin/bash

echo "Setup config to ${CONTROLLER0}"
ssh ${ODL_SYSTEM_IP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"

scp ${WORKSPACE}/test/csit/suites/sxp/topology/22-sxp-controller-one-node.xml ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/
