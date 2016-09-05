#!/bin/bash

BGPCONF=/tmp/${BUNDLEFOLDER}/system/org/opendaylight/bgpcep/bgp-controller-config/*/bgp-controller-config-*-config-example.xml

cat > ${WORKSPACE}/bgp_cluster_setup_Be.sh <<EOF

  echo "Update bgp configuration in 41-bgp-example.xml"
  sed -i -e "s/<rib-id>example-bgp-rib/<rib-id>example-bgp-rib-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-ipv4-topology/<topology-id>example-ipv4-topology-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-ipv6-topology/<topology-id>example-ipv6-topology-\$1/g" ${BGPCONF}
  sed -i -e "s/<topology-id>example-linkstate-topology/<topology-id>example-linkstate-topology-\$1/g" ${BGPCONF}

  echo "Dump ${BGPCONF}"
  cat ${BGPCONF}

EOF

if [ "${DISTROSTREAM}" == "beryllium" ]; then

  echo "Copying config files to ODL Controller folder"
  for i in `seq 1 ${NUM_ODL_SYSTEM}`
  do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Configuring bgp for cluster on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/bgp_cluster_setup_Be.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} "bash /tmp/bgp_cluster_setup_Be.sh $i"
  done

fi
