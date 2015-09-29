#!/usr/bin/env bash

set -e
SFF_IP=$1
SFF_HEX=$(printf '%02X' ${SFF_IP//./ })
sw=$(sudo ovs-vsctl show | egrep -E 'Bridge.*sw' | awk '{print $2}' | sed -e 's/^"//'  -e 's/"$//')

if [ $sw = "sw3" ] || [ $sw = "sw5" ] ; then
    # delete NORMAL, if present
    sudo ovs-ofctl --strict del-flows $sw priority=0
    sudo ovs-ofctl add-flow $sw "priority=1000,nsi=255 actions=move:NXM_NX_NSH_C1[]->NXM_NX_NSH_C1[],move:NXM_NX_NSH_C2[]->NXM_NX_NSH_C2[],move:NXM_NX_TUN_ID[0..31]->NXM_NX_TUN_ID[0..31],load:$SFF_HEX->NXM_NX_TUN_IPV4_DST[],set_nsi:254,IN_PORT" -OOpenFlow13
    sudo ovs-ofctl add-flow $sw "priority=1000,nsi=254 actions=move:NXM_NX_NSH_C1[]->NXM_NX_NSH_C1[],move:NXM_NX_NSH_C2[]->NXM_NX_NSH_C2[],move:NXM_NX_TUN_ID[0..31]->NXM_NX_TUN_ID[0..31],load:$SFF_HEX->NXM_NX_TUN_IPV4_DST[],set_nsi:253,IN_PORT" -OOpenFlow13
else
    echo "Invalid SF for this demo";
    exit
fi
