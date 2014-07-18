#!/usr/bin/env sh
# Helper script to run CBench tests in a loop, used for testing
# Script assumes it lives in the same dir as cbench.sh

# Exit codes
EX_USAGE=64
EX_OK=0

usage()
{
    # Print usage message
    cat << EOF
Usage $0 [options]

Run CBench against OpenDaylight in a loop.

OPTIONS:
    -h Show this help message
    -l Loop CBench runs without restarting ODL
    -r Loop CBench runs, restart ODL between runs
    -t <time> Run CBench for a given number of minutes
    -p <processors> Pin ODL to given number of processors
EOF
}

start_odl()
{
    # Starts ODL, optionally pinning it to a given number of processors
    if [ -z $processors ]; then
        # Start ODL, don't pass processor info
        echo "Starting ODL, not passing processor info"
        ./cbench.sh -o
    else
        # Start ODL, pinning it to given number of processors
        echo "Pinning ODL to $processors processor(s)"
        ./cbench.sh -p $processors -o
    fi
}

run_cbench()
{
    # Run CBench against ODL, optionally passing a CBench run time
    if [ -z $run_time ]; then
        # Flag means run CBench
        echo "Running CBench, not passing run time info"
        ./cbench.sh -r
    else
        # Flags mean use $run_time CBench runs, run CBench
        echo "Running CBench with $run_time minute(s) run time"
        ./cbench.sh -t $run_time -r
    fi
}

loop_no_restart()
{
    # Repeatedly run CBench against ODL without restarting ODL
    echo "Looping CBench against ODL without restarting ODL"
    while :; do
        start_odl
        run_cbench
    done
}

loop_with_restart()
{
    # Repeatedly run CBench against ODL, restart ODL between runs 
    echo "Looping CBench against ODL, restarting ODL each run"
    while :; do
        start_odl
        run_cbench
        # Stop ODL
        ./cbench.sh -k
    done
}

# If executed with no options
if [ $# -eq 0 ]; then
    usage
    exit $EX_USAGE
fi

while getopts ":hlp:rt:" opt; do
    case "$opt" in
        h)
            # Help message
            usage
            exit $EX_OK
            ;;
        l)
            # Loop without restarting ODL between CBench runs
            loop_no_restart
            ;;
        p)
            # Pin a given number of processors
            # Note that this option must be given before -o (start ODL)
            processors=${OPTARG}
            if [ $processors -lt 1 ]; then
                echo "Can't pin ODL to less than one processor"
                exit $EX_USAGE
            fi
            ;;
        r)
            # Restart ODL between each CBench run
            loop_with_restart
            ;;
        t)
            # Set length of CBench run in minutes
            run_time=${OPTARG}
            ;;
        *)
            usage
            exit $EX_USAGE
    esac
done
