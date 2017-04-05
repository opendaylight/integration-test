#!/bin/bash

# Copyright 2017 Brocade Communications Systems, Inc.
# 130 Holger Way, San Jose, CA 95134.
# All rights reserved.
#
# Brocade, the B-wing symbol, Brocade Assurance, ADX, AnyIO, DCX, Fabric OS,
# FastIron, HyperEdge, ICX, MLX, MyBrocade, NetIron, OpenScript, VCS, VDX, and
# Vyatta are registered trademarks, and The Effortless Network and the On-Demand
# Data Center are trademarks of Brocade Communications Systems, Inc., in the
# United States and in other countries. Other brands and product names mentioned
# may be trademarks of others.
#
# Use of the software files and documentation is subject to license terms.

set -e

key3="$(cat /etc/ssh/ssh_host_rsa_key.pub)"
parts=($key3)
hostkey=${parts[1]}
id=$1
controller=$controller_ip
echo "Adding key for ${id} to ${controller}"
echo "Found host key: ${hostkey}"

port=8181
basicauth="YWRtaW46YWRtaW4="

set +e
read -r -d '' payload << EOM
{
    "device": [
        {
            "ssh-host-key": "${hostkey}",
            "unique-id": "${id}"
        }
     ]
}
EOM
set -e

payload=$(echo "${payload}" | tr '\n' ' ' | tr -s " ")

url="http://${controller}:${port}/restconf/config/odl-netconf-callhome-server:netconf-callhome-server/allowed-devices"

echo "POST to whitelist"
res=$(curl -s -X POST -H "Authorization: Basic ${basicauth}" \
      -H "Content-Type: application/json" \
      -H "Cache-Control: no-cache" \
      -H "Postman-Token: 656d7e0d-2f48-5135-3569-06b2a27a709d" \
      --data "${payload}" \
      ${url})
echo $res
if [[ $res == *"data-exists"* ]]; then
  echo "Whitelist already has that entry."
fi
