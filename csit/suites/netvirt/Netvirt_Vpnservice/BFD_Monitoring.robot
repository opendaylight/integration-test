*** Settings ***
Documentation     Test suite for BFD Tunnel Monitoring
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL Karaf Log
...               AND    Create Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get OvsDebugInfo
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SwitchOperations.robot
Resource          ../../../libraries/OVSDB.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${STATE_UP}       UP
${STATE_DOWN}     DOWN
${STATE_ENABLE}    ENABLED
${STATE_DISABLE}    DISABLED
${BFD_ENABLED_FALSE}    false
${BFD_ENABLED_TRUE}    true
${PING_REGEX}     , 0% packet loss
${VAR_BASE}       ${CURDIR}/../../../variables/netvirt

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
    Log    Bridge Up
    ${ifconfig_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig
    Log    ${ifconfig_output}
    #    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-ext up
    #    Log    ${bridge_up}
    #    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo /sbin/ifconfig br-ext up
    #    Log    ${bridge_up}
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
    Should Not Contain    ${output}    ${STATE_DISABLE}
    Log    Verify Flows are present
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Verify Ping Between VMs on different Compute Nodes
    Wait Until Keyword Succeeds    30s    5s    Verify Ping

TC02
    [Documentation]    Test Case 2
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

TC03
    [Documentation]    Test Case 3
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
    #TC04
    #    [Documentation]    TC04
    #    ${dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
    #    ${gtw} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
    #    ${ifconfig_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig ${dpid}:tunnel_port:0
    #    Verify Tunnel Status as UP
    #    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/itm-state:dpn-endpoints/DPN-TEPs-info/${dpid}/
    #    Log    ${resp.content}
    #    @{lines}    Split To Lines    ${resp.content}
    #    : FOR    ${line}    IN    @{lines}
    #    ${matches} =    Get Lines Containing String    ${line}    interface-name
    #    ${matches}=    Fetch From Right    ${matches}    :
    #    ${matches}=    Strip String    ${matches}    characters="
    #    ${ifconfig_output}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig ${dpid}:tunnel_port:0

TC05
    [Documentation]    TC05
    Log    Changing the tunnel monitoring to LLDP from REST
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_lldp    session=session
    Log    Verifying the tunnel monitoring protocol changed to lldp
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Should Contain    ${resp.content}    ${LLDP}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    Log    Verifying the default monitoring interval i.e 1000ms via REST
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_30000}
    Log    Changing the tunnel monitoring interval after monitoring is disabled
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/monitor_interval    mapping={"int":"20000"}    session=session
    Log    Verifying the default monitoring interval i.e 20000ms
    ${resp}    RequestsLibrary.Get Request    session    ${MONITOR_INTERVAL_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${TMI_2000}
    Log    Changing the tunnel monitoring back to bfd
    TemplatedRequests.Put_As_Json_Templated    folder=${VAR_BASE}/enable_tunnel_monitoring    session=session
    Log    Verifying the tunnel monitoring protocol changed to lldp
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Should Contain    ${resp.content}    ${BFD}

TC06
    [Documentation]    Verify that the Access port reflect the proper status with BFD Monitoring SET to ON
    Log    Verifying default tunnel status and protocol
    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int up
    Log    ${bridge_up}
    Sleep     5
    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int up
    Log    ${bridge_up}
    Sleep     5
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW}
    Log    ${output}
    Should Contain    ${output}    ${TUNNEL_MONITOR_ON}
    ${resp}    RequestsLibrary.Get Request    session    ${TUNNEL_MONITOR_URL}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${BFD_ENABLED_TRUE}
    Should Contain    ${resp.content}    ${BFD}
    Log    Verifyin the access port i.e vhost port status
    ${all_ports_status} =    SW_GET_ALL_PORT_STATUS      ${OS_COMPUTE_1_IP}     br-int
    Log    ${all_ports_status}
    ${all_ports_status} =    SW_GET_ALL_PORT_STATUS      ${OS_COMPUTE_2_IP}     br-int
    Log    ${all_ports_status}
    Log    Restarting the VM to verify the access port goes down
    ${output}=    Execute Command on VM Instance    ${NETWORKS[0]}     ${VM_IP_NET1[0]}    sudo reboot
    Log    ${output}
    ${all_ports_status} =    SW_GET_ALL_PORT_STATUS      ${OS_COMPUTE_1_IP}     br-int
    Log    ${all_ports_status}
    Sleep    5
    ${all_ports_status} =    SW_GET_ALL_PORT_STATUS      ${OS_COMPUTE_1_IP}     br-int
    Log    ${all_ports_status}

TC07
    [Documentation]    Verify that the Access port reflect the proper status with BFD Monitoring SET to ON
    Log    Verifying default tunnel status and protocol
    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int up
    Log    ${bridge_up}
    Sleep     5
    ${bridge_up}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int up
    Log    ${bridge_up}
    Sleep     5
    Wait Until Keyword Succeeds    30s    5s    Verify Tunnel Status as UP
    ${int_down}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int down
    Log    ${bridge_up}
    ${int_down}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig
    Log    ${bridge_up}
    Sleep    4
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    ${int_down}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig br-int up 
    Log    ${bridge_up}
    ${int_down}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo /usr/sbin/ifconfig
    Log    ${bridge_up}
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Create Setup
    [Documentation]    Verify the creation of two networks, two subnets and four ports using Neutron CLI
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
    Should Match Regexp    ${output}    ${PING_REGEX}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[0]}    ping -c 3 ${VM_IP_NET2[1]}
    Should Match Regexp    ${output}    ${PING_REGEX}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ping -c 3 ${VM_IP_NET1[0]}
    Should Contain    ${output}    ${PING_REGEX}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET2[1]}    ping -c 3 ${VM_IP_NET2[0]}
    Should Contain    ${output}    ${PING_REGEX}

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
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_UP}
    Should Not Contain    ${output}    ${STATE_DOWN}

Verify Tunnel Status as DOWN
    ${output}=    Issue Command On Karaf Console    ${TEP_SHOW_STATE}
    Log    ${output}
    Should Contain    ${output}    ${STATE_DOWN}
