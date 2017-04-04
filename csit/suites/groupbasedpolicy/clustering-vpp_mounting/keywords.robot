*** Settings ***
Documentation     Collection of reusable keywrods for clustering tests
Library           SSHLibrary    300 seconds
Library           RequestsLibrary
Resource          ../../../libraries/KarafKeywords.robot
Resource          vars.robot

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

Search For Gbp Master
    [Documentation]    Check karaf logs to identify node with running gbp
    [Arguments]    ${skip_index}=${EMPTY}
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    0
    : FOR    ${index}    IN RANGE    1    6
    \    continue for loop if    '${index}' == '${skip_index}'
    \    ${ip}    set variable    ${ODL_SYSTEM_${index}_IP}
    \    ${output}    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'    controller=${ip}
    \    Log    ${output}
    \    run keyword if    "GroupbasedpolicyInstance" in "\""+${output}+"\""    Set Gbp Master Index And Increment Count    ${index}
    Log    ${GBP_INSTANCE_COUNT}
    Should Not Be Equal    ${GBP_INSTANCE_COUNT}    0
    [Return]    ${GBP_INSTANCE_COUNT}

Set Gbp Master Index And Increment Count
    [Documentation]    Set found ODL node with GBP instances for next tests
    [Arguments]    ${index}
    Set Global Variable    ${GBP_MASTER_INDEX}    ${index}
    Log    ${GBP_INSTANCE_COUNT}
    ${NEW_COUNT}    Evaluate    ${GBP_INSTANCE_COUNT} + 1
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    ${NEW_COUNT}
    Log    ${GBP_INSTANCE_COUNT}
