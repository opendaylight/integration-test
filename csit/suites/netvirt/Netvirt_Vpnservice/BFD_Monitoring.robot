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
Resource          ../../../libraries/OVSDB.robot

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
TC00 Verify if tunnels are present
     [Documentation]     Verify if tunnels are present
     ${output} =    ITM Get Tunnels
     Log    ${output}
     ${count}=    Get Count    ${output}    tunnel_port
     Log    ${count} 
     Run Keyword If    ${count} == 0    Create Tunnel

TC01 Verify that the default tunnel type is set to BFD
    [Documentation]    Verify that the default tunnel type is set to BFD if both the devices support BFD
    Log    Verifying ITM tunnel through REST
    ${output} =    ITM Get Tunnels
    Log    ${output}
    Log    Verifying the BFD based tunnel configuration
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Should Contain    ${output}    ${MONITORING_INTERVAL}
    Should Contain    ${output}    ${INTERVAL_1000}
    Log    Bridge Up
    Log    Verifying the tunnel state with show state command
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    Log    Verifying the default configuration i.e BFD, tunnel monitoring enabled
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_100}
    Log    Verifying the VXLAN Interface
    ${output}=    Issue Command On Karaf Console    ${VXLAN_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Contain    ${output}    ${STATE_ENABLE}
    Should Not Contain     ${output}    ${STATE_DISABLE}
    Log    Verify Flows are present
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Verify Ping Between VMs on different Compute Nodes
    Wait Until Keyword Succeeds    30s    5s    Verify Ping

TC02 Verify that Tunnel Monitoring can be disabled and monitor interval can be configured through REST
    [Documentation]    Verify that Tunnel Monitoring can be disabled and monitor interval can be configured through REST
    Log    Verifying ITM tunnel through REST
    ${output} =    ITM Get Tunnels
    Log    ${output}
    Log    Verifying the BFD based tunnel configuration
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Log    Disabling the tunnel monitoring from REST
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/disable_tunnel_monitoring    session=session
    Log    Verifying the tunnel monitoring after disable
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD_ENABLED_FALSE}
    Should Contain    ${resp.content}    ${BFD}
    Log    Verifying the default tunnel monitoring is off
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_OFF}
    Log    Verifying the tunnel state with show state command
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    Log    Verifying the default monitoring interval i.e 1000ms via REST
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_100}
    Log    Changing the tunnel monitoring interval after monitoring is disabled
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"2000"}    session=session
    Log    Verifying the default monitoring interval i.e 2000ms
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_200}

TC03 Verify that the monitoring interval value boundaries with Monitoring Enabled
    [Documentation]    Verify that the monitoring interval value boundaries with Monitoring Enabled
    Log    Enabling the tunnel monitoring from REST
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/enable_tunnel_monitoring    session=session
    Log    Verifying the tunnel monitoring is enabled
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Should Contain    ${resp.content}    ${BFD}
    Log    Verifying the tunnel status
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Log    Changing the tunnel monitoring interval to 1000ms
    Log    Verifying the default monitoring interval i.e 1000ms
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"1000"}    session=session
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_100}
    Log    Setting the tunnel monitoring interval to 30000ms
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"30000"}    session=session
    Log    Verifying the tunnel monitoring interval to 30000ms
    Sleep    2
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to 50ms
    ${resp}    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_50}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${TMI_50}
    Should Contain    ${resp.content}    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to 0ms
    ${resp}    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_0}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${TMI_0}
    Should Contain    ${resp.content}    ${TMI_30000}
    Log    Verifying the tunnel monitoring interval to a negative value
    ${resp}    RequestsLibrary.Put Request    session    ${MONITOR_INTERVAL_NEW}    data=${INTERVAL_NEG}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_ERROR_CODE}
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Not Contain    ${resp.content}    ${TMI_NEG}
    Should Contain    ${resp.content}    ${TMI_30000}

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Create Setup
    [Documentation]    Create two networks, two subnets and four ports
#    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
#    Log    ${output}
#    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
#    Log    ${output}
#    ${node_1_dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
#    ${node_2_dpid} =    Get DPID    ${OS_COMPUTE_2_IP}
#    ${node_3_dpid} =    Get DPID    ${OS_CONTROL_NODE_IP}
#    ${node_1_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
#    ${node_2_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
#    ${node_3_adapter} =    Get Ethernet Adapter    ${OS_CONTROL_NODE_IP}
#    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
#    ${subnet} =    Set Variable    ${first_two_octets}.0.0/16
#    ${gateway} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
#    ${gateway1} =    Get Default Gateway    ${OS_CONTROL_NODE_IP}
#    ${gateway2} =    Get Default Gateway    ${OS_COMPUTE_2_IP}
#    Issue Command On Karaf Console    tep:add ${node_1_dpid} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet} null TZA
#    Issue Command On Karaf Console    tep:add ${node_2_dpid} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet} null TZA
#    Issue Command On Karaf Console    tep:add ${node_3_dpid} ${node_3_adapter} 0 ${OS_CONTROL_NODE_IP} ${subnet} null TZA
#    Issue Command On Karaf Console    tep:commit
#    Sleep    20
#    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
#    Log    ${output}
#    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
#    Log    ${output}
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
#    Get OvsDebugInfo
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
    #Get OvsDebugInfo
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
    Get OvsDebugInfo

Verify Ping
    [Documentation]    Verify Ping amonng VMs
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping -c 3 ${VM_IP_NET1[1]}
    Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Contain     ${output}    ${PING_REGEXP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain     ${output}    ${PING_REGEXP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain     ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    #${flow_output}=    SW_GET_FLOW_TABLE    ${OS_COMPUTE_1_IP}    br-int
    #Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Not Contain    ${flow_output}    table=21
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${table51_output} =    Get Lines Containing String    ${flow_output}    table=51
    Log To Console    ${table51_output}
    @{table51_output}=    Split To Lines    ${table51_output}    0    -1
    : FOR    ${line}    IN    @{table51_output}
    \    Log To Console    ${line}
    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}

Verify Tunnel Status as UP
    [Documentation]    Verify that the tunnels are UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}

Verify Tunnel Status as DOWN
    [Documentation]    Verify that the tunnels are DOWN
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_DOWN}
 
Create Tunnel
    [Documentation]    Create tunnels betwee the 2 compute nodes and Openstack controller.
    ${node_1_dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid} =    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_3_dpid} =    Get DPID    ${OS_CONTROL_NODE_IP}
    ${node_1_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${node_3_adapter} =    Get Ethernet Adapter    ${OS_CONTROL_NODE_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet} =    Set Variable    ${first_two_octets}.0.0/16
    ${gateway} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ${gateway1} =    Get Default Gateway    ${OS_CONTROL_NODE_IP}
    ${gateway2} =    Get Default Gateway    ${OS_COMPUTE_2_IP}
    Issue Command On Karaf Console    tep:add ${node_1_dpid} ${node_1_adapter} 0 ${OS_COMPUTE_1_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_2_dpid} ${node_2_adapter} 0 ${OS_COMPUTE_2_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:add ${node_3_dpid} ${node_3_adapter} 0 ${OS_CONTROL_NODE_IP} ${subnet} null TZA
    Issue Command On Karaf Console    tep:commit
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
