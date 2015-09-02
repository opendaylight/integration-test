#!/bin/bash

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

# Command to invoke
CMD="./shard_perf_test.py"

# Default number od $CMD instances to start
instances=1

# Default parameters for $CMD
resource="both"
auth=false
threads=1
requests=1000
odl_host=127.0.0.1
odl_port=8181

function usage {
    echo "usage: $programname [-h?an] [-i instances] [-c cycles] [-f flows] [-t threads] [-o odl_host] [-p odl_port]"
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


while getopts "h?ai:n:o:p:r:t:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 1
        ;;
    a)  auth=true
        ;;
    i)  instances=$OPTARG
        ;;
    n)  requests=$OPTARG
        ;;
    r)  resource=$OPTARG
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

i=0
START_TIME=$SECONDS

while [  $i -lt $instances ]; do
    CMD_STRING=$(printf '%s --resource %s --requests %s --threads %s' $CMD $resource $requests $threads)
    CMD_STRING+=$(printf ' --host %s --port %s' $odl_host $odl_port)
    if [ "$auth" = true ] ; then
        CMD_STRING+=' --auth'
    fi
    echo "Starting instance $i: '$CMD_STRING'"
    $CMD_STRING &

    let i=$i+1
done

wait
ELAPSED_TIME=$(($SECONDS - $START_TIME))

echo "Done."

if [ "$ELAPSED_TIME" -gt 0 ] ; then
    let "rate=(threads * $requests * $instances)/$ELAPSED_TIME"
    echo "Measured rate: $rate"
    echo "Measured time: $ELAPSED_TIME"
fi