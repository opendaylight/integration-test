#!/bin/sh


#NS1
sudo ip netns add ns1
sudo ip link add tap-port-1 type veth peer name tap79ad0001-19
sudo ovs-vsctl add-port BR1 tap79ad0001-19
sudo ip link set tap-port-1 netns ns1
sudo ip netns exec ns1 ip link set dev tap-port-1 up
sudo ip link set dev tap79ad0001-19 up
sudo ip netns exec ns1 ifconfig tap-port-1 20.1.1.2 netmask 255.255.255.0
sudo ip netns exec ns1 ifconfig tap-port-1 hw ether 00:16:3E:19:F7:8B
sudo ip netns exec ns1 ip link set dev lo up
sudo ip netns exec ns1 ip route add default via 20.1.1.1
#NS2
sudo ip netns add ns2
sudo ip link add tap-port-2 type veth peer name tap79ad0002-19
sudo ovs-vsctl add-port BR1 tap79ad0002-19
sudo ip link set tap-port-2 netns ns2
sudo ip netns exec ns2 ip link set dev tap-port-2 up
sudo ip link set dev tap79ad0002-19 up
sudo ip netns exec ns2 ifconfig tap-port-2 20.1.1.3 netmask 255.255.255.0
sudo ip netns exec ns2 ifconfig tap-port-2 hw ether 00:16:3E:BB:9B:0F
ip netns exec ns2 ip link set dev lo up
sudo ip netns exec ns2 ip route add default via 20.1.1.1

sudo ip netns
sudo ip netns exec ns1 ip link
sudo ip netns exec ns1 ifconfig
sudo ip netns exec ns2 ip link
sudo ip netns exec ns2 ifconfig
