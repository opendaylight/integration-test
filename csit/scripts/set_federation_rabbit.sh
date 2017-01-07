#!/bin/bash

if [[ ${CONTROLLERFEATURES} == *federation* ]]; then

cat > ${WORKSPACE}/set_federation_rabbit.sh <<EOF

    echo "Install rabbit server ..."
    sudo yum install -y erlang
    sudo yum install -y rabbitmq-server

    echo "Starting rabbit server ..."
    sudo chkconfig rabbitmq-server
    sudo service rabbitmq-server start

    echo "Add federation user to rabbit server ..."
    sudo /usr/sbin/rabbitmqctl add_user federation federation
    sudo rabbitmqctl set_permissions -p / federation ".*" ".*" ".*"

    echo "Configuring rabbit broker for ODL ..."
    SERVICECONF=\$(find "/tmp/${BUNDLEFOLDER}/" -name "federation-service-impl-*config.xml")
    sed -ie "s/<site-ip>.*</<site-ip>\$2</g" \${SERVICECONF}
    sed -ie "s/<mqBrokerIp>.*</<mqBrokerIp>\$1</g" \${SERVICECONF}
    sed -ie "s/CONTROL_QUEUE_.*</CONTROL_QUEUE_\$1</g" \${SERVICECONF}
    sed -ie "s/guest/federation/g" \${SERVICECONF}
    cat \${SERVICECONF}

EOF

    echo "Copying config files to ODL Controller folder"
    for i in `seq 1 ${NUM_ODL_SYSTEM}`
    do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        ODL_SITE_IP=${ODL_SYSTEM_1_IP}
        if [ ${NUM_ODL_SYSTEM} -gt 1 ]; then
            HA_PROXY_IP=OPENSTACK_COMPUTE_NODE_${NUM_OPENSTACK_SYSTEM}_IP
            ODL_SITE_IP=${!HA_PROXY_IP}
        fi
        echo "Setting rabbit client site ip to ${ODL_MGR_IP} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_federation_rabbit.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_federation_rabbit.sh' ${!CONTROLLERIP} ${ODL_SITE_IP}
    done

fi
