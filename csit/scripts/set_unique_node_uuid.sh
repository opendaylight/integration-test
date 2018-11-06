#!/bin/bash

cat > ${WORKSPACE}/system-ovs-restart.sh <<EOF
sudo rm -rf /etc/openvswitch/conf.db
sudo service openvswitch-switch restart
EOF

echo "Copying and running running set_unique_node_uuid.sh on tools system(s)"
for i in `seq 2 ${NUM_TOOLS_SYSTEM}`; do
    ip_var=TOOLS_SYSTEM_${i}_IP
    ip=${!ip_var}
    echo "Restarting openswitch to create unique node uuid"
    scp ${WORKSPACE}/system-ovs-restart.sh ${ip}:/tmp/
    ssh ${ip} 'sudo bash /tmp/system-ovs-restart.sh'
done
