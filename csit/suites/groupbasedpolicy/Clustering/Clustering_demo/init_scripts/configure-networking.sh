#! /bin/bash

sudo systemctl stop firewalld.service
sudo /sbin/sysctl -w net.ipv4.ip_forward=1
sudo modprobe ip_gre
sudo ip tunnel add tun0 mode gre remote $2 local $1
sudo ip link set tun0 up
sudo ip address add $3 dev tun0
if [ -n "$4" -a -n "$5" ]; then
  sudo ip tunnel add tun1 mode gre remote $4 local $1
  sudo ip link set tun1 up
  sudo ip address add $5 dev tun1;
fi