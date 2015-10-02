#!/bin/bash

echo "Setup config to $ODL_SYSTEM_IP}"
ssh ${ODL_SYSTEM_IP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"
#WORKAROUND FOR BUG-4660 shutdown of clustering
ssh ${ODL_SYSTEM_IP} "touch /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/05-clustering.xml"
ssh ${ODL_SYSTEM_IP} "touch /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/06-clustered-entity-ownership.xml"

scp ${WORKSPACE}/test/csit/suites/sxp/filtering/22-sxp-controller-one-node.xml ${ODL_SYSTEM_IP}:/tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/
