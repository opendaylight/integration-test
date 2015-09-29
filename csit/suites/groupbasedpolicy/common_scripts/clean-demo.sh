#!/usr/bin/env bash

set -e

sw=$(sudo ovs-vsctl show | egrep -E 'Bridge.*sw' | awk '{print $2}' | sed -e 's/^"//'  -e 's/"$//')

sudo ovs-vsctl del-manager;
docker stop -t=1 $(docker ps -a -q) > /dev/null 2>&1
docker rm $(docker ps -a -q) > /dev/null 2>&1

if [ "$sw" ]
then
    sudo ovs-vsctl del-br $sw
fi

