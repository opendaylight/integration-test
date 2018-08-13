#!/bin/bash

cat > ${WORKSPACE}/system-ovs-restart.sh <<EOF

sudo rm -rf /etc/openvswitch/conf.db
sudo service openvswitch-switch restart

EOF
scp ${WORKSPACE}/system-ovs-restart.sh ${TOOLS_SYSTEM_2_IP}:/tmp/
ssh ${TOOLS_SYSTEM_2_IP} 'sudo bash /tmp/system-ovs-restart.sh'
scp ${WORKSPACE}/system-ovs-restart.sh ${TOOLS_SYSTEM_3_IP}:/tmp/
ssh ${TOOLS_SYSTEM_3_IP} 'sudo bash /tmp/system-ovs-restart.sh'
scp ${WORKSPACE}/system-ovs-restart.sh ${TOOLS_SYSTEM_4_IP}:/tmp/
ssh ${TOOLS_SYSTEM_2_IP} 'sudo bash /tmp/system-ovs-restart.sh'
scp ${WORKSPACE}/system-ovs-restart.sh ${TOOLS_SYSTEM_5_IP}:/tmp/
ssh ${TOOLS_SYSTEM_2_IP} 'sudo bash /tmp/system-ovs-restart.sh'
