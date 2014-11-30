#!/bin/bash

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

CMD="./flow_config_blaster.py"
programname=$0

function usage {
    echo "usage: $programname [-h?an] [-i instances] [-c cycles] [-f flows] [- threads]"
    echo "	-h|?          print this message"
    echo "	-a            use default authentication ('admin/admin')"
    echo "	-n            use the 'no-delete' flag in '$CMD'"
    echo "	-i instances  number of '$CMD' instances to spawn"
    echo "	-c cycles     number of cycles in '$CMD'"
    echo "	-f flows      number of flows in '$CMD'"
    echo "	-t threads    number of threads in '$CMD'"
}

# Initialize our own variables:

instances=1
no_delete=false
auth=false
threads=1
flows=1000
cycles=1

while getopts "h?ac:f:i:nt:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 1
        ;;
    a)  auth=true
        ;;
    c)  cycles=$OPTARG
        ;;
    f)  flows=$OPTARG
        ;;
    i)  instances=$OPTARG
        ;;
    n)  no_delete=true
        ;;
    t)  threads=$OPTARG
        ;;
    esac
done

echo "Running $instances instance(s), parameters:\n  flows='flows', threads=$threads, cycles=$cycles, \
no-delete='$no_delete', auth='$auth'"


let "flows_per_instance=$cycles * $flows * $threads"

printf "FPI: %d\n" $flows_per_instance

i=0
START_TIME=$SECONDS
while [  $i -lt $instances ]; do
    let "startflow=$flows_per_instance * $i"

    CMD_STRING=$(printf '%s --cycles %s --flows %s --threads %s --startflow %s' $CMD $cycles $flows $threads $startflow)
    if [ "$auth" = true ] ; then
        CMD_STRING+=' --auth'
    fi
    if [ "$no_delete" = true ] ; then
        CMD_STRING+=' --no-delete'
    fi

    echo "Starting instance $i: '$CMD_STRING'"
    let i=$i+1
    $CMD_STRING &
done

wait
ELAPSED_TIME=$(($SECONDS - $START_TIME))

let "rate=($flows_per_instance * $instances)/$ELAPSED_TIME"
echo "Done."
echo "Measured rate: $rate"
echo "Measured time: $ELAPSED_TIME"

# End of file
