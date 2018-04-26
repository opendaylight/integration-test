#!/bin/bash

cat > ${WORKSPACE}/system2-ovs-restart.sh <<EOF

sudo rm -rf /etc/openvswitch/conf.db 
sudo service openvswitch-switch restart

EOF
scp ${WORKSPACE}/system2-ovs-restart.sh ${TOOLS_SYSTEM_2_IP}:/tmp/
ssh ${TOOLS_SYSTEM_2_IP} 'sudo bash /tmp/system2-ovs-restart.sh'
