#! /bin/bash

sudo brctl addbr br1
sudo brctl addbr br2
sudo brctl addbr br3
sudo ip link set br1 up
sudo ip link set br2 up
sudo ip link set br3 up
sudo service docker start
sudo docker network create --subnet=10.100.0.0/24 net1
br1_name=$(ifconfig | grep br- | cut -d: -f1)
sudo docker pull alagalah/odlpoc_ovs230
sudo docker run -dit --net net1 --ip $1 -h docker1 --name docker1 docker.io/alagalah/odlpoc_ovs230:latest
docker_if=$(ifconfig | grep veth | cut -d: -f1)
sudo ip link set $docker_if down
sudo ip link set $docker_if name docker1
sudo ip link set docker1 up
sudo brctl delif $br1_name docker1
sudo brctl addif br1 docker1
sudo docker run -dit --net net1 --ip $2 -h docker2 --name docker2 docker.io/alagalah/odlpoc_ovs230:latest
docker_if=$(ifconfig | grep veth | cut -d: -f1)
sudo ip link set $docker_if down
sudo ip link set $docker_if name docker2
sudo ip link set docker2 up
sudo brctl delif $br1_name docker2
sudo brctl addif br2 docker2
sudo ip link set $br1_name down
sudo docker network create --subnet=10.101.0.0/24 net2
br2_name=$(ifconfig | grep br- | cut -d: -f1)
sudo docker run -dit --net net2 --ip $3 -h docker3 --name docker3 docker.io/alagalah/odlpoc_ovs230:latest
docker_if=$(ifconfig | grep veth | cut -d: -f1)
sudo ip link set $docker_if down
sudo ip link set $docker_if name docker3
sudo ip link set docker3 up
sudo brctl delif $br2_name docker3
sudo brctl addif br3 docker3
sudo ip link set $br2_name down
