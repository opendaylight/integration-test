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

PING_NS2 = "sudo /sbin/ip netns exec ns1 ping 20.1.1.3 -c 3"
PING_NS3 = "sudo /sbin/ip netns exec ns1 ping 30.1.1.4 -c 3"
PING_NS4 = "sudo /sbin/ip netns exec ns1 ping 30.1.1.5 -c 3"


PING_REGEX = '\,\s+0\%\s+packet\s+loss'

DELAY_BEFORE_PING = 2


create_ns_setup_dpn_1 = """

sudo /sbin/ip netns add ns1
sudo /sbin/ip link add tap-port-1 type veth peer name tap79ad0001-19
sudo ovs-vsctl add-port BR1 tap79ad0001-19
sudo /sbin/ip link set tap-port-1 netns ns1
sudo /sbin/ip netns exec ns1 ip link set dev tap-port-1 up
sudo /sbin/ip link set dev tap79ad0001-19 up
sudo /sbin/ip netns exec ns1 ifconfig tap-port-1 20.1.1.2 netmask 255.255.255.0
sudo /sbin/ip netns exec ns1 ifconfig tap-port-1 hw ether 00:16:3E:19:F7:8B
sudo /sbin/ip netns exec ns1 ip link set dev lo up
sudo /sbin/ip netns exec ns1 ip route add default via 20.1.1.1
sudo /sbin/ip netns add ns2
sudo /sbin/ip link add tap-port-2 type veth peer name tap79ad0002-19
sudo ovs-vsctl add-port BR1 tap79ad0002-19
sudo /sbin/ip link set tap-port-2 netns ns2
sudo /sbin/ip netns exec ns2 ip link set dev tap-port-2 up
sudo /sbin/ip link set dev tap79ad0002-19 up
sudo /sbin/ip netns exec ns2 ifconfig tap-port-2 20.1.1.3 netmask 255.255.255.0
sudo /sbin/ip netns exec ns2 ifconfig tap-port-2 hw ether 00:16:3E:BB:9B:0F
ip netns exec ns2 ip link set dev lo up
sudo /sbin/ip netns exec ns2 ip route add default via 20.1.1.1

"""

create_ns_setup_dpn_2 = """

sudo /sbin/ip netns add ns3
sudo /sbin/ip link add tap-port-3 type veth peer name tap79ad0003-19
sudo ovs-vsctl add-port BR2 tap79ad0003-19
sudo /sbin/ip link set tap-port-3 netns ns3
sudo /sbin/ip netns exec ns3 ip link set dev tap-port-3 up
sudo /sbin/ip link set dev tap79ad0003-19 up
sudo /sbin/ip netns exec ns3 ifconfig tap-port-3 30.1.1.4 netmask 255.255.255.0
sudo /sbin/ip netns exec ns3 ifconfig tap-port-3 hw ether 00:16:3E:92:F5:F8
sudo /sbin/ip netns exec ns3 ip link set dev lo up
sudo /sbin/ip netns exec ns3 ip route add default via 30.1.1.1
#NS4
sudo /sbin/ip netns add ns4
sudo /sbin/ip link add tap-port-4 type veth peer name tap79ad0004-19
sudo ovs-vsctl add-port BR2 tap79ad0004-19
sudo /sbin/ip link set tap-port-4 netns ns4
sudo /sbin/ip netns exec ns4 ip link set dev tap-port-4 up
sudo /sbin/ip link set dev tap79ad0004-19 up
sudo /sbin/ip netns exec ns4 ifconfig tap-port-4 30.1.1.5 netmask 255.255.255.0
sudo /sbin/ip netns exec ns4 ifconfig tap-port-4 hw ether 00:16:3E:19:57:58
sudo /sbin/ip netns exec ns4 ip link set dev lo up
sudo /sbin/ip netns exec ns4 ip route add default via 30.1.1.1

"""

delete_ns_setup_dpn_1 = """

sudo /sbin/ip netns delete ns1
sudo /sbin/ip netns delete ns2

"""

delete_ns_setup_dpn_2 = """

sudo /sbin/ip netns delete ns3
sudo /sbin/ip netns delete ns4

"""
