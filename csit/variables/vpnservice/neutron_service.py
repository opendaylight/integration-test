"""These Variables are used as part of Liberty openstack topology creation.

All these variable are being used as part of netvirt vpnservice
feature.

"""

__author__ = "Mahendar Yavagani"
__copyright__ = "Copyright 2016, Ericsson"
__version__ = "1.0.1"

# Nuetron Network Variables
NETWORK1 = "NET10 "
SUBNET1 = "NET1-SUBNET1"
NETWORK2 = "NET20 "
SUBNET2 = "NET2-SUBNET2"
IPSUBNET1 = "10.1.1.0/24 "
IPSUBNET2 = "20.1.1.0/24 "
PORT1 = "PORT11"
PORT2 = "PORT12"
PORT3 = "PORT21"
PORT4 = "PORT22"
VM1 = " VM11 "
VM2 = " VM12 "
VM3 = " VM21 "
VM4 = " VM22 "

ROUTER1 = "ROUTER1 "

NET_CREATE = "neutron net-create "
SUBNET_CREATE = "neutron subnet-create "
PORT_CREATE = "neutron port-create "
NET_TYPE = " --provider:network_type local"
NAME = " --name "

EXPORT_IMAGE = "export IMAGE=cirros-0.3.4-x86_64-uec"

NOVA_BOOT = "nova boot --image cirros-0.3.4-x86_64-uec --flavor m1.tiny --nic "
SEL_PORT = " port-id=$(neutron port-list | grep '"
PRINT_PORT = "' | awk '{print $2}')"
ZONE = " --availability-zone nova:"
CN1 = "OS_COMPUTE_1_IP"
CN2 = "OS_COMPUTE_2_IP"

ROUTER_CREATE = "neutron router-create "
IF_CREATE = "neutron router-interface-add "
UPDATE_RTR = "neutron router-update "
RT_OPTIONS = " --routes type=dict list=true "
EXT_RT1 = "destination=40.1.1.0/24,nexthop=10.1.1.2 "
EXT_RT2 = "destination=50.1.1.0/24,nexthop=20.1.1.3 "
RT_CLEAR = " --routes action=clear"

IF_DELETE = "neutron router-interface-delete "
ROUTER_DELETE = "neutron router-delete "

DELETE_NET = "neutron net-delete "
DELETE_SUBENT = "neutron subnet-delete "
DELETE_PORT = "neutron port-delete "
NOVA_DELETE = "nova delete "

CREATE_NET1 = NET_CREATE + NETWORK1 + NET_TYPE
CREATE_SUBNET1 = SUBNET_CREATE + NETWORK1 + IPSUBNET1 + NAME + SUBNET1
CREATE_NET2 = NET_CREATE + NETWORK2 + NET_TYPE
CREATE_SUBNET2 = SUBNET_CREATE + NETWORK2 + IPSUBNET2 + NAME + SUBNET2

CREATE_PORT11 = PORT_CREATE + NETWORK1 + NAME + PORT1
CREATE_PORT12 = PORT_CREATE + NETWORK2 + NAME + PORT2
CREATE_PORT21 = PORT_CREATE + NETWORK1 + NAME + PORT3
CREATE_PORT22 = PORT_CREATE + NETWORK2 + NAME + PORT4

BOOT_VM11 = NOVA_BOOT + SEL_PORT + PORT1 + PRINT_PORT + VM1 + ZONE + CN1
BOOT_VM12 = NOVA_BOOT + SEL_PORT + PORT2 + PRINT_PORT + VM2 + ZONE + CN1
BOOT_VM21 = NOVA_BOOT + SEL_PORT + PORT3 + PRINT_PORT + VM3 + ZONE + CN2
BOOT_VM22 = NOVA_BOOT + SEL_PORT + PORT4 + PRINT_PORT + VM4 + ZONE + CN2

CREATE_ROUTER1 = ROUTER_CREATE + ROUTER1
CREATE_ROUTER_IF1 = IF_CREATE + ROUTER1 + SUBNET1
CREATE_ROUTER_IF2 = IF_CREATE + ROUTER1 + SUBNET2
ADD_EXTRA_ROUTE1 = UPDATE_RTR + ROUTER1 + RT_OPTIONS + EXT_RT1
ADD_EXTRA_ROUTES = UPDATE_RTR + ROUTER1 + RT_OPTIONS + EXT_RT1 + EXT_RT2
DEL_EXTRA_ROUTE = UPDATE_RTR + ROUTER1 + RT_CLEAR

DELETE_ROUTER_IF1 = IF_DELETE + ROUTER1 + SUBNET1
DELETE_ROUTER_IF2 = IF_DELETE + ROUTER1 + SUBNET2
DELETE_ROUTER1 = ROUTER_DELETE + ROUTER1

DELETE_NET1 = DELETE_NET + NETWORK1
DELETE_NET2 = DELETE_NET + NETWORK2
DELETE_SUBNET1 = DELETE_SUBENT + SUBNET1
DELETE_SUBNET2 = DELETE_SUBENT + SUBNET2

DELETE_PORT11 = DELETE_PORT + PORT1
DELETE_PORT21 = DELETE_PORT + PORT2
DELETE_PORT12 = DELETE_PORT + PORT3
DELETE_PORT22 = DELETE_PORT + PORT4

DELETE_VM11 = NOVA_DELETE + VM1
DELETE_VM21 = NOVA_DELETE + VM2
DELETE_VM12 = NOVA_DELETE + VM3
DELETE_VM22 = NOVA_DELETE + VM4

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
