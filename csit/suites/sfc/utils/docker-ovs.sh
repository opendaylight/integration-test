#!/bin/bash
# Copyright (C) 2014 Nicira, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# BASED ON https://github.com/openvswitch/ovs/blob/master/utilities/ovs-docker
# MODIFIED

set -o xtrace
#set -e #Exit script if a command fails

# Check for programs we'll need.
search_path () {
    save_IFS=$IFS
    IFS=:
    for dir in $PATH; do
        IFS=$save_IFS
        if test -x "$dir/$1"; then
            return 0
        fi
    done
    IFS=$save_IFS
    echo >&2 "$0: $1 not found in \$PATH, please install and try again"
    exit 1
}

clean_iptables () {
    sudo iptables -F
    sudo iptables -t nat -F
}

ovs_vsctl () {
    sudo ovs-vsctl --timeout=60 "$@"
}

d_ovs_vsctl () {
    CONTAINER="$1"
    shift
    sudo docker exec "$CONTAINER" ovs-vsctl --timeout=60 "$@"
}

create_netns_link () {
    sudo mkdir -p /var/run/netns
    if [ ! -e /var/run/netns/"$PID" ]; then
        sudo ln -s /proc/"$PID"/ns/net /var/run/netns/"$PID"
        trap 'delete_netns_link' 0
        for signal in 1 2 3 13 14 15; do
            trap 'delete_netns_link; trap - $signal; kill -$signal $$' $signal
        done
    fi
}

delete_netns_link () {
    sudo rm -f /var/run/netns/"$PID"
}

connect_namespace_to_container () {

    NAMESPACE="$1"
    CONTAINER="$2"

    if [ -z "$NAMESPACE" ] || [ -z "$CONTAINER" ]; then
        echo >&2 "$UTIL add-port: not enough arguments (use --help for help)"
        exit 1
    fi

    shift 2
    while [ $# -ne 0 ]; do
        case $1 in
            --ipaddress=*)
                ADDRESS=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            --macaddress=*)
                MACADDRESS=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            *)
                echo >&2 "$UTIL add-port: unknown option \"$1\""
                exit 1
                ;;
        esac
    done

    if PID=`sudo docker inspect -f '{{.State.Pid}}' "$CONTAINER"`; then :; else
        echo >&2 "$UTIL: Failed to get the PID of the container"
        exit 1
    fi

    create_netns_link

    CONTAINER_IF="v-$NAMESPACE"
    NAMESPACE_IF="v-${CONTAINER:0:12}"

    # Create namespace
    if [ -z `sudo ip netns list | grep "$NAMESPACE"` ]; then
         sudo ip netns add "$NAMESPACE"
    fi

    # Create a veth pair in namespace.
    sudo ip netns exec "$NAMESPACE" ip link add "$NAMESPACE_IF" type veth peer \
       name "$CONTAINER_IF"
    sudo ip netns exec "$NAMESPACE" ip link set dev "$NAMESPACE_IF" up

    # Move one side to container namespace.
    sudo ip netns exec "$NAMESPACE" ip link set dev "$CONTAINER_IF" netns "$PID"
    sudo ip netns exec "$PID" ip link set dev "$CONTAINER_IF" up

    # And put it in integration bridge
    d_ovs_vsctl "$CONTAINER" add-port br-int "$CONTAINER_IF"

    if [ -n "$ADDRESS" ]; then
        sudo ip netns exec "$NAMESPACE" ip addr add "$ADDRESS" dev "$NAMESPACE_IF"
    fi

    if [ -n "$MACADDRESS" ]; then
        sudo ip netns exec "$NAMESPACE" ip link set dev "$NAMESPACE_IF" \
           address "$MACADDRESS"
    fi

    delete_netns_link
}

spawn_node () {
    NODE="$1"
    TUN="$2"

    if [ -z `sudo docker images | awk '/^ovs-docker/ {print $1}'` ]; then
        echo "$UTIL: Docker image ovs-docker does not exist, creating..."
        sudo docker build -t ovs-docker .
    fi

    CONTAINER=`sudo docker run -itd --privileged --cap-add ALL --name=ovs-node-"$NODE" ovs-docker`

    if [ $? -ne 0 ]; then
       echo >&2 "$UTIL: Failed to start container $NODE"
       exit 1
    fi

    STATUS=""
    while [ "$STATUS" != "EXITED" ]; do
       STATUS=`sudo docker exec "$CONTAINER" supervisorctl status configure-ovs |\
          awk '{print $2}'`
    done
    CONTAINER_GW=`sudo docker inspect -f '{{ .NetworkSettings.Gateway }}' "$CONTAINER"`
    CONTAINER_IP=`sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' "$CONTAINER"`

    # Create a container bridge as integration for all guests
    if d_ovs_vsctl "$CONTAINER" br-exists br-int; then :; else
        d_ovs_vsctl "$CONTAINER" add-br br-int
        d_ovs_vsctl "$CONTAINER" add-port br-int patch-tun -- \
           set interface patch-tun type=patch option:peer=patch-int
    fi


    # Create a container bridge as endpoint for all tunnels
    if d_ovs_vsctl "$CONTAINER" br-exists br-tun; then :; else
        d_ovs_vsctl "$CONTAINER" add-br br-tun
        d_ovs_vsctl "$CONTAINER" add-port br-tun patch-int -- \
           set interface patch-int type=patch option:peer=patch-tun
    fi

    # Setup the tunnel
    if [ "$TUN" == "vxlan" ]; then
        TUN_OPT="type=vxlan"
    elif [ "$TUN" == "vxlan-gpe" ]; then
        TUN_OPT="type=vxlan option:exts=gpe"
    else
        TUN_OPT=""
    fi

    if [ -z "$TUN" ]; then :; else
        ovs_vsctl add-port br-tun vtep-node-"$NODE" -- \
            set interface vtep-node-"$NODE" $TUN_OPT \
            option:remote_ip="$CONTAINER_IP" ofport_request="$NODE"
        d_ovs_vsctl "$CONTAINER" add-port br-tun vtep -- \
            set interface vtep $TUN_OPT \
            option:remote_ip="$CONTAINER_GW" ofport_request=10
    fi

    if [ -z "$ODL" ]; then :; else
        d_ovs_vsctl "$CONTAINER" set-manager "tcp:${ODL}:6640"
    fi

    DO_GUEST="$GUESTS"
    until [ $DO_GUEST -eq 0 ]; do
        ADDRESS="10.0.${NODE}.${DO_GUEST}/16"
        connect_namespace_to_container "ovsnsn${NODE}g$DO_GUEST" "$CONTAINER" \
           --ipaddress="$ADDRESS"
        let DO_GUEST-=1
    done
}

spawn_nodes_and_guests () {

    while [ $# -ne 0 ]; do
        case $1 in
            --nodes=*)
                NODES=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            --guests=*)
                GUESTS=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            --tun=*)
                TUN=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            --odl=*)
                ODL=`expr X"$1" : 'X[^=]*=\(.*\)'`
                shift
                ;;
            *)
                echo >&2 "$UTIL spawn: unknown option \"$1\""
                exit 1
                ;;
        esac
    done

    NUM_REGEX="[0-9]+"
    TUN_REGEX="vxlan|vxlan-gpe|^$"
    IP_REGEX="^$|^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"

    if [[ $NODES =~ $NUM_REGEX ]]; then :; else
         echo >&2 "$UTIL: NODES has to be a number"
         exit 1
    fi

    if [ $NODES -gt 256 ]; then
         echo >&2 "$UTIL: NODES has to be less than 256"
         exit 1
    fi

    if [[ $GUESTS =~ $NUM_REGEX ]]; then :; else
         echo >&2 "$UTIL: GUESTS has to be a number"
         exit 1
    fi

    if [ $GUESTS -gt 256 ]; then
         echo >&2 "$UTIL: GUESTS has to be less than 256"
         exit 1
    fi

    if [[ $TUN =~ $TUN_REGEX ]]; then :; else
         echo >&2 "$UTIL: TYPE has to be vxlan or vxlan-gpe"
         exit 1
    fi

    if [[ $ODL =~ $IP_REGEX ]]; then :; else
         echo >&2 "$UTIL: IP has to be a valid ip address"
         exit 1
    fi

    # Create a host bridge as end point for all tunnels
    if ovs_vsctl br-exists br-tun; then :; else
        ovs_vsctl add-br br-tun
        if [ -z "$ODL" ]; then :; else
            ovs_vsctl set-manager "tcp:${ODL}:6640"
            ovs_vsctl set-controller br-tun "tcp:${ODL}:6633"
        fi
    fi

    DO_NODE="$NODES"
    until [ $DO_NODE -eq 0 ]; do
       spawn_node "$DO_NODE" "$TUN"
       let DO_NODE-=1
    done
}

clean() {

     for ID in `sudo docker ps -a | awk '/ovs-node-[0-9]+$/ {print $1}'`; do
         sudo docker stop "$ID"
         sudo docker rm "$ID"
     done

     for NS in `sudo ip netns list | grep ovsns`; do
         sudo ip netns del "$NS"
     done

     ovs_vsctl del-br br-tun
     ovs_vsctl del-manager
}


usage() {
    cat << EOF
${UTIL}: Perform various tasks related with docker-ovs container.
usage: ${UTIL} COMMAND

Commands:
  spawn --nodes=NODES --guests=GUESTS --tun=TYPE --odl=IP
                    Runs NODES number of docker-ovs instances and attaches
                    GUESTS number of namespaces to each instance. If tun
                    option is specified, tunnel of such type will be configured
                    between the nodes and a host bridge. Types supported are
                    vxlan or vxlan-gpe
  clean
                    Stops containers and deletes namespaces
Options:
  -h, --help        display this help message.
EOF
}

UTIL=$(basename $0)
search_path ovs-vsctl
search_path docker
clean_iptables

#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

if (sudo ip netns) > /dev/null 2>&1; then :; else
    echo >&2 "$UTIL: ip utility not found (or it does not support netns),"\
             "cannot proceed"
    exit 1
fi

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

case $1 in
    "spawn")
        shift
        spawn_nodes_and_guests "$@"
        exit 0
        ;;
    "clean")
        shift
        clean
        exit 0
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo >&2 "$UTIL: unknown command \"$1\" (use --help for help)"
        exit 1
        ;;
esac

