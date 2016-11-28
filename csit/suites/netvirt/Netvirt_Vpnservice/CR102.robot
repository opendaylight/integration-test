*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL Karaf Log
...               AND    Create And Verify Networks Subnets And Ports
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
Variables         ../../../variables/Variables.py

*** Variables ***
@{NETWORKS}       NET10    NET20    NET30
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22    PORT31    PORT32
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{VM_INSTANCES_NET30}    VM13    VM23
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
${MAC_REGEX}      ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})
${FIB_ENTRY_1}    10.1.1.3
${FIB_ENTRY_3}    10.1.1.4
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s 10.1.1.110 10.1.1.110
${RPING_EXP_STR}    broadcast

*** Test Cases ***
TC01
    [Documentation]    Test Case 1
    Log    Validate the Flows on DPNs
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Checking MAC-IP table in Config DS via REST
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Contain    ${resp.content}    ${FIB_ENTRY_1}
    Should Contain    ${resp.content}    ${FIB_ENTRY_3}
    Log    Checking the RX Packets Count on VM2 before ARP Broadcast
    ${output1} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ifconfig eth0
    Log    ${output1}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${output2} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ifconfig eth0
    Log    ${output2}
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    Log    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ${CONFIG_EXTRA_ROUTE_IP1}
    Sleep    30
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ifconfig
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ${RPING_MIP_IP}    
    Log    Validate the Flows on DPNs
    Log    Checking the RX Packets Count on VM2 after ARP Broadcast
    ${output1} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ifconfig eth0
    Log    ${output1}
    Log    Checking the RX Packets Count on VM1 before ARP Broadcast
    ${output2} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ifconfig eth0
    Log    ${output2}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present    ${OS_COMPUTE_2_IP}
    Log    Validate the FIB entries in Controller
    ${resp}    RequestsLibrary.Get Request    session    /restconf/config/odl-fib:fibEntries/
    Log    ${resp.content}
    ${resp}=    Should Match Regexp    ${resp.content}    "destPrefix\"+\:\"20.1.1.3\/32\"+,\"label\"+\:\\d+\,"nextHopAddressList\"+\:\[\"${OS_COMPUTE_1_IP}\"\]+\,\"origin\"+\:\"[a-z]\"+
    Log    ${resp}

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

Create And Verify Networks Subnets And Ports
    [Documentation]    UC_8 Verify the creation of two networks, two subnets and four ports using Neutron CLI
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
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/networks/    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[2]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/subnets/    ${SUBNETS}
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[4]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    /restconf/config/neutron:neutron/ports/    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_NET30[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_NET30[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET10}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET20}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    : FOR    ${VM}    IN    @{VM_INSTANCES_NET30}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    ${VM_IP_NET30}    ${DHCP_IP3}    Wait Until Keyword Succeeds    180s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET30}
    Log    ${VM_IP_NET30}
    Set Suite Variable    ${VM_IP_NET30}
    Log    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NEUTRON_ROUTERS_API}    ${router_list}
    Log    Add Interfaces to router
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[2]}
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    ${VM_IP_NET20[0]}    ${VM_IP_NET20[1]}    ${VM_IP_NET30[0]}    ${VM_IP_NET30[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    /restconf/config/odl-fib:fibEntries/    ${vm_instances}
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
    ${vm_instances} =    Create List    ${VM_IP_NET10[0]}    ${VM_IP_NET10[1]}    ${VM_IP_NET20[0]}    ${VM_IP_NET20[1]}    ${VM_IP_NET30[0]}
    ...    ${VM_IP_NET30[1]}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    /restconf/config/odl-fib:fibEntries/    ${vm_instances}
    Log    VALIDATING MAC IP
    ${resp}    RequestsLibrary.Get Request    session    /restconf/operational/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Log    Check Datapath Across DPNs
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET20[0]}
    Should Contain    ${output}    64 bytes
    Log    Only for check...to be removed
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET30[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET30[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET30[0]}    ping -c 3 ${VM_IP_NET20[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[2]    ${VM_IP_NET30[0]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes
