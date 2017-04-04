*** Settings ***
Documentation     Collection of reusable keywrods for clustering tests
Library           SSHLibrary    120 seconds
Library           RequestsLibrary

*** Keywords ***
Register VPP Node In ODL
    [Documentation]    Register VPP node
    [Arguments]    ${vpp_name}    ${vpp_ip}
    ${data}=    Catenate
    ...    {"node" : [
    ...    {"node-id":"${vpp_name}",
    ...    "netconf-node-topology:host":"${vpp_ip}",
    ...    "netconf-node-topology:port":"2831",
    ...    "netconf-node-topology:tcp-only":false,
    ...    "netconf-node-topology:keepalive-delay":0,
    ...    "netconf-node-topology:username":"admin",
    ...    "netconf-node-topology:password":"admin",
    ...    "netconf-node-topology:connection-timeout-millis":10000,
    ...    "netconf-node-topology:default-request-timeout-millis":10000,
    ...    "netconf-node-topology:max-connection-attempts":10,
    ...    "netconf-node-topology:between-attempts-timeout-millis":10000,
    ...    "netconf-node-topology:schema-cache-directory":"hc-schema"}
    ...    ]
    ...    }
    ${out}    SSHLibrary.Execute Command    curl -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} -X POST -d ${data} -H \'Content-Type: application/json\' http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf
    Log    ${out}

Unregister VPP Node In ODL
    [Documentation]    Unegister VPP node
    [Arguments]    ${vpp_name}    ${vpp_ip}
    ${out}    SSHLibrary.Execute Command    curl -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} -X DELETE -d -H \'Content-Type: application/json\' http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf
    Log    ${out}
