#!/bin/bash

display_usage() {
  echo "Add VPP Mount into ODL."
  echo "Usage:$0 [ODL Hostname or IP] [ODL restconf port] [ODL restconf username] [ODL restconf passwword] [Mount Name of VPP in ODL] [VPP Hostname or IP] \n"
  exit 85
}

if [  $# -lt 3 ]
then
  display_usage
exit 1
fi

odl_ip=$1
odl_restconf_port=$2
odl_restconf_username=$3
odl_restconf_password=$4
vpp_host=$5
vpp_ip=$6

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
echo $post_data
curl -u $odl_restconf_username:$odl_restconf_password -X POST -d "$post_data" -H 'Content-Type: application/json' http://$odl_ip:$odl_restconf_port/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf
curl -u $odl_restconf_username:$odl_restconf_password -X GET http://$odl_ip:$odl_restconf_port/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf/

