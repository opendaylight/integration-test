#!/bin/sh

# author__ = "Jan Medved"
# copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
# license__ = "New-style BSD"
# email__ = "jmedved@cisco.com"

# Initialize our own variables:
instances=0
resource="both"
auth=false
threads=1
requests=1000

while getopts "h?ai:n:r:t:" opt; do
    case "$opt" in
    h|\?)
        echo "This would be help"
        exit 0
        ;;
    a)  auth=true
        ;;
    i)  instances=$OPTARG
        ;;
    n)  requests=$OPTARG
        ;;
    r)  resource=$OPTARG
        ;;
    t)  threads=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "Running $instances instances, parameters:\n  resource='$resource', requests=$requests, threads=$threads"

i=0
while [  $i -lt $instances ]; do
    echo "Starting instance $i"
    let i=$i+1
    ./shard_perf_test.py --auth --resource $resource --requests $requests --threads $threads &
done

wait
echo "Done."

# End of file
