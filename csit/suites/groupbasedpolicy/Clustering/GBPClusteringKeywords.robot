*** Settings ***
Documentation     Collection of reusable keywrods for clustering tests
Library           SSHLibrary    120 seconds
Library           RequestsLibrary
Resource          ./Variables.robot
Resource          ./Connections.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/GBP/ConnUtils.robot

*** Keywords ***
Search For Gbp Master
    [Documentation]    Check karaf logs to identify node with running instances
    [Arguments]    ${skip_index}=${EMPTY}
    Set Suite Variable    ${GBP_INSTANCE_COUNT}    0
    : FOR    ${index}    IN RANGE    1    4
    \    Continue For Loop If    '${index}' == '${skip_index}'
    \    ${ip}=    ${ODL_SYSTEM_${index}_IP}
    \    ${output}=    Issue Command On Karaf Console    log:display | grep --color=never 'Instantiating'    controller=${ip}
    \    Log    ${output}
    \    Run Keyword If    "GroupbasedpolicyInstance" in "\""+${output}+"\""    Set Gbp Master Index And Increment Count    ${index}
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

Verify VPP Setup
    [Documentation]    Checks if all required VPP configuration is present
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${ODL_SYSTEM_${GBP_MASTER_INDEX}_IP}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Wait For Karaf Log    Renderer updated renderer policy to version    karaf_ip=${ODL_SYSTEM_IP}
    Switch Connection    VPP2_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 1 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 2 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh vxlan tunnel
    Log    ${out}
    Switch Connection    VPP3_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 1 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 2 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh vxlan tunnel
    Log    ${out}

Check Ports
    [Documentation]    Checks whether all port are already present
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    Should Contain    ${out}    tap-1
    Should Contain    ${out}    tap-2
    Should Contain    ${out}    tap-3
    Should Contain    ${out}    vxlan_tunnel0
    Should Contain    ${out}    vxlan_tunnel1
    Should Contain    ${out}    vxlan_tunnel2
    Should Contain    ${out}    vxlan_tunnel3
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Should Contain    ${out}    1
    Should Contain    ${out}    2

Register VPP Node In ODL
    [Documentation]    Register VPP node 
    [Arguments]    ${vpp_name}    ${vpp_ip}
    ${data}=    {\"node\" : [
    ...    {\"node-id\":\"${vpp_name}\",
    ...    \"netconf-node-topology:host\":\"${vpp_ip}\",
    ...    \"netconf-node-topology:port\":\"2831\",
    ...    \"netconf-node-topology:tcp-only\":false,
    ...    \"netconf-node-topology:keepalive-delay\":0,
    ...    \"netconf-node-topology:username\":\"admin\",
    ...    \"netconf-node-topology:password\":\"admin\",
    ...    \"netconf-node-topology:connection-timeout-millis\":10000,
    ...    \"netconf-node-topology:default-request-timeout-millis\":10000,
    ...    \"netconf-node-topology:max-connection-attempts\":10,
    ...    \"netconf-node-topology:between-attempts-timeout-millis\":10000,
    ...    \"netconf-node-topology:schema-cache-directory\":\"hc-schema\"}
    ...    ]
    ...    }
    ${out}    SSHLibrary.Execute Command    curl -u ${ODL_RESTCONF_USER}:${ODL_RESTCONF_PASSWORD} -X POST -d ${data} -H \'Content-Type: application/json\' http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/config/network-topology:network-topology/network-topology:topology/topology-netconf
    Log    ${out}
