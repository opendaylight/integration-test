#!/bin/bash

echo log in as admin
. /opt/stack/devstack/openrc admin admin &> /dev/null

# Add external net
neutron net-create external-net --router:external --provider:network_type=flat --provider:physical_network=physnet1
neutron subnet-create --name external-subnet external-net 10.10.10.0/24  --gateway 10.10.10.250

# get info for setting up a VM
IMAGE=`glance image-list | grep "64-uec " | awk '{print$4}'`
FLAVOR=`nova flavor-list | grep nano | awk '{print$2}'`

# Create 2 new tenants and add role 
openstack project create T1
openstack project create T2
openstack role add --project T1 --user admin Member
openstack role add --project T2 --user admin Member

# Create net,subnet,security rules and VM on tenant1
echo log in as T1
. /opt/stack/devstack/openrc admin T1 &> /dev/null
neutron security-group-rule-create default --direction ingress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron security-group-rule-create default --direction egress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron net-create net100
neutron subnet-create --name subnet100 net100 192.168.100.0/24
nova boot --image $IMAGE --flavor $FLAVOR T1-vm
sleep 10

# Add FIP to T1-vm
neutron router-create R100
neutron router-interface-add R100 subnet100
neutron router-gateway-set R100 external-net
ADDRESS1=`neutron floatingip-create external-net | grep floating_ip_address | awk '{print$4}'`
ID1=`neutron floatingip-list | grep $ADDRESS1 | awk '{print$2}'`
neutron floatingip-list
echo $ID1
nova floating-ip-associate T1-vm $ADDRESS1
sleep 2

# Create net,subnet,security rules and VM on tenant2
echo log in as T2
. /opt/stack/devstack/openrc admin T2 &> /dev/null
neutron security-group-rule-create default --direction ingress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron security-group-rule-create default --direction egress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron net-create net100
neutron subnet-create --name subnet100 net100 192.168.100.0/24
nova boot --image $IMAGE --flavor $FLAVOR T2-vm
sleep 10

# Add FIP to T2-vm
neutron router-create R100
neutron router-interface-add R100 subnet100
neutron router-gateway-set R100 external-net
ADDRESS2=`neutron floatingip-create external-net | grep floating_ip_address | awk '{print$4}'`
ID2=`neutron floatingip-list | grep $ADDRESS2 | awk '{print$2}'`
neutron floatingip-list
echo $ID2
nova floating-ip-associate T2-vm $ADDRESS2
sleep 2

# Check ping to VMs FIP
echo ping to FIP of T1
RESULT1=`ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null
then
	echo "LOG: Ping to $ADDRESS1 pass"
else
	echo "LOG: Ping to $ADDRESS1 fail"
fi

echo ping to FIP of T2
RESULT2=`ping -c 3 -w 3 $ADDRESS2`
if echo $RESULT2 | grep " 0%" &> /dev/null
then    
        echo "LOG: Ping to $ADDRESS2 pass"
else
        echo "LOG: Ping to $ADDRESS2 fail"
fi

# Try to delete T1-vm FIP from T2
echo Try to delete T1-vm FIP from T2
RESULT3=`neutron floatingip-delete $ID1`
if echo $RESULT3 | grep "Unable to find floatingip" &> /dev/null
then
	echo "LOG: Can't delete T1-vm FIP from T2"
else
	echo "LOG: T2 just delete T1-vm FIP but it suppose to FAIL!!!!!!!!!!!!!!!!!!!!!"
fi

# Delete FIP of T2
echo Delete T2-vm FIP
RESULT3=`neutron floatingip-delete $ID2`
if echo $RESULT3 | grep "Deleted floatingip" &> /dev/null
then
	echo "LOG: Delete $ADDRESS2 succeeded"
else
	echo "LOG: Delete $ADDRESS2 failed"
fi

# Check ping to VMs FIP- ping to FIP T2 should fail
echo ping to FIP of T1
RESULT1=`ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null
then
        echo "LOG: Ping to $ADDRESS1 pass"
else
        echo "LOG: Ping to $ADDRESS1 fail"
fi

echo ping to FIP of T2
RESULT2=`ping -c 3 -w 3 $ADDRESS2`
if echo $RESULT2 | grep " 0%" &> /dev/null
then
        echo "LOG: Ping to $ADDRESS2 pass but it was supposed to fail"
else
        echo "LOG: Ping to $ADDRESS2 fail as expected"
fi

# cleanup
echo !!!!!!!!!!!!!!!!!! CLEAN-UP !!!!!!!!!!!!!!!
echo log in as T1
. /opt/stack/devstack/openrc admin T1 &> /dev/null
neutron floatingip-delete $ID1
neutron router-interface-delete R100 subnet100
neutron router-gateway-clear R100
neutron router-delete R100
nova delete T1-vm
neutron net-delete net100
echo log in as T2
. /opt/stack/devstack/openrc admin T2 &> /dev/null
neutron router-interface-delete R100 subnet100
neutron router-gateway-clear R100
neutron router-delete R100
nova delete T2-vm
neutron net-delete net100
echo log in as admin
. /opt/stack/devstack/openrc admin admin &> /dev/null
openstack project delete T1
openstack project delete T2
neutron net-delete external-net
