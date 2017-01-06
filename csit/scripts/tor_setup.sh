#!/bin/bash

cat > ${WORKSPACE}/tor_setup.sh <<EOF
echo "TOR software install procedure"
sudo apt-get install -y --force-yes openvswitch-vtep
sudo ovs-vswitchd --version

ps -ef | grep ovs
sudo killall -9 python
sudo killall -9 ovs-vswitchd
sudo killall -9 ovsdb-server
sudo rm /etc/openvswitch/ovs.db
sudo rm /etc/openvswitch/vtep.db
sudo ovsdb-tool create /etc/openvswitch/ovs.db /usr/share/openvswitch/vswitch.ovsschema
sudo ovsdb-tool create /etc/openvswitch/vtep.db /usr/share/openvswitch/vtep.ovsschema
sleep 1
sudo ovsdb-server --pidfile --detach --log-file --remote punix:/var/run/openvswitch/db.sock --remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db
ps -ef | grep ovs
sudo ovs-vsctl --no-wait init
sudo ovs-vswitchd --pidfile --detach
sudo ovs-vsctl add-br br-ovs
sudo ovs-vsctl show
sleep 1
sudo vtep-ctl add-ps br-ovs
sudo vtep-ctl set Physical_Switch br-ovs tunnel_ips=192.168.122.1
sudo /usr/share/openvswitch/scripts/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=/var/run/openvswitch/ovs-vtep.pid --detach br-ovs
ps -ef | grep ovs
sudo ovsdb-client dump hardware_vtep

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/tor_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/tor_setup.sh'
done

