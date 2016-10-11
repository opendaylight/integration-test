#!/bin/bash

display_usage() {
  echo "Add VPP Mount into ODL."
  echo "Usage:$0 [ODL Hostname or IP:port] [Mount Name of VPP in ODL] [VPP Hostname or IP] \n"
  exit 85
}

if [  $# -lt 3 ]
then
  display_usage
exit 1
fi

odl_ip=$1
vpp_host=$2
vpp_ip=$3

vpp_username=admin
vpp_password=admin

post_data='{"node" : [
{"node-id":"'$vpp_host'",
"netconf-node-topology:host":"'$vpp_ip'",
"netconf-node-topology:port":"2831",
"netconf-node-topology:tcp-only":false,
"netconf-node-topology:keepalive-delay":0,
"netconf-node-topology:username":"'$vpp_username'",
"netconf-node-topology:password":"'$vpp_password'",
"netconf-node-topology:connection-timeout-millis":10000,
"netconf-node-topology:default-request-timeout-millis":10000,
"netconf-node-topology:max-connection-attempts":10,
"netconf-node-topology:between-attempts-timeout-millis":10000,
"netconf-node-topology:schema-cache-directory":"hcmount"}
]
}
'

curl -u admin:admin -X POST -d "$post_data" -H 'Content-Type: application/json' http://$odl_ip:8081/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf
