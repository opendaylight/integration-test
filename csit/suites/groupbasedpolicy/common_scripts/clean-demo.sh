#!/usr/bin/env bash

set -e

sw=$(sudo ovs-vsctl show | egrep -E 'Bridge.*sw' | awk '{print $2}' | sed -e 's/^"//'  -e 's/"$//')

sudo ovs-vsctl del-br $sw;
sudo ovs-vsctl del-manager;
sudo /vagrant/vmclean.sh