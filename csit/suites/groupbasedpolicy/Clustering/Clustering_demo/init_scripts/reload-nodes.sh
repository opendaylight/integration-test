#! /bin/bash -x
sudo service vpp stop
sudo service honeycomb stop
#remove persistent data
sudo rm -rf /var/lib/honeycomb/persist/config/*
sudo rm -rf /var/lib/honeycomb/persist/context/*

sleep 3
sudo service vpp start
sleep 5
sudo service honeycomb start
sleep 3

if [ $(hostname) = "controller" ]; then
    sudo pkill -f karaf
    sudo rm -rf /opt/distribution-karaf-0.5.0-Boron/data/ /opt/distribution-karaf-0.5.0-Boron/journal/ /opt/distribution-karaf-0.5.0-Boron/snapshots/ /opt/distribution-karaf-0.5.0-Boron/instances/
    cd
    sudo vppctl set int state GigabitEthernet0/9/0 up
    sudo vppctl set int state GigabitEthernet0/a/0 up
    sudo vppctl set int ip address GigabitEthernet0/9/0 10.0.0.1/24
    sudo vppctl sh int
    sudo vppctl sh int address

    sleep 20
    curl -u admin:admin -X GET -H 'Content-Type: application/xml' http://localhost:8283/restconf/config/ietf-interfaces:interfaces/ | python -m json.tool
    sudo /opt/distribution-karaf-0.5.0-Boron/bin/karaf debug
    echo "
USE THE FOLLOWING FEATURES IN ODL, THEN REGISTER ALL VPP NODES:

log:set ERROR org.opendaylight.netconf
feature:install odl-vbd-ui odl-groupbasedpolicy-neutron-vpp-mapper odl-restconf
log:set TRACE org.opendaylight.groupbasedpolicy.renderer.vpp
log:set TRACE org.opendaylight.groupbasedpolicy.neutron.vpp.mapper
log:set TRACE org.opendaylight.vbd.impl
log:set ERROR org.opendaylight.netconf
logout


/vagrant/register_vpp_node.sh 192.168.255.100 compute0 192.168.255.101
/vagrant/register_vpp_node.sh 192.168.255.100 compute1 192.168.255.102
/vagrant/register_vpp_node.sh 192.168.255.100 controller 192.168.255.100"
fi;

if [ $(hostname) = "compute0" ]; then
    sudo vppctl set int state GigabitEthernet0/9/0 up
    sudo vppctl set int state GigabitEthernet0/a/0 up
    sudo vppctl set int ip address GigabitEthernet0/9/0 10.0.0.2/24
    sudo vppctl sh int
    sudo vppctl sh int address

    sleep 20
    curl -u admin:admin -X GET -H 'Content-Type: application/xml' http://localhost:8283/restconf/config/ietf-interfaces:interfaces/ | python -m json.tool
fi;

if [ $(hostname) = "compute1" ]; then
    sudo vppctl set int state GigabitEthernet0/9/0 up
    sudo vppctl set int state GigabitEthernet0/a/0 up
    sudo vppctl set int ip address GigabitEthernet0/9/0 10.0.0.3/24
    sudo vppctl sh int
    sudo vppctl sh int address

    sleep 20
    curl -u admin:admin -X GET -H 'Content-Type: application/xml' http://localhost:8283/restconf/config/ietf-interfaces:interfaces/ | python -m json.tool
fi;



