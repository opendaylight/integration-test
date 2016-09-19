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

set -o xtrace
#set -e #Exit script if a command fails

UTIL=$(basename $0)

setup_network_iface () {
    CONTAINER="$1"
    CONTAINER_IF="$2"
    docker exec $CONTAINER ip netns add app
    docker exec $CONTAINER ip link add veth-app type veth peer name $CONTAINER_IF
    docker exec $CONTAINER ovs-vsctl add-port br-sfc $CONTAINER_IF
    docker exec $CONTAINER ip link set dev $CONTAINER_IF up
    docker exec $CONTAINER ip link set veth-app netns app
}

while [ $# -ne 0 ]; do
    case $1 in
        --nodes=*)
            NODES=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
        *)
            echo >&2 "$UTIL: unknown option \"$1\""
            exit 1
            ;;
    esac
done

GUEST=1

for node in $(seq 1 $NODES); do
    NAMESPACE="ovsnsn${node}g${GUEST}"
    CONTAINER_IF="c-${NAMESPACE}"
    setup_network_iface "ovs-node-$node" $CONTAINER_IF
done

exit 0
