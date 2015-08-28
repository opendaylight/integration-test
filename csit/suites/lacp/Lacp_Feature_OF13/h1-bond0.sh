sudo modprobe bonding
sudo ip link add bond0 type bond
sudo ip link set bond0 address 02:01:02:03:04:08

sudo ip link set h1-eth0 down
sudo ip link set h1-eth0 address 00:00:00:00:00:11
sudo ip link set h1-eth0 master bond0
sudo ip link set h1-eth1 down
sudo ip link set h1-eth1 address 00:00:00:00:00:12
sudo ip link set h1-eth1 master bond0

sudo ip addr add 10.1.1.1/8 dev bond0
sudo ip addr del 10.0.0.1/8 dev h1-eth0
sudo ip link set bond0 up

sudo ifconfig

sudo cat /proc/net/bonding/bond0
