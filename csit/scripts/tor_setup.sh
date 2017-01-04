#!/bin/bash

cat > ${WORKSPACE}/tor_setup.sh <<EOF

echo "TOR software install procedure"
sudo apt-get remove openvswitch-common openvswitch-datapath-dkms openvswitch-controller openvswitch-pki openvswitch-switch -y
sudo add-apt-repository -y ppa:sgauthier/openvswitch-dpdk
sudo apt-get update -y --force-yes
sudo apt-get install -y --force-yes openvswitch-switch
sudo apt-get install -y --force-yes openvswitch-vtep
sudo ovs-vswitchd --version

echo '---> All Python package installation should happen in virtualenv'
sudo apt-get install -y --force-yes python-virtualenv python-pip

echo '---> Install OVS 2.4 Python module'
wget -c https://pypi.python.org/packages/2f/8a/358cad389613865ee255c7540f9ea2c2f98376c2d9cd723f5cf30390d928/ovs-2.4.0.tar.gz#md5=9097ced87a88e67fbc3d4b92c16e6b71
tar -zxvf ovs-2.4.0.tar.gz
cd ovs-2.4.0
sudo mkdir -p /var/run/openvswitch/
sudo python setup.py install
cd ..

#Stop  OVS 2.5 services
#sudo killall -9 ovs-vtep
#sudo killall -9 ovs-vswitchd
#sudo killall -9 ovsdb-server
#ps -ef | grep ovs

#Configure OVS 2.5 TOR emulation
#sudo rm /etc/openvswitch/ovs.db
#sudo rm /etc/openvswitch/vtep.db
#export OVS_HOME="/usr/share/openvswitch/"
#locate vswitch.ovsschema
#sudo find / -name vswitch.ovsschema
#locate vtep.ovsschema
#sudo find / -name vtep.ovsschema
#sudo ovsdb-tool create /etc/openvswitch/ovs.db /usr/share/openvswitch/vswitch.ovsschema
#sudo ovsdb-tool create /etc/openvswitch/vtep.db /usr/share/openvswitch/vtep.ovsschema
#sleep 1
#sudo ls -l /usr/var/run/openvswitch/
#sudo mkdir -p /usr/var/run/openvswitch/
#sudo ovsdb-server --pidfile --detach --log-file --remote punix:/usr/var/run/openvswitch/db.sock \
#--remote=db:hardware_vtep,Global,managers /etc/openvswitch/ovs.db /etc/openvswitch/vtep.db
#sudo ovs-vsctl --no-wait init
#sudo ovs-vswitchd --pidfile --detach
#sudo ovs-vsctl add-br br0
#sleep 1
#sudo ovs-vsctl show
#sudo vtep-ctl add-ps br0
#sudo vtep-ctl set Physical_Switch br0 tunnel_ips=12.0.0.11

EOF

echo "Execute the TOR software install procedure on all the tools VMs"
for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/tor_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/tor_setup.sh'
done
