#!/bin/bash


cat > ${WORKSPACE}/set_rabbit_client.sh <<EOF

    echo "Configuring rabbit broker for ODL ..."
    SERVICECONF=\$(find "/tmp/${BUNDLEFOLDER}/" -name "federation-service-impl-*config.xml")
    sed -ie "s/<site-ip>127.0.0.1/<site-ip>\$2/g" \${SERVICECONF}
    sed -ie "s/127.0.0.1/\$1/g" \${SERVICECONF}
    sed -ie "s/guest/federation/g" \${SERVICECONF}
    cat \${SERVICECONF}

EOF

if [[ ${CONTROLLERFEATURES} == *federation* ]]; then
    echo "Copying config files to ODL Controller folder"
    for i in `seq 1 ${NUM_ODL_SYSTEM}`
    do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        ODL_MGR_IP=${ODL_SYSTEM_1_IP}
        if [ ${NUM_ODL_SYSTEM} -gt 1 ]; then
            ODL_MGR_IP=${OPENSTACK_COMPUTE_NODE_3_IP}
        fi
        echo "Setting rabbit client site ip to ${ODL_MGR_IP} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_rabbit_client.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_rabbit_client.sh' ${OPENSTACK_CONTROL_NODE_IP} ${ODL_MGR_IP}
    done
fi
