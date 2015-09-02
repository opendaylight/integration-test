#!/bin/bash

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

# Init our own program name
program_name=$0

# Command to invoke
CMD="./flow_config_blaster.py"

# Default number of $CMD instances
instances=1

# Default parameters for $CMD
no_delete=false
auth=false
threads=1
flows=1000
cycles=1
odl_host=127.0.0.1
odl_port=8181

function usage {
    echo "usage: $program_name [-h?an] [-i instances] [-c cycles] [-f flows] [-t threads] [-o odl_host] [-p odl_port]"
    echo "	-h|?          print this message"
    echo "	-a            use default authentication ('admin/admin')"
    echo "	-n            use the 'no-delete' flag in '$CMD'"
    echo "	-i instances  number of '$CMD' instances to spawn"
    echo "	-c cycles     number of cycles"
    echo "	-f flows      number of flows"
    echo "	-o odl_host   IP Address of the ODL controller"
    echo "	-p odl_port   RESTCONF port in the ODL controller"
    echo "	-t threads    number of threads"
    echo "Optional flags/arguments [acfnopt] are passed to '$CMD'."
}

# Initialize our own variables:


while getopts "h?ac:f:i:no:p:t:" opt; do
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
    o)  odl_host=$OPTARG
        ;;
    p)  odl_port=$OPTARG
        ;;
    t)  threads=$OPTARG
        ;;
    esac
done

echo "*** Creating $instances instance(s) of '$CMD' ***"
echo ""

let "flows_per_instance=$cycles * $flows * $threads"
i=0

START_TIME=$SECONDS
while [  $i -lt $instances ]; do
    let "startflow=$flows_per_instance * $i"

    CMD_STRING=$(printf '%s --cycles %s --flows %s --threads %s ' $CMD $cycles $flows $threads)
    CMD_STRING+=$(printf ' --host %s --port %s --startflow %s' $odl_host $odl_port $startflow)
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

echo "Done."

if [ "$ELAPSED_TIME" -gt 0 ] ; then
    let "rate=($flows_per_instance * $instances)/$ELAPSED_TIME"
    echo "Measured rate: $rate"
    echo "Measured time: $ELAPSED_TIME"
fi