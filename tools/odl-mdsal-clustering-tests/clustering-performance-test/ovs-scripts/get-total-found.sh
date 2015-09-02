#!/bin/bash

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

ECHO=`which echo`

TOTAL=0
i=1

while true;
do
    CUR=$((`./OVS-dump-flows.sh.13 s$i 2> /dev/null |  grep -v "flags=\[more\]" | wc -l` - 1))

    if [ "$CUR" == "-1" ];
    then 
	break
    else
        printf "Switch s%d: %d flows\n" $i $CUR
        TOTAL=$(($TOTAL + $CUR))
        i=$(($i + 1))
    fi
done

printf "\nTotal: %d\n\n" $TOTAL