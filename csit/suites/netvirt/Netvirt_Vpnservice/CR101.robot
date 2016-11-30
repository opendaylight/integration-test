*** Settings ***
Documentation     Test suite for BFD Tunnel Monitoring
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL Karaf Log
...               AND    Create Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get OvsDebugInfo
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${STATE_UP}      UP
${STATE_DOWN}      DOWN
${SH_OF_CMD}      sudo ovs-ofctl
${SH_OVS_CMD}     sudo ovs-vsctl
${OF_PROTOCOL}    -O OpenFlow13
${SH_HIPVS_CMD}    hipvsctl
${grep}           | grep
${check}          LIVE

*** Test Cases ***
TC01
    [Documentation]    Test Case 1
    Log    Verifying ITM tunnel through REST
    ${output} =    ITM Get Tunnels
    Log    ${output}
    Log    Verifying the BFD based tunnel configuration
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Should Contain    ${output}    ${MONITORING_INTERVAL}
    Should Contain    ${output}    ${INTERVAL_1000}
    Log    Verifying the tunnel state with show state command
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}
    Log    Verifying the default configuration i.e BFD, tunnel monitoring enabled
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD}
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_100}
    Log    Verifying the VXLAN Interface
    ${output}=    Issue Command On Karaf Console    vxlan
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    vxlan:show
    Log    ${output}
    Log    Verify Flows are present
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP} 
    Log    Verify Ping Between VMs on different Compute Nodes
    Wait Until Keyword Succeeds    30s    5s    Verify Ping
    SW_GET_ALL_PORT    ${OS_COMPUTE_1_IP}     br-int

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[0]
    ${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[1]

Create Setup
    [Documentation]    UC_8 Verify the creation of two networks, two subnets and four ports using Neutron CLI
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/networks/    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/subnets/    ${SUBNETS}
    Log    Create Security Group with ICMP,TCP And UDP protocol
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/ports/    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${DHCP_IP1}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    Set Suite Variable    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET2}

Verify Ping
    [Documentation]    Verify Ping amonng VMs
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    64 bytes

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Not Contain    ${flow_output}    table=21
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Match regexp    ${flow_output}    table=17.*goto_table:50
    ${table50_output} =    Get Lines Containing String    ${flow_output}    table=50
    Log To Console    ${table50_output}
    @{table50_output}=    Split To Lines    ${table50_output}    0    -1
    : FOR    ${line}    IN    @{table50_output}
    \    Log To Console    ${line}
    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}
 
SW_GET_ALL_PORT
    [Arguments]    ${ip}    ${brname}    ${sw_type}=ovs
    ${ports}=    Create Dictionary
    @{keys}=    Create List
    @{values}=    Create List
    ${grep_cmd}=    Catenate    ${grep}    -A2    addr
    ${cmd}=    Catenate    ${SH_OF_CMD}    show    ${brname}    ${OF_PROTOCOL}    ${grep_cmd}
    Log    ${cmd}
    ${all_port_output}=    Run Keyword If    '${sw_type}' == 'ovs'    Run Command On Remote System    ${ip}    ${cmd}
    Log    ${all_port_output}
    ${matches} =    Get Lines Containing String    ${all_port_output}    addr
    Log    ${matches}
    @{lines}    Split To Lines    ${matches}
    : FOR    ${line}    IN    @{lines}
    \    ${matches}=    Fetch From Left    ${line}    :
    \    ${matches}=    Strip String    ${matches}
    \    Log    ${matches}
    \    Append To List    ${keys}    ${matches}
    Log    ${keys}
    ${matches} =    Get Lines Containing String    ${all_port_output}    state
    Log    ${matches}
    @{lines}    Split To Lines    ${matches}
    : FOR    ${line}    IN    @{lines}
    \    ${matches}=    Fetch From Right    ${line}    :
    \    ${matches}=    Strip String    ${matches}
    \    Log    ${matches}
    \    Append To List    ${values}    ${matches}
    Log    ${values}
