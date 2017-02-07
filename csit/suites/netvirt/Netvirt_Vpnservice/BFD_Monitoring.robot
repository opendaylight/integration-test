*** Settings ***
Documentation     Test suite for Tunnel Monitoring. More test cases to be added in subsequent patches.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get OvsDebugInfo
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${STATE_ENABLE}    ENABLED
${STATE_DISABLE}    DISABLE
${BFD_ENABLED_FALSE}    false
${BFD_ENABLED_TRUE}    true
${PING_REGEXP}    , 0% packet loss
${VAR_BASE}       ${CURDIR}/../../../variables/netvirt

*** Test Cases ***
DHCP Check
    [Documentation]    Verify if DHCP request was successful
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IPS}=    Create List
    : FOR    ${i}    IN RANGE    0    8
    \    ${VM_IP_NET1}    ${VM_IP_NET2}    Verify VMs received IP
    \    Append To List    ${VM_IPS}    ${VM_IP_NET1}    ${VM_IP_NET2}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${VM_IPS}    None
    \    Exit For Loop If    '${status}' == 'PASS'
    Set Suite Variable    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET1}

TC00 Verify Tunnels Are Present
    [Documentation]    Verify if tunnels are present. If not then create new tunnel.
    ${output}=    ITM Get Tunnels
    Log    ${output}
    ${count}=    Get Count    ${output}    tunnel_port
    Log    ${count}
    Run Keyword If    ${count} == 0    Create Tunnel

TC01 Verify That Default Tunnel Type Is Set To BFD
    [Documentation]    Verify that the default tunnel type is set to BFD if both the devices support BFD
    Log    Verifying ITM tunnel through REST
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Log    Verifying the BFD based tunnel configuration
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Should Contain    ${output}    ${MONITORING_INTERVAL}
    Should Contain    ${output}    ${INTERVAL_1000}
    Log    Verifying the tunnel state with show state command
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    Log    Verifying the default configuration i.e BFD, tunnel monitoring enabled
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Log    Verifying the default monitor interval
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_1000}
    Log    Verifying the VXLAN Interface
    Wait Until Keyword Succeeds    180s    10s    Verify VXLAN interface
    Log    Verify Flows are present
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Verify Ping Between VMs on different Compute Nodes
    Wait Until Keyword Succeeds    30s    5s    Verify Ping

TC02 Verify that Tunnel Monitoring can be disabled and monitor interval can be configured through REST
    [Documentation]    Verify that Tunnel Monitoring can be disabled and monitor interval can be configured through REST
    Log    Verifying ITM tunnel are present and tunnel status
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Wait Until Keyword Succeeds    10s    5s    Verify Tunnel Status as UP
    Log    Verifying the BFD based tunnel configuration is on
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Log    Disabling the tunnel monitoring from REST
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/disable_tunnel_monitoring    session=session
    Log    Verifying the tunnel monitoring after disable
    ${resp}=    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${BFD_ENABLED_FALSE}
    Should Contain    ${resp.content}    ${BFD}
    Log    Verifying the default tunnel monitoring is off
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    Wait Until Keyword Succeeds    10s    5s    Verify Tunnel Status as UP
    Log    Verifying the default monitoring interval i.e 1000ms via REST
    ${resp}=    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${TMI_1000}
    Log    Change and verify the default tunnel monitoring interval after monitoring is disabled
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"2000"}    session=session
    ${resp}=    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${TMI_2000}

TC03 Verify that the monitoring interval value boundaries with Monitoring Enabled
    [Documentation]    Verify that the monitoring interval value boundaries with Monitoring Enabled
    Log    Verifying ITM tunnel are present and tunnel status
    ${output}=    ITM Get Tunnels
    Log    ${output}
    Wait Until Keyword Succeeds    10s    5s    Verify Tunnel Status as UP
    Log    Enabling the tunnel monitoring from REST
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/enable_tunnel_monitoring    session=session
    Log    Verifying the tunnel monitoring is enabled
    ${resp}=    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Should Contain    ${resp.content}    ${BFD}
    Log    Verifying the tunnel status
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Log    Changing and verifying the tunnel monitoring interval to 1000ms
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"1000"}    session=session
    ${resp}=    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${TMI_1000}
    Log    Setting the tunnel monitoring interval to 30000ms
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"30000"}    session=session
    Log    Verifying the tunnel monitoring interval to 30000ms
    Wait Until Keyword Succeeds    10s    1s    Check Tunnel Monitoring    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to greater than 30000ms cannot be set
    ${resp}=    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_31000}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    Wait Until Keyword Succeeds    10s    1s    Check Tunnel Monitoring    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to 50ms cannot be set
    ${resp}=    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_50}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    Wait Until Keyword Succeeds    10s    1s    Check Tunnel Monitoring    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to 0ms cannot be set
    ${resp}=    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_0}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    Wait Until Keyword Succeeds    10s    1s    Check Tunnel Monitoring    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to a negative value cannot be set
    ${resp}=    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_NEG}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    Wait Until Keyword Succeeds    10s    1s    Check Tunnel Monitoring    ${TMI_30000}

*** Keywords ***
Start Suite
    [Documentation]    Run before the suite execution
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Presuite Cleanup
    Create Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Delete Setup
    Close All Connections

Presuite Cleanup
    [Documentation]    Clean the already existing tunnels and tep interfaces
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_TRANSPORTZONE}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_INTERFACES}
    Log    ${resp.content}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice

Verify VMs received IP
    [Documentation]    Verify VM received IP
    ${VM_IP_NET1}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Should Not Contain    ${VM_IP_NET2}    None
    Should Not Contain    ${VM_IP_NET1}    None
    [Return]    ${VM_IP_NET1}    ${VM_IP_NET2}

Verify Ping
    [Documentation]    Verify Ping among VMs
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${table51_output} =    Get Lines Containing String    ${flow_output}    table=51
    Log    ${table51_output}
    @{table51_output}=    Split To Lines    ${table51_output}    0    -1
    : FOR    ${line}    IN    @{table51_output}
    \    Log    ${line}
    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}

Check Tunnel Monitoring
    [Arguments]    ${TMI_INTERVAL}
    [Documentation]    Check the tunnel monitoring interval through REST
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${TMI_INTERVAL}

Create Tunnel
    [Documentation]    Create tunnels betwee the 2 compute nodes and Openstack controller.
    Log    If ODL version is Boron or higher then ITM tunnel should be auto configured. If not then the suite should fail. For ODL version Beryllium or lower, ITM tunnel should be created.
    CompareStream.Run_Keyword_If_At_Least_Boron    BuiltIn.Fail    Tunnel should be auto configured for ${ODL_STREAM}
    ${node_1_dpid}=    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid}=    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_3_dpid}=    Get DPID    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter}=    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter}=    Get Ethernet Adapter    ${OS_CONTROL_NODE_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet}=    Set Variable    ${first_two_octets}.0.0/16
    ${gateway}=    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ${gateway1}=    Get Default Gateway    ${OS_CONTROL_NODE_IP}
    ${gateway2}=    Get Default Gateway    ${OS_COMPUTE_2_IP}
    Issue Command On Karaf Console    tep:add ${node_1_dpid} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_2_dpid} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_3_dpid} ${node_3_adapter} 0 ${OS_CONTROL_NODE_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:commit
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP

Delete Setup
    [Documentation]    Delete the created VMs, ports, subnet and networks
    Log    Delete the VM instances
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    Log    Delete neutron ports
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    Log    Delete subnets
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    Log    Delete networks
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
