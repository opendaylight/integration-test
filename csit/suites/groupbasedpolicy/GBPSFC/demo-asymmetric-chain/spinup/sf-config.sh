#!/usr/bin/env bash

set -e
hostnum=${HOSTNAME#"gbpsfc"}
sw="sw$hostnum"

if [ "$hostnum" -eq "3" ]; then
    TUNNEL=0xC0A83247
elif [ "$hostnum" -eq "5" ]; then
    TUNNEL=0xC0A83249
else
    echo "Invalid SF for this demo";
    exit
fi

sudo ovs-vsctl add-br $sw
sudo ovs-vsctl add-port $sw $sw-vxlangpe-0 -- set interface $sw-vxlangpe-0 type=vxlan options:remote_ip=flow options:dst_port=6633 options:nshc1=flow options:nshc2=flow options:nshc3=flow options:nshc4=flow options:nsp=flow options:nsi=flow options:key=flow
