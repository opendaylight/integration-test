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
ADDRESS1=`nova list | grep T1-vm | awk -F "net100=" '{print $2}' | awk  '{print $1}'`


# Create net,subnet,security rules and VM on tenant2
echo log in as T2
. /opt/stack/devstack/openrc admin T2 &> /dev/null
neutron security-group-rule-create default --direction ingress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron security-group-rule-create default --direction egress --protocol icmp --remote_ip_prefix 0.0.0.0/0
neutron net-create net100
neutron subnet-create --name subnet100 net100 192.168.100.0/24
nova boot --image $IMAGE --flavor $FLAVOR T2-vm
sleep 10
ADDRESS2=`nova list | grep T2-vm | awk -F "net100=" '{print $2}' | awk  '{print $1}'`

# Check ping to VMs
DHCP1=`sudo ip netns|head -n 2| tail -n 1| awk '{print$1}'`
DHCP2=`sudo ip netns|head -n 1| awk '{print$1}'`
echo ping T1-vm from T1 network namespace
#echo sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1
RESULT1=`sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null;
then
	echo "LOG: Ping to $ADDRESS1 pass";
else
	echo "LOG: Ping to $ADDRESS1 fail";
fi

echo ping T2-vm from T2 network namespace
#echo sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS2
RESULT2=`sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS2`
if echo $RESULT2 | grep " 0%" &> /dev/null;
then    
        echo "LOG: Ping to $ADDRESS2 pass";
else
        echo "LOG: Ping to $ADDRESS2 fail";
fi

# Check ping from network1 to VM2 and vice versa- ping should fail
echo ping T1-vm from T2 network namespace
#echo sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS1
RESULT1=`sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null;
then
        echo "LOG: Ping to $ADDRESS1 pass but it was supposed to FAIL!!!!!!!!!!!!!!!!!!";
else
        echo "LOG: Ping to $ADDRESS1 fail as expected";
fi

echo ping T2-vm from T1 network namespace
#echo sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS2
RESULT2=`sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS2`
if echo $RESULT2 | grep " 0%" &> /dev/null;
then
        echo "LOG: Ping to $ADDRESS2 pass but it was supposed to FAIL!!!!!!!!!!!!!!!!!!";
else
        echo "LOG: Ping to $ADDRESS2 fail as expected";
fi

# delete VM on T2
nova delete T2-vm 

# Check ping to VMs:T1-vm should work and T2-vm should fail
echo ping T1-vm from T1 network namespace
#echo sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1
RESULT1=`sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null;
then
	echo "LOG: Ping to $ADDRESS1 pass";
else
 	echo "LOG: Ping to $ADDRESS1 fail";
fi

echo ping T2-vm from T2 network namespace
#echo sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS2
RESULT2=`sudo ip netns exec $DHCP2 ping -c 3 -w 3 $ADDRESS2`
if echo $RESULT2 | grep " 0%" &> /dev/null;
then    
         echo "LOG: Ping to $ADDRESS2 pass but it was supposed to FAIL!!!!!!!!!!!";
else
         echo "LOG: Ping to $ADDRESS2 fail as expected";
fi

# delete net on T2 - if it fails then there is linkage between tenants
NET_DELETE=`neutron net-delete net100`
if echo $NET_DELETE |grep "Deleted network" 
then
	echo "LOG: Delete net on Tenant2 succeeded";
else
	echo "LOG: Delete net on tenant1 failed";
fi

# delete tenant
echo log in as admin
. /opt/stack/devstack/openrc admin admin &> /dev/null
echo LOG: Delete T2
openstack project delete T2

# check ping to T1-vm
echo ping T1-vm from T1 network namespace
#echo sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1
RESULT1=`sudo ip netns exec $DHCP1 ping -c 3 -w 3 $ADDRESS1`
if echo $RESULT1 | grep " 0%" &> /dev/null;
then
        echo "LOG: Ping to $ADDRESS1 pass";
else
        echo "LOG: Ping to $ADDRESS1 fail";
fi

# cleanup
echo !!!!!!!!!!!!!!!!!! CLEAN-UP !!!!!!!!!!!!!!!
. /opt/stack/devstack/openrc admin T1
nova delete T1-vm
neutron net-delete net100
. /opt/stack/devstack/openrc admin admin
openstack project delete T1
neutron net-delete external-net
