#Environment Variables
USER_HOME = "/home/mininet"
NS_SCRIPT_PATH = "/integration/test/csit/scripts/"

# Nuetron Network Variables
NEUTRON_NETWORK1 = "NET10"
NEUTRON_SUBNET1 = "NET1-SUBNET1"
NEUTRON_NETWORK2 = "NET20"
NEUTRON_SUBNET2 = "NET2-SUBNET2"
NEUTRON_IPSUBNET1 = "20.1.1.0/24"
NEUTRON_IPSUBNET2 = "30.1.1.0/24"
NEUTRON_PORT1 = "PORT11"
NEUTRON_PORT2 = "PORT12"
NEUTRON_PORT3 = "PORT21"
NEUTRON_PORT4 = "PORT22"
NEUTRON_PORT1_MAC = "00:16:3E:19:F7:8B"
NEUTRON_PORT2_MAC = "00:16:3E:BB:9B:0F"
NEUTRON_PORT3_MAC = "00:16:3E:92:F5:F8"
NEUTRON_PORT4_MAC = "00:16:3E:19:57:58"


#STK_SRVR = "10.183.255.52"
#STK_UNAME = "stack"
#STK_PWD = "stack"
#source_openrc "source openrc admin admin"
#os_script = 

#net1 = "network-1"
#net2 = "network-2"
#subnet1 = "net1-subnet1"
#subnet2 = "net2-subnet2"
#nw1 = "10.1.1.0"
#nw2 = "20.1.1.0"
#port1 = "PORT11"
#port2 = "PORT21"
#port3 = "PORT12"
#port4 = "PORT22"
#
#CREATE_NET1 = "neutron net-create " + net1 + " --provider:network_type local"
#CREATE_NET2 = "neutron net-create " + net2 + " --provider:network_type local"
#CREATE_SUBNET1 = "neutron subnet-create " + net1 +  nw1 + "/24 --name" + subnet1
#CREATE_SUBNET2 = "neutron subnet-create " + net2 +  nw2 + "/24 --name" + subnet2
#
#CREATE_PORT11 = "neutron port-create " + net1 + " --name " + port1
#CREATE_PORT21 = "neutron port-create " + net1 + " --name " + port2
#CREATE_PORT12 = "neutron port-create " + net2 + " --name " + port3
#CREATE_PORT22 = "neutron port-create " + net2 + " --name " + port4



CREATE_NET1 = "neutron net-create NET10 --provider:network_type local"
CREATE_SUBNET1 = "neutron subnet-create NET10 10.1.1.0/24 --name NET1-SUBNET1"
CREATE_NET2 = "neutron net-create NET20 --provider:network_type local"
CREATE_SUBNET2 = "neutron subnet-create NET20 20.1.1.0/24 --name NET2-SUBNET2"

CREATE_PORT11 = "neutron port-create NET10 --name PORT11"
CREATE_PORT12 = "neutron port-create NET20 --name PORT12"
CREATE_PORT21 = "neutron port-create NET10 --name PORT21"
CREATE_PORT22 = "neutron port-create NET20 --name PORT22"

EXPORT_IMAGE = "export IMAGE=cirros-0.3.4-x86_64-uec"

BOOT_VM11 = "nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic port-id=$(neutron port-list | grep 'PORT11' | awk '{print $2}') VM11 --availability-zone nova:compute-node1"
BOOT_VM12 = "nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic port-id=$(neutron port-list | grep 'PORT12' | awk '{print $2}') VM12 --availability-zone nova:compute-node1"
BOOT_VM21 = "nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic port-id=$(neutron port-list | grep 'PORT21' | awk '{print $2}') VM21 --availability-zone nova:compute-node2"
BOOT_VM22 = "nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic port-id=$(neutron port-list | grep 'PORT22' | awk '{print $2}') VM22 --availability-zone nova:compute-node2"

CREATE_ROUTER1 = "neutron router-create ROUTER1"
CREATE_ROUTER_IF1 = "neutron router-interface-add ROUTER1  NET1-SUBNET1"
CREATE_ROUTER_IF2 = "neutron router-interface-add ROUTER1  NET2-SUBNET2"
ADD_EXTRA_ROUTE1 = "neutron router-update ROUTER1 --routes type=dict list=true destination=40.1.1.0/24,nexthop=10.1.1.2"
ADD_EXTRA_ROUTES = "neutron router-update ROUTER1 --routes type=dict list=true destination=40.1.1.0/24,nexthop=10.1.1.2 destination=50.1.1.0/24,nexthop=20.1.1.3"
DEL_EXTRA_ROUTE =  "neutron router-update ROUTER1 --routes action=clear"

DELETE_ROUTER_IF1 = "neutron router-interface-delete ROUTER1  NET1-SUBNET1"
DELETE_ROUTER_IF2 = "neutron router-interface-delete ROUTER1  NET2-SUBNET2"
DELETE_ROUTER1 = "neutron router-delete ROUTER1"

DELETE_NET1 = "neutron net-delete NET10"
DELETE_NET2 = "neutron net-delete NET20"
DELETE_SUBNET1 = "neutron subnet-delete NET1-SUBNET1"
DELETE_SUBNET2 = "neutron subnet-delete NET2-SUBNET2"

DELETE_PORT11 = "neutron port-delete PORT11"
DELETE_PORT21 = "neutron port-delete PORT21"
DELETE_PORT12 = "neutron port-delete PORT12"
DELETE_PORT22 = "neutron port-delete PORT22"

DELETE_VM11 = "nova delete VM11"
DELETE_VM21 = "nova delete VM21"
DELETE_VM12 = "nova delete VM12"
DELETE_VM22 = "nova delete VM22"



# Vpn Service Variables
L3VPN = "vpn"
RD = ["100:1"]
IMPORT_RT = ["100:1"]
EXPORT_RT = ["100:1"]
L3VPN2 = "vpn2"
RD2 = ["100:2"]
IMPORT_RT2 = ["100:2"]
EXPORT_RT2 = ["100:2"]

RD_NEW = ["100:2"]
IMPORT_RT_NEW = ["100:2"]
EXPORT_RT_NEW = ["100:2"]
AS_NO = 100

# Datapath test variables
VM_INDX1 = 0
VM_INDX2 = 1


NS1 = "ns1"
IP_NS2 = "20.1.1.3"
IP_NS3 = "30.1.1.4"
IP_NS4 = "30.1.1.5"
COUNT = 2
PING_REGEX = '\,\s+0\%\s+packet\s+loss'

DELAY_BEFORE_PING = 180
DELAY_2_BEFORE_PING = 10

# FLOWS

TABLE17_TO_21_REGEX = "table=17.*goto_table:21"

TABLE20_REGEX = "table=20.*mpls,mpls_label=.*"
TABLE21_REGEX_1 = "table=21.*10.1.1.2.*"
TABLE21_REGEX_2 = "table=21.*10.1.1.3.*"
TABLE21_REGEX_3 = "table=21.*20.1.1.2.*"
TABLE21_REGEX_4 = "table=21.*20.1.1.3.*"
#TABLE21_REGEX_4 = "table=21.*" + ip1 + ".*"
