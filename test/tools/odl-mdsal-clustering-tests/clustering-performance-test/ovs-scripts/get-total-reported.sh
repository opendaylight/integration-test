#!/bin/bash

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

ECHO=`which echo`
TOTAL=0
dname=`dirname $0`
i=1

while true;
do
    CURSTRING=`${dname}/OVS-dump-tables.sh.13 s$i 2> /dev/null | grep -v "active=0" | grep "active"`

    if [ "$CURSTRING" = "" ];
    then
        break
    else
        CUR=`echo $CURSTRING | awk -F'[:=,]' '{print $3}'`
        TOTAL=$(($TOTAL + $CUR))
        printf "Switch s%d:\n" $i
        echo "  Table " $CURSTRING
        i=$(($i + 1))
    fi
done

printf "\nTotal: %d\n\n" $TOTAL

