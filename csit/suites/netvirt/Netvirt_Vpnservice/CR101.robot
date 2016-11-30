*** Settings ***
Documentation     Test suite for CR101
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL Karaf Log
...               AND    Create Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get OvsDebugInfo    #Test Teardown    Get OvsDebugInfo
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET1    NET2
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    20.1.1.0/24    20.2.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
@{VM_INSTANCES_NET1}    VM1    VM2
@{VM_INSTANCES_NET2}    VM3    VM4
@{ROUTERS}        ROUTER_1    ROUTER_2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2","8800:2"]
${CREATE_IMPORT_RT}    ["2200:2","8800:2"]
@{EXTRA_NW_IP}    10.1.1.110
#@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
## Values passed for extra routes
#${EXT_RT1}       destination=40.1.1.0/24,nexthop=10.1.1.3
#${EXT_RT2}       destination=50.1.1.0/24,nexthop=10.1.1.3
#${RT_OPTIONS}    --routes type=dict list=true
#${RT_CLEAR}      --routes action=clear
#${MAC_REGEX}     ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
#${FIB_ENTRY_1}    10.1.1.3
#${FIB_ENTRY_1}    10.1.1.110
#${FIB_ENTRY_3}    10.1.1.4
#${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.1.110 10.1.1.110
#${RPING_EXP_STR}    broadcast
${TUNNEL_MONITOR_ON}    Tunnel Monitoring (for VXLAN tunnels): On
${MONITORING_INTERVAL}    Tunnel Monitoring Interval (for VXLAN tunnels): 100
${INTERVAL_1000}    1000

*** Test Cases ***
TC01
    [Documentation]    Test Case 1
    Log    Test the Setup
    ${output} =    ITM Get Tunnels
    Log    ${output}
    ${output}=    Issue Command On Karaf Console    tep:show
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Should Contain    ${output}    ${MONITORING_INTERVAL}
    Should Contain    ${output}    ${INTERVAL_1000}
    Log    Verifying the default configuration i.e BFD, tunnel monitoring enabled
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/itm-config:tunnel-monitor-params/
    Log    ${resp.content}
    Should Contain    ${resp.content}    bfd

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

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Contain    ${flow_output}    table=21
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=10.1.1.3
    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=20.1.1.3
    ${table50_output} =    Get Lines Containing String    ${flow_output}    table=50
    Log To Console    ${table50_output}
    @{table50_output}=    Split To Lines    ${table50_output}    0    -1
    : FOR    ${line}    IN    @{table50_output}
    \    Log To Console    ${line}
    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}

Create Setup
    [Documentation]    UC_8 Verify the creation of two networks, two subnets and four ports using Neutron CLI
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create five networks
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
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice    #    @{VM_INSTANCES}
    ...    # Create List    @{VM_INSTANCES_NET1}    @{VM_INSTANCES_NET2}    @{VM_INSTANCES_NET3}    @{VM_INSTANCES_NET4}    # @{VM_INSTANCES_NET5}
    ...    #    : FOR    ${VM}    IN    @{VM_INSTANCES}    #
    ...    # Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}    #
    ...    # : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}    #    Wait Until Keyword Succeeds
    ...    # 25s    5s    Verify VM Is ACTIVE    ${VM}    #    : FOR
    ...    # ${VM}    IN    @{VM_INSTANCES_NET20}    #    Wait Until Keyword Succeeds    25s
    ...    # 5s    Verify VM Is ACTIVE    ${VM}    #    : FOR    ${VM}
    ...    # IN    @{VM_INSTANCES_NET30}    #    Wait Until Keyword Succeeds    25s    5s
    ...    # Verify VM Is ACTIVE    ${VM}    #    Log    Check for routes    #
    ...    # Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    #    ${VM_IP_NET1}
    ...    # ${DHCP_IP1}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    # @{VM_INSTANCES_NET1}
    ...    #    Log    ${VM_IP_NET1}    #    Set Suite Variable    ${VM_IP_NET1}
    ...    #    ${VM_IP_NET2}    ${DHCP_IP2}    Wait Until Keyword Succeeds    180s    10s
    ...    # Verify VMs Received DHCP Lease    # @{VM_INSTANCES_NET2}
    #    Log    ${VM_IP_NET2}
    #    Set Suite Variable    ${VM_IP_NET2}
