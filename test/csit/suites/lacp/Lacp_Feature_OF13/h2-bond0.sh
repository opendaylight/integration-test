modprobe bonding
ip link add bond0 type bond
ip link set bond0 address 02:01:02:03:04:09

ip link set h2-eth0 down
ip link set h2-eth0 address 00:00:00:00:00:22
ip link set h2-eth0 master bond0
ip link set h2-eth1 down
ip link set h2-eth1 address 00:00:00:00:00:23
ip link set h2-eth1 master bond0

ip addr add 10.1.1.2/8 dev bond0
ip addr del 10.0.0.2/8 dev h2-eth0
ip link set bond0 up

ifconfig

cat /proc/net/bonding/bond0

