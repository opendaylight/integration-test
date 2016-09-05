#!/bin/bash


if [ "${ODL_STREAM}" == "beryllium" ]; then

  BGPCONF=/tmp/${BUNDLEFOLDER}/system/org/opendaylight/bgpcep/bgp-controller-config/*/bgp-controller-config-*-config-example.xml

  echo "Update bgp configuration in 41-bgp-example.xml"
  sed -i -e "s/<rib-id>example-bgp-rib/<rib-id>example-bgp-rib-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-ipv4-topology/<topology-id>example-ipv4-topology-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-ipv6-topology/<topology-id>example-ipv6-topology-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-linkstate-topology/<topology-id>example-linkstate-topology-\$1/g" ${BGPCONF}

  echo "Dump ${BGPCONF}"
  cat ${BGPCONF}

fi
