#!/bin/bash

echo "Setup config to ${CONTROLLER0}"
ssh ${CONTROLLER0} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"

scp ${WORKSPACE}/test/csit/suites/sxp/topology/22-sxp-controller-one-node.xml ${CONTROLLER0}:/tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/
