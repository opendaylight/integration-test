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

UTIL=$(basename $0)
CONTAINERS=`docker ps --format "{{.Names}}"`
while [ $# -ne 0 ]; do
    case $1 in
        --container=*)
            CONTAINERS=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
        *)
            echo >&2 "$UTIL: unknown option \"$1\""
            exit 1
            ;;
    esac
done

for container in ${CONTAINERS}; do
        docker exec $container ovs-ofctl -OOpenFlow13 dump-flows br-sfc
done
exit 0
