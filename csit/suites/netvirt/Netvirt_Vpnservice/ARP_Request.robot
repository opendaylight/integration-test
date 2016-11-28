*** Settings ***
Documentation     Test suite for ARP Request. More test cases to be added in subsequent patches.
Suite Setup       BuiltIn.Run Keywords    DevstackUtils.Devstack Suite Setup    AND    SetupUtils.Setup_Utils_For_Setup_And_Teardown    AND    Create Setup    
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
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../variables/netvirt/Variables.robot
Variables         ../../../variables/Variables.py

*** Variables ***
#${STATE_UP}      UP
#${STATE_DOWN}    DOWN
#${STATE_ENABLE}    ENABLED
#${STATE_DISABLE}    DISABLE
#${BFD_ENABLED_FALSE}    false
#${BFD_ENABLED_TRUE}    true
#${PING_REGEXP}    , 0% packet loss
#${VAR_BASE}      ${CURDIR}/../../../variables/netvirt
@{EXTRA_NW_IP}    50.1.1.110
${FIB_ENTRY_1}    50.1.1.3
${FIB_ENTRY_2}    50.1.1.110
${FIB_ENTRY_3}    50.1.1.4
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 50.1.1.110 50.1.1.110
${RPING_EXP_STR}    broadcast
#${FIB_ENTRY_VM11_REGEX}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_VM21_REGEX}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_MIP_REGEX_DPN2}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#${FIB_ENTRY_MIP_REGEX_DPN1}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]

*** Test Cases ***
TC01
    [Documentation]    Test Case 1
    Log    Validate the Flows on DPNs
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    @{ips}=    Create List
    Append To List    ${ips}    ${VM_IP_NET1[1]}    ${VM_IP_NET1[0]}
    Get Fib Entries    session    @{ips}
    #    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    #    Log    ${resp}
    #    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    #    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Log    Checking the RX Packets Count on VM2 before ARP Broadcast
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    Log    ${rx_packet1_before}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${rx_packet0_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    Log    ${rx_packet0_before}
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    20
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Contain    ${output}    eth0:1
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${RPING_MIP_IP}
    Should Contain    ${output}    broadcast
    Should Contain    ${output}    Received 0 reply
    Log    Validate the Flows on DPNs
    Log    Checking the RX Packets Count on VM2 after ARP Broadcast
    ${rx_packet1_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig eth0
    Log    ${rx_packet1_after}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${rx_packet0_after} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0
    Log    ${rx_packet0_after}
    Should Not Be Equal    ${rx_packet0_before}    ${rx_packet0_after}
    Should Not Be Equal    ${rx_packet1_before}    ${rx_packet1_after}
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Checking MAC-IP table in Config DS via REST
    Append To List    ${ips}    ${FIB_ENTRY_2}
    Wait Until Keyword Succeeds    60s    5s    Get Fib Entries    session    @{ips}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Wait Until Keyword Succeeds    60s    5s    Get MAC IP
    # ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    # Log    ${resp.content}
    # Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    # Should Contain    ${resp.content}    ${FIB_ENTRY_2}
    # Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    # Log    Validate the FIB entries in Controller
    # ${output}    Get Fib Entries    session
    # ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
    # Log    ${resp}

TC02
    [Documentation]    Test Case 2
    Log    Validate the Flows on DPNs
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    @{ips}=    Create List
    Append To List    ${ips}    ${VM_IP_NET1[1]}    ${VM_IP_NET1[0]}
    Get Fib Entries    session    @{ips}
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[1]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_2_IP}\\"\\],\\"origin\\":\\"[a-z]
#    Log    ${resp}
#    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${VM_IP_NET1[0]}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
#    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Log    Bring down the Sub Interface on DPN2
    ${UNCONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 down
    Log    ${UNCONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ${UNCONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[1]}    ifconfig
    Should Not Contain    ${output}    eth0:1
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    10
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig
    Should Contain    ${output}    eth0:1
    Log    Verify VM1 has MIP
    ${rx_packet1_before} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ifconfig eth0:1
    Log    ${rx_packet1_before}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ${RPING_MIP_IP}
    Log    Generating the ARP requests by pinging
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET1[0]}    ping 50.1.1.110 -c 5
    Should Contain    ${output}    ${PING_REGEXP}
    Log    Validate the FIB entries in Controller
    ${output}    Get Fib Entries    session
    ${resp}=    Should Match Regexp    ${output}    destPrefix\\":\\"${FIB_ENTRY_2}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
    Log    ${resp}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_2}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}

*** Keywords ***
Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}

Presuite Cleanup
    [Documentation]    Clean the already existing tunnels and tep interfaces
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_TRANSPORTZONE}
    Log    ${resp.content}
    ${resp}    RequestsLibrary.Delete Request    session    ${TUNNEL_INTERFACES}
    Log    ${resp.content}

Create Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Create Network    ${NETWORKS[2]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Should Contain    ${NET_LIST}    ${NETWORKS[2]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[2]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[4]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET1[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET2[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET3[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET3[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET1}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET2}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET3}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    ${VM_IP_NET1}    ${DHCP_IP1}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET1}
    Log    ${VM_IP_NET1}
    Set Suite Variable    ${VM_IP_NET1}
    ${VM_IP_NET2}    ${DHCP_IP2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET2}
    Log    ${VM_IP_NET2}
    Set Suite Variable    ${VM_IP_NET2}
    ${VM_IP_NET3}    ${DHCP_IP3}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET3}
    Log    ${VM_IP_NET3}
    Set Suite Variable    ${VM_IP_NET3}
    Log    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NEUTRON_ROUTERS_API}    ${router_list}
    Log    Add Interfaces to router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}    ${VM_IP_NET3[0]}    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Log    Create a L3VPN and associate network1 and Router
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${net_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${net_id}
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    ${VM_IP_NET1[0]}    ${VM_IP_NET1[1]}    ${VM_IP_NET2[0]}    ${VM_IP_NET2[1]}    ${VM_IP_NET3[0]}
    ...    ${VM_IP_NET3[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${FIB_ENTRIES_URL}    ${vm_instances}
    Log    VALIDATING MAC IP
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Log    Check Datapath Across DPNs
    Verify Ping

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
    ${output}=    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET3[0]}    ping -c 3 ${VM_IP_NET3[1]}
    Should Contain    ${output}    ${PING_REGEXP}

Verify Flows Are Present
    [Arguments]    ${ip}
    [Documentation]    Verify Flows Are Present
    ${flow_output}=    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${resp}=    Should Contain    ${flow_output}    table=50
    Log    ${resp}
    ${resp}=    Should Contain    ${flow_output}    table=21
    Log    ${resp}
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:36
    ${resp}=    Should Match regexp    ${flow_output}    table=0.*goto_table:17
    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=50.1.1.3
    ${resp}=    Should Match regexp    ${flow_output}    table=21.*nw_dst=60.1.1.3
    ${table51_output} =    Get Lines Containing String    ${flow_output}    table=51
    Log To Console    ${table51_output}
    @{table51_output}=    Split To Lines    ${table51_output}    0    -1
    : FOR    ${line}    IN    @{table51_output}
    \    Log To Console    ${line}
    \    ${resp}=    Should Match Regexp    ${line}    ${MAC_REGEX}

Get Fib Entries
    [Arguments]    ${session}    @{vm_ip}
    [Documentation]    Get Fib table entries from ODL
    ${resp}    RequestsLibrary.Get Request    ${session}    ${FIB_ENTRIES_URL}
    Log    ${resp.content}
    : FOR    ${vm}    IN    @{vm_ip}
    \    Should Match Regexp    ${resp.content}    destPrefix\\":\\"${vm}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]

Get MAC IP
    [Documentation]    Check for MAC
    ${resp}    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_2}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    \    Should Match Regexp    ${resp.content}    destPrefix\\":\\"${vm}\/32\\",\\"label\\":\\d+,\\"nextHopAddressList\\":\\[\\"${OS_COMPUTE_1_IP}\\"\\],\\"origin\\":\\"[a-z]
