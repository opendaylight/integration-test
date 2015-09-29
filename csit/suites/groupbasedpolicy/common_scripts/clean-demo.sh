#!/usr/bin/env bash

set -e

sw=$(sudo ovs-vsctl show | egrep -E 'Bridge.*sw' | awk '{print $2}' | sed -e 's/^"//'  -e 's/"$//')
if [ "$sw" ]
then
    sudo ovs-vsctl del-br $sw
fi
sudo ovs-vsctl del-manager;

docker stop -t=1 $(docker ps -a -q) > /dev/null 2>&1
docker rm $(docker ps -a -q) > /dev/null 2>&1

sudo /etc/init.d/openvswitch-switch stop > /dev/null
sudo rm /etc/openvswitch/conf.db > /dev/null
sudo /etc/init.d/openvswitch-switch start > /dev/null