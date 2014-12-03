#!/bin/bash

ECHO=`which echo`

TOTAL=0

i=1

while true;
do
    CUR=$((`./OVS-dump-flows.sh.13 s$i 2> /dev/null |wc -l` - 1))

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