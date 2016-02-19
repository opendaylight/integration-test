# Environment Variables
USER_HOME = "/home/mininet"

# Nuetron Network Variables
NEUTRON_NETWORK1 = "mynetwork1"
NEUTRON_SUBNET1 = "mysubnet1"
NEUTRON_NETWORK2 = "mynetwork2"
NEUTRON_SUBNET2 = "mysubnet2"
NEUTRON_IPSUBNET1 = "20.1.1.0/24"
NEUTRON_IPSUBNET2 = "30.1.1.0/24"
NEUTRON_PORT1 = "myport1"
NEUTRON_PORT2 = "myport2"
NEUTRON_PORT3 = "myport3"
NEUTRON_PORT4 = "myport4"
NEUTRON_PORT1_MAC = "00:16:3E:19:F7:8B"
NEUTRON_PORT2_MAC = "00:16:3E:BB:9B:0F"
NEUTRON_PORT3_MAC = "00:16:3E:92:F5:F8"
NEUTRON_PORT4_MAC = "00:16:3E:19:57:58"

# Vpn Service Variables
TUNNEL_NAME = "gretunnel2"
L3VPN = "vpn"
RD = ["100:1"]
IMPORT_RT = ["100:1"]
EXPORT_RT = ["100:1"]
RD_NEW = ["100:2"]
IMPORT_RT_NEW = ["100:2"]
EXPORT_RT_NEW = ["100:2"]
AS_NO = 100

# Datapath test variables
NS1 = "ns1"
IP_NS2 = "20.1.1.3"
IP_NS3 = "30.1.1.4"
IP_NS4 = "30.1.1.5"
COUNT = 3
PING_REGEX = '\,\s+0\%\s+packet\s+loss'

DELAY_BEFORE_PING = 2
