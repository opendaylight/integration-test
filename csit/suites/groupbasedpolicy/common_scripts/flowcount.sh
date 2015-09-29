#!/usr/bin/env bash

: ' Returns ovs-ofctl dump-flows command output for a table
    specified in argument by table ID and ovs-ofctl dump-groups
    output. If no table specified in args, the sum of flows for
    each table is returned in the output.
'

set -e

sw=$(sudo ovs-vsctl show | egrep -E 'Bridge.*sw' | awk '{print $2}' | sed  -e 's/"//g')
if [ "$1" ]
then
        echo "GROUPS:";
        ovs-ofctl dump-groups $sw -OOpenFlow13;
        echo;echo "FLOWS:";ovs-ofctl dump-flows $sw -OOpenFlow13 table=$1 --rsort=priority
    echo
    printf "Flow count: "
    echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=$1 | wc -l)-1))
else
        printf "No table entered. $sw flow count: ";
        echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 | wc -l)-1))
        printf "\nTable0: PortSecurity:  "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=0| wc -l)-1))
        printf "\nTable1: IngressNat:    "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=1| wc -l)-1))
        printf "\nTable2: SourceMapper:  "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=2| wc -l)-1))
        printf "\nTable3: DestMapper:    "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=3| wc -l)-1))
        printf "\nTable4: PolicyEnforcer:"; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=4| wc -l)-1))
        printf "\nTable5: EgressNAT:     "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=5| wc -l)-1))
        printf "\nTable6: External:      "; echo $(($(ovs-ofctl dump-flows $sw -OOpenFlow13 table=6| wc -l)-1))
fi

