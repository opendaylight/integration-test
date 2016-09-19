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

UTIL=$(basename $0)

setup_network_iface () {
    CONTAINER="$1"

    echo "Configuring container: $CONTAINER";
    docker exec $CONTAINER ip netns add app
    docker exec $CONTAINER ip link add veth-app type veth peer name veth-br
    docker exec $CONTAINER ovs-vsctl add-port br-sfc veth-br
    docker exec $CONTAINER ip link set dev veth-br up
    docker exec $CONTAINER ip link set veth-app netns app
}

while [ $# -ne 0 ]; do
    case $1 in
        --nodes=*)
            NODES=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
        *)
            echo >&2 "$UTIL spawn: unknown option \"$1\""
            exit 1
            ;;
    esac
done

for i in $(seq 1 $NODES); do
    setup_network_iface "ovs-node-$i"
done

exit 0
