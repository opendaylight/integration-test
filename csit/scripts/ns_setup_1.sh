#!/bin/sh

#NS3
sudo ip netns add ns3
sudo ip link add tap-port-3 type veth peer name tap79ad0003-19
sudo ovs-vsctl add-port BR2 tap79ad0003-19
sudo ip link set tap-port-3 netns ns3
sudo ip netns exec ns3 ip link set dev tap-port-3 up
sudo ip link set dev tap79ad0003-19 up
sudo ip netns exec ns3 ifconfig tap-port-3 30.1.1.4 netmask 255.255.255.0
sudo ip netns exec ns3 ifconfig tap-port-3 hw ether 00:16:3E:92:F5:F8
sudo ip netns exec ns3 ip link set dev lo up
sudo ip netns exec ns3 ip route add default via 30.1.1.1
#NS4
sudo ip netns add ns4
sudo ip link add tap-port-4 type veth peer name tap79ad0004-19
sudo ovs-vsctl add-port BR2 tap79ad0004-19
sudo ip link set tap-port-4 netns ns4
sudo ip netns exec ns4 ip link set dev tap-port-4 up
sudo ip link set dev tap79ad0004-19 up
sudo ip netns exec ns4 ifconfig tap-port-4 30.1.1.5 netmask 255.255.255.0
sudo ip netns exec ns4 ifconfig tap-port-4 hw ether 00:16:3E:19:57:58
sudo ip netns exec ns4 ip link set dev lo up
sudo ip netns exec ns4 ip route add default via 30.1.1.1

sudo ip netns
sudo ip netns exec ns3 ip link
sudo ip netns exec ns3 ifconfig
sudo ip netns exec ns4 ip link
sudo ip netns exec ns4 ifconfig

