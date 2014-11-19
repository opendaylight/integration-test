#!/usr/bin/env sh
# Helper script to run WCBench tests in a loop, used for testing
# Script assumes it lives in the same dir as wcbench.sh

# Exit codes
EX_USAGE=64
EX_OK=0

# Output verbose debug info (true) or not (anything else)
VERBOSE=false

###############################################################################
# Prints usage message
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
###############################################################################
usage()
{
    cat << EOF
Usage $0 [options]

Run WCBench against OpenDaylight in a loop.

OPTIONS:
    -h Show this help message
    -v Output verbose debug info
    -l Loop WCBench runs without restarting ODL
    -r Loop WCBench runs, restart ODL between runs
    -t <time> Run WCBench for a given number of minutes
    -p <processors> Pin ODL to given number of processors
EOF
}

###############################################################################
# Starts ODL, optionally pinning it to a given number of processors
# Globals:
#   processors
#   VERBOSE
# Arguments:
#   None
# Returns:
#   WCBench exit status
###############################################################################
start_odl()
{
    if "$VERBOSE" = true; then
        if [ -z $processors ]; then
            # Start ODL, don't pass processor info
            echo "Starting ODL, not passing processor info"
            ./wcbench.sh -vo
        else
            # Start ODL, pinning it to given number of processors
            echo "Pinning ODL to $processors processor(s)"
            ./wcbench.sh -vp $processors -o
        fi
    else
        if [ -z $processors ]; then
            # Start ODL, don't pass processor info
            echo "Starting ODL, not passing processor info"
            ./wcbench.sh -o
        else
            # Start ODL, pinning it to given number of processors
            echo "Pinning ODL to $processors processor(s)"
            ./wcbench.sh -p $processors -o
        fi
    fi
}

###############################################################################
# Run WCBench against ODL, optionally passing a WCBench run time
# Globals:
#   run_time
#   VERBOSE
# Arguments:
#   None
# Returns:
#   WCBench exit status
###############################################################################
run_wcbench()
{
    if "$VERBOSE" = true; then
        if [ -z $run_time ]; then
            # Flag means run WCBench
            echo "Running WCBench, not passing run time info"
            ./wcbench.sh -vr
        else
            # Flags mean use $run_time WCBench runs, run WCBench
            echo "Running WCBench with $run_time minute(s) run time"
            ./wcbench.sh -vt $run_time -r
        fi
    else
        if [ -z $run_time ]; then
            # Flag means run WCBench
            echo "Running WCBench, not passing run time info"
            ./wcbench.sh -r
        else
            # Flags mean use $run_time WCBench runs, run WCBench
            echo "Running WCBench with $run_time minute(s) run time"
            ./wcbench.sh -t $run_time -r
        fi
    fi
}

###############################################################################
# Repeatedly run WCBench against ODL without restarting ODL
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Exit status of run_wcbench
###############################################################################
loop_no_restart()
{
    echo "Looping WCBench against ODL without restarting ODL"
    while :; do
        start_odl
        run_wcbench
    done
}

###############################################################################
# Repeatedly run WCBench against ODL, restart ODL between runs
# Globals:
#   VERBOSE
# Arguments:
#   None
# Returns:
#   WCBench exit status
###############################################################################
loop_with_restart()
{
    echo "Looping WCBench against ODL, restarting ODL each run"
    while :; do
        start_odl
        run_wcbench
        # Stop ODL
        if "$VERBOSE" = true; then
            ./wcbench.sh -vk
        else
            ./wcbench.sh -k
        fi
    done
}

# If executed with no options
if [ $# -eq 0 ]; then
    usage
    exit $EX_USAGE
fi

# Used to output help if no valid action results from arguments
action_taken=false

# Parse options given from command line
while getopts ":hvlp:rt:" opt; do
    case "$opt" in
        h)
            # Help message
            usage
            exit $EX_OK
            ;;
        v)
            # Output debug info verbosely
            VERBOSE=true
            ;;
        l)
            # Loop without restarting ODL between WCBench runs
            loop_no_restart
            action_taken=true
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
            # Restart ODL between each WCBench run
            loop_with_restart
            action_taken=true
            ;;
        t)
            # Set length of WCBench run in minutes
            run_time=${OPTARG}
            ;;
        *)
            # Print usage message
            usage
            exit $EX_USAGE
    esac
done

# Output help message if no valid action was taken
if ! "$action_taken" = true; then
    usage
    exit $EX_USAGE
fi
