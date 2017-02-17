*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Basic Vpnservice Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORTS_CN1}      PORT11    PORT21
@{PORTS_CN2}      PORT12    PORT22
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
@{CREATE_RD}      ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
# Values passed for extra routes
${RT_OPTIONS}     --routes type=dict list=true
${RT_CLEAR}       --routes action=clear
${DISPATCHER_TABLE}    17
${GWMAC_TABLE}    19
${ARP_RESPONSE_TABLE}    81
${L3_TABLE}       21
${ELAN_TABLE}     51
${ARP_RESPONSE_REGEX}    arp,arp_op=2 actions=CONTROLLER:65535,resubmit\\(,${DISPATCHER_TABLE}\\)
${ARP_REQUEST_REGEX}    arp,arp_op=1 actions=group:\\d+
${ARP_REQUEST_GROUP_REGEX}    actions=CONTROLLER:65535,bucket=actions=resubmit\\(,${DISPATCHER_TABLE}\\),bucket=actions=resubmit\\(,${ARP_RESPONSE_TABLE}\\)
${MAC_REGEX}      (([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2}))
${IP_REGEX}       (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])
${NETWORKASS_GWMACTABLE_REGEX}    dl_dst=${MAC_REGEX} actions=goto_table:21

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    Neutron Security Group Create    sg-vpnservice
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    sg-vpnservice    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    ${allowed_address_pairs_args}=    Set Variable    --allowed-address-pairs type=dict list=true ip_address=${EXTRA_NW_SUBNET[0]} ip_address=${EXTRA_NW_SUBNET[1]}
    Create Port    ${NETWORKS[0]}    ${PORTS_CN1[0]}    sg=sg-vpnservice    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[0]}    ${PORTS_CN2[0]}    sg=sg-vpnservice    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORTS_CN1[1]}    sg=sg-vpnservice    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORTS_CN2[1]}    sg=sg-vpnservice    additional_args=${allowed_address_pairs_args}
    ${PORT_LIST} =    Create List    @{PORTS_CN1}    @{PORTS_CN2}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}
    #Get Port MAC Address
    ${PORTS_MACADDR_CN1} =    Get Ports MacAddr    ${PORTS_CN1}
    Set Suite Variable    ${PORTS_MACADDR_CN1}
    ${PORTS_MACADDR_CN2} =    Get Ports MacAddr    ${PORTS_CN2}
    Set Suite Variable    ${PORTS_MACADDR_CN2}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORTS_CN1[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORTS_CN2[0]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORTS_CN1[1]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORTS_CN2[1]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    : FOR    ${index}    IN RANGE    1    5
    \    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_NET10}
    \    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_NET20}
    \    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NET10}    ${VM_IP_NET20}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${VM_IPS}    None
    \    Exit For Loop If    '${status}' == 'PASS'
    \    BuiltIn.Sleep    5s
    : FOR    ${vm}    IN    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    \    Write Commands Until Prompt    nova console-log ${vm}    30s
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    Should Not Contain    ${VM_IP_NET10)    None
    Should Not Contain    ${VM_IP_NET20}    None
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    ...    AND    Get Suite Teardown Debugs

#Check ELAN Datapath Traffic Within The Networks
#    [Documentation]    Checks datapath within the same network with different vlans.
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
#    Should Contain    ${output}    64 bytes
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET20[1]}
#    Should Contain    ${output}    64 bytes

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    Get Gateway MAC And IP Address    ${ROUTERS[0]}
    Log    ${GWMAC_ADDRS}
    Set Suite Variable    ${GWMAC_ADDRS}
    Log    ${GWIP_ADDRS}
    Set Suite Variable    ${GWIP_ADDRS}

#Check L3_Datapath Traffic Across Networks With Router
#    [Documentation]    Datapath test across the networks using router for L3.
#    Log    Verification of FIB Entries and Flow
#    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
#    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10}
#    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET20}
#    #Verify GWMAC Table
#    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
#    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
#    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
#    Log    L3 Datapath test across the networks using router
#    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
#    Log    ${dst_ip_list}
#    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[1]}    ${dst_ip_list}
#    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
#    Log    ${dst_ip_list}
#    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}
#
#Verify FLOWTABLE Packet Count for inter and intra network
#    [Documentation]    Verify packet count before and after ping for L2 and L3 Datapath validation.
#    # Verify FIB and Flow TABLE
#    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
#    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
#    ${n_Elan_Pkts_1}    ${n_vpn_Pkts_1}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[1]}    ${PORTS_MACADDR_CN2[0]}
#    Log    Datapath test within same network
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
#    Should Contain    ${output}    64 bytes
#    ${n_Elan_Pkts_2}    ${n_vpn_Pkts_2}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[1]}    ${PORTS_MACADDR_CN2[0]}
#    Should Be True    ${n_Elan_Pkts_1} < ${n_Elan_Pkts_2}
#    Should Be True    ${n_vpn_Pkts_1} == ${n_vpn_Pkts_2}
#    Log    Datapath test with different network
#    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET10[1]}
#    Should Contain    ${output}    64 bytes
#    ${n_Elan_Pkts_3}    ${n_vpn_Pkts_3}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[1]}    ${PORTS_MACADDR_CN2[0]}
#    Should Be True    ${n_vpn_Pkts_3} > ${n_vpn_Pkts_2}

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD[0]}    exportrt=${CREATE_EXPORT_RT[0]}    importrt=${CREATE_IMPORT_RT[0]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across the networks using L3VPN with router association.
    Log    Verify VPN interfaces, FIB entries and Flow table
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/l3vpn:vpn-interfaces/    ${vm_instances}
    ${RD} =    Strip String    ${CREATE_RD[0]}    characters="[]
    Log    ${RD}
    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    Wait Until Keyword Succeeds    60s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    60s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    #Verify GWMAC Table
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    Log    Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{VM_IP_NET10}[0]    ${dst_ip_list}
    Log    Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{VM_IP_NET20}[0]    ${dst_ip_list}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces
    [Documentation]    Delete Router and Interface to the subnets with L3VPN assciate
    # Asscoiate router with L3VPN
    #${devstack_conn_id} =    Get ControlNode Connection
    #${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    #Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    #${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    #Should Contain    ${resp}    ${router_id}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTERS[0]}
    #${router_list} =    Create List    ${ROUTERS[0]}
    #Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    # Verify Router Entry removed from L3VPN
    #${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    #Should Not Contain    ${resp}    ${router_id}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network1_id}
    Should Contain    ${resp}    ${network2_id}

Verify L3VPN datapath with Networks Association
    [Documentation]    Datapath test across the networks using L3VPN with network association.
    Log    Verify FIB and Flow
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/l3vpn:vpn-interfaces/    ${vm_instances}
    ${RD} =    Strip String    ${CREATE_RD[0]}    characters="[]
    Log    ${RD}
    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}    n_entrys=2
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_2_IP}    n_entrys=2
    Log    L3 Datapath test across the networks
    #${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    #Log    ${dst_ip_list}
    #Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${dst_ip_list}
    #${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    #Log    ${dst_ip_list}
    #Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes


Verify Datapath After OVS Restart
    [Documentation]    Verify datapath after OVS restart
    Log    Restarting OVS1 and OVS2
    Restart OVSDB    ${OS_COMPUTE_1_IP}
    Restart OVSDB    ${OS_COMPUTE_2_IP}
    Log    Checking the OVS state and Flow table after restart
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify OVS Reports Connected    tools_system=${OS_COMPUTE_2_IP}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}    n_entrys=2
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_2_IP}    n_entrys=2
    Log    Verify Data path test
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS[1]}    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes

Verify Datapath After Reboot Nova VM Instance
    [Documentation]    Verify datapath after reboot nova Vm instance.
    Reboot Nova VM    ${VM_INSTANCES_NET20[0]}
    Wait Until Keyword Succeeds    30s    10s    Verify VM Is ACTIVE    ${VM_INSTANCES_NET20[0]}
    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Should Not Contain    ${VM_IP_NET20}    None
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    60s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}    n_entrys=2
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_2_IP}    n_entrys=2
    Log    Verify Data path test
    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS[1]}    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes

#Verify Datapath After Recreate VM Instance
#    [Documentation]    Verify datapath after recreating Vm instance
#    Log    Delete VM and verify flows updated
#    Delete Vm Instance    ${VM_INSTANCES_NET10[0]}
#    Wait Until Keyword Succeeds    60s    10s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}    n_entrys=1
#    Remove RSA Key From KnowHosts    ${VM_IP_NET10[0]}
#    Log    ReCreate VM and verify flow updated
#    Create Vm Instance With Port On Compute Node    ${PORTS_CN1[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}
#    Wait Until Keyword Succeeds    30s    10s    Verify VM Is ACTIVE    ${VM_INSTANCES_NET10[0]}
#    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    60s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET10}
#    Log    ${VM_IP_NET10}
#    Set Suite Variable    ${VM_IP_NET10}
#    Wait Until Keyword Succeeds    60s    10s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}    n_entrys=2
#    Log    Verify Data path test
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
#    Should Contain    ${output}    64 bytes
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[1]}    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET10[0]}
#    Should Contain    ${output}    64 bytes

#Verify Datapath After Migrate VM Instance
#    [Documentation]    Verify datapath after migrate Vm instance
#    Log    Migrate VM instance and verify flows updated
#    Migrate NOVA VM Instance    ${VM_INSTANCES_NET20[0]}
#    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
#    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/l3vpn:vpn-interfaces/    ${vm_instances}
#    ${RD} =    Strip String    ${CREATE_RD[0]}    characters="[]
#    Log    ${RD}
#    Wait Until Keyword Succeeds    60s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
#    Wait Until Keyword Succeeds    60s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
#    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_2_IP}    n_entrys=3
#    Log    Verify Data path test
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
#    Should Contain    ${output}    64 bytes
#    ${output} =    Execute Command on VM Instance    ${NETWORKS[1]}    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET10[0]}
#    Should Contain    ${output}    64 bytes

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network1_id}
    Should Not Contain    ${resp}    ${network2_id}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify GWMAC Flow Entry for Network With L3VPN    ${OS_COMPUTE_2_IP}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

Delete Neutron Ports
    [Documentation]    Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORTS_CN1}    @{PORTS_CN2}
    \    Delete Port    ${Port}

Delete Sub Networks
    [Documentation]    Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete SecurityGroup    sg-vpnservice
    Close All Connections

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[0]
    ${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[1]

Verify GWMAC Entry On ODL
    [Arguments]    ${GWMAC_ADDRS}
    [Documentation]    get ODL GWMAC table entry
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/neutronvpn:neutron-vpn-portip-port-data/
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
    \    Should Contain    ${resp.content}    ${macAdd}

Get Gateway MAC And IP Address
    [Arguments]    ${router_Name}
    [Documentation]    Get Gateway mac and IP Address
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-port-list ${router_Name}    30s
    @{MacAddr-list} =    Get Regexp Matches    ${output}    ${MAC_REGEX}
    @{IpAddr-list} =    Get Regexp Matches    ${output}    ${IP_REGEX}
    [Return]    ${MacAddr-list}    ${IpAddr-list}

Verify GWMAC Flow Entry On Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${group_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-groups br-int
    Log    ${group_output}
    #Verify DISPATCHER_TABLE - 17
    Should Contain    ${flow_output}    table=${DISPATCHER_TABLE}
    ${dispatcher_table} =    Get Lines Containing String    ${flow_output}    table=${DISPATCHER_TABLE}
    Log    ${dispatcher_table}
    Should Contain    ${dispatcher_table}    goto_table:${GWMAC_TABLE}
    Should Not Contain    ${dispatcher_table}    goto_table:${ARP_RESPONSE_TABLE}
    #Verify GWMAC_TABLE - 19
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    #Verify GWMAC address present in table 19
    : FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
    \    Should Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}
    #verify Miss entry
    Should Contain    ${gwmac_table}    actions=resubmit(,17)
    #arp request and response
    Should Match Regexp    ${gwmac_table}    ${ARP_RESPONSE_REGEX}
    ${match} =    Should Match Regexp    ${gwmac_table}    ${ARP_REQUEST_REGEX}
    ${groupID} =    Split String    ${match}    separator=:
    Log    groupID
    Verify ARP REQUEST in groupTable    ${group_output}    ${groupID[1]}
    #Verify ARP_RESPONSE_TABLE - 81
    Should Contain    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    ${arpResponder_table} =    Get Lines Containing String    ${flow_output}    table=${ARP_RESPONSE_TABLE}
    Log    ${arpResponder_table}
    Should Contain    ${arpResponder_table}    priority=0 actions=drop
    : FOR    ${macAdd}    ${ipAdd}    IN ZIP    ${GWMAC_ADDRS}    ${GWIP_ADDRS}
    \    ${ARP_RESPONSE_IP_MAC_REGEX} =    Set Variable    arp_tpa=${ipAdd},arp_op=1 actions=.*,set_field:${macAdd}->eth_src
    \    Should Match Regexp    ${arpResponder_table}    ${ARP_RESPONSE_IP_MAC_REGEX}

Verify ARP REQUEST in groupTable
    [Arguments]    ${group_output}    ${Group-ID}
    [Documentation]    get flow dump for group ID
    Should Contain    ${group_output}    group_id=${Group-ID}
    ${arp_group} =    Get Lines Containing String    ${group_output}    group_id=${Group-ID}
    Log    ${arp_group}
    Should Match Regexp    ${arp_group}    ${ARP_REQUEST_GROUP_REGEX}

Verify GWMAC Flow Entry Removed From Flow Table
    [Arguments]    ${cnIp}
    [Documentation]    Verify the GWMAC Table, ARP Response table and Dispatcher table.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    #Verify GWMAC_TABLE - 19
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    #Verify GWMAC address present in table 19
    : FOR    ${macAdd}    IN    @{GWMAC_ADDRS}
    \    Should Not Contain    ${gwmac_table}    dl_dst=${macAdd} actions=goto_table:${L3_TABLE}

Verify GWMAC Flow Entry for Network With L3VPN
    [Arguments]    ${cnIp}    ${n_entrys}=0
    [Documentation]    Verify the GWMAC Table present when network assciate with L3VPN.
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    #Get GWMAC_TABLE - 19
    Should Contain    ${flow_output}    table=${GWMAC_TABLE}
    ${gwmac_table} =    Get Lines Containing String    ${flow_output}    table=${GWMAC_TABLE}
    Log    ${gwmac_table}
    ${match_list} =    Get Regexp Matches    ${gwmac_table}    ${NETWORKASS_GWMACTABLE_REGEX}
    ${match_count} =    Get Length    ${match_list}
    Should Be Equal As Integers    ${match_count}    ${n_entrys}

Get Ports MacAddr
    [Arguments]    ${portName_list}
    [Documentation]    Retrieve the port MacAddr for the given list of port name and return the MAC address list.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${MacAddr-list}    Create List
    : FOR    ${portName}    IN    @{portName_list}
    \    ${output} =    Write Commands Until Prompt    neutron port-list | grep "${portName}" | awk '{print $6}'    30s
    \    Log    ${output}
    \    ${splitted_output}=    Split String    ${output}    ${EMPTY}
    \    ${macAddr}=    Get from List    ${splitted_output}    0
    \    Log    ${macAddr}
    \    Append To List    ${MacAddr-list}    ${macAddr}
    [Return]    ${MacAddr-list}

Get PacketCount from Flow Table
    [Arguments]    ${cnIp}    ${dest_ip}    ${dest_mac}
    [Documentation]    Get the packet count from given table using the destination nw_dst=ip or dl_dst=mac
    ${ELAN_REGEX} =    Set Variable    table=${ELAN_TABLE}, n_packets=\\d+,\\s.*,dl_dst=${dest_mac}
    ${L3VPN_REGEX} =    Set Variable    table=${L3_TABLE}, n_packets=\\d+,\\s.*,nw_dst=${dest_ip}
    ${PACKET_COUNT_REGEX} =    Set Variable    n_packets=\\d+
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${ELAN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_ELAN} =    Get from List    ${n_packets}    1
    ${n_packets_ELAN} =    Convert To Integer    ${n_packets_ELAN}
    Log    ${n_packets_ELAN}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${L3VPN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_L3VPN}=    Get from List    ${n_packets}    1
    ${n_packets_L3VPN} =    Convert To Integer    ${n_packets_L3VPN}
    Log    ${n_packets_L3VPN}
    [Return]    ${n_packets_ELAN}    ${n_packets_L3VPN}

Reboot Nova VM
    [Arguments]    ${vm_name}
    [Documentation]    Reboot NOVA VM
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova reboot --poll ${vm_name}    30s
    Log    ${output}
    Wait Until Keyword Succeeds    35s    10s    Verify VM Is ACTIVE    ${vm_name}
    Close Connection

Remove RSA Key From KnowHosts
    [Arguments]    ${vm_ip}
    [Documentation]    Remove RSA
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo cat /root/.ssh/known_hosts    30s
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo ssh-keygen -f "/root/.ssh/known_hosts" -R ${vm_ip}    30s
    Log    ${output}
    ${output}=    Write Commands Until Prompt    sudo cat "/root/.ssh/known_hosts"    30s
    Log    ${output}
    Close Connection

Restart OVSDB
    [Arguments]    ${ovs_ip}
    [Documentation]    Restart the OVS node without cleaning the current configuration.
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl stop
    Log    ${output}
    ${output} =    Utils.Run Command On Mininet    ${ovs_ip}    sudo /usr/share/openvswitch/scripts/ovs-ctl start
    Log    ${output}

Migrate NOVA VM Instance
    [Documentation]    Migrate NOVA VM 
    [Arguments]    ${vm_name}
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    nova migrate --poll ${vm_name}     30s
    Log    ${output}
    Wait Until Keyword Succeeds    60s    10s    Verify VM Is ACTIVE    ${vm_name}
    ${output}=    Write Commands Until Prompt    nova resize-confirm ${vm_name}     30s
    Log    ${output}
    Close Connection
