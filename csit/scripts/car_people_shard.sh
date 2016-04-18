echo "Add car-people shards file"
cat > ${WORKSPACE}/custom_shard_config.txt <<EOF
FRIENDLY_MODULE_NAMES[1]='inventory'
MODULE_NAMESPACES[1]='urn:opendaylight:inventory'
FRIENDLY_MODULE_NAMES[2]='topology'
MODULE_NAMESPACES[2]='urn:TBD:params:xml:ns:yang:network-topology'
FRIENDLY_MODULE_NAMES[3]='toaster'
MODULE_NAMESPACES[3]='http://netconfcentral.org/ns/toaster'
FRIENDLY_MODULE_NAMES[4]='car'
MODULE_NAMESPACES[4]='urn:opendaylight:params:xml:ns:yang:controller:config:sal-clustering-it:car'
FRIENDLY_MODULE_NAMES[5]='people'
MODULE_NAMESPACES[5]='urn:opendaylight:params:xml:ns:yang:controller:config:sal-clustering-it:people'
FRIENDLY_MODULE_NAMES[6]='car-people'
MODULE_NAMESPACES[6]='urn:opendaylight:params:xml:ns:yang:controller:config:sal-clustering-it:car-people'
EOF

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copy shard config to member-${i} with IP address ${!CONTROLLERIP}"
    scp ${WORKSPACE}/custom_shard_config.txt ${!CONTROLLERIP}:/tmp/
done
