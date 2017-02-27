*** Settings ***
Documentation     Test suite to validate FT_96.4 functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
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
@{NETWORKS}       NET10    NET20    NET30    NET40    NET50    NET60
@{SUBNETS}        SUBNET1    SUBNET2    SUBNET3    SUBNET4    SUBNET5    SUBNET6
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24    40.1.1.0/24    50.1.1.0/24    60.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4    PORT5    PORT6    PORT7
...               PORT8    PORT9    PORT10    PORT11    PORT12    PORT13
@{VM_INSTANCES_DPN1}    VM11    VM21    VM31    VM41    VM51    VM61
@{VM_INSTANCES_DPN2}    VM12    VM22    VM32    VM42    VM52    VM62
@{ROUTERS}        ROUTER_1
@{ROUTER_SUBNETS}    SUBNET1    SUBNET2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
@{CREATE_RD}      ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_EXPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
@{CREATE_IMPORT_RT}    ["2200:2"]    ["2300:2"]    ["2400:2"]
${EPH1_CFG}       sudo ifconfig eth0:1 10.1.1.110 netmask 255.255.255.0 up
${EPH2_CFG}       sudo ifconfig eth0:1 50.1.1.110 netmask 255.255.255.0 up
${EPH3_CFG}       sudo ifconfig eth0:1 40.1.1.110 netmask 255.255.255.0 up

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create six networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Create Network    ${NETWORKS[2]}
    Create Network    ${NETWORKS[3]}
    Create Network    ${NETWORKS[4]}
    Create Network    ${NETWORKS[5]}
    ${NET_LIST}    List Networks
    Log    ${NET_LIST}
    Should Contain    ${NET_LIST}    ${NETWORKS[0]}
    Should Contain    ${NET_LIST}    ${NETWORKS[1]}
    Should Contain    ${NET_LIST}    ${NETWORKS[2]}
    Should Contain    ${NET_LIST}    ${NETWORKS[3]}
    Should Contain    ${NET_LIST}    ${NETWORKS[4]}
    Should Contain    ${NET_LIST}    ${NETWORKS[5]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}

Create Neutron Subnets
    [Documentation]    Create six subnets. One subnets per network
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Create SubNet    ${NETWORKS[2]}    ${SUBNETS[2]}    ${SUBNET_CIDR[2]}
    Create SubNet    ${NETWORKS[3]}    ${SUBNETS[3]}    ${SUBNET_CIDR[3]}
    Create SubNet    ${NETWORKS[4]}    ${SUBNETS[4]}    ${SUBNET_CIDR[4]}
    Create SubNet    ${NETWORKS[5]}    ${SUBNETS[5]}    ${SUBNET_CIDR[5]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[2]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[3]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[4]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[5]}
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
    [Documentation]    Create thirteen ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[4]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[5]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[2]}    ${PORT_LIST[6]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[7]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[3]}    ${PORT_LIST[8]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[4]}    ${PORT_LIST[9]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[4]}    ${PORT_LIST[10]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[5]}    ${PORT_LIST[11]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[5]}    ${PORT_LIST[12]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_DPN1[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_DPN1[1]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[5]}    ${VM_INSTANCES_DPN1[2]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[8]}    ${VM_INSTANCES_DPN1[3]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[9]}    ${VM_INSTANCES_DPN1[4]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[11]}    ${VM_INSTANCES_DPN1[5]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_DPN2[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[4]}    ${VM_INSTANCES_DPN2[1]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[6]}    ${VM_INSTANCES_DPN2[2]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[7]}    ${VM_INSTANCES_DPN2[3]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[10]}    ${VM_INSTANCES_DPN2[4]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[12]}    ${VM_INSTANCES_DPN2[5]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    60s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    : FOR    ${index}    IN RANGE    1    5
    \    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_DPN1}
    \    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease
    \    ...    @{VM_INSTANCES_DPN2}
    \    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NET10}    ${VM_IP_NET20}
    \    ${status}    ${message}    Run Keyword And Ignore Error    List Should Not Contain Value    ${VM_IPS}    None
    \    Exit For Loop If    '${status}' == 'PASS'
    \    BuiltIn.Sleep    5s
    : FOR    ${vm}    IN    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    \    Write Commands Until Prompt    nova console-log ${vm}    30s
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    Should Not Contain    ${VM_IP_NET10)    None
    Should Not Contain    ${VM_IP_NET20}    None

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET10[0]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_IP_NET10[1]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[2]    ${VM_IP_NET10[2]}    ping -c 3 ${VM_IP_NET20[2]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[2]    ${VM_IP_NET20[2]}    ping -c 3 ${VM_IP_NET10[2]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[3]    ${VM_IP_NET10[3]}    ping -c 3 ${VM_IP_NET20[3]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[3]    ${VM_IP_NET20[3]}    ping -c 3 ${VM_IP_NET10[3]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[4]    ${VM_IP_NET10[4]}    ping -c 3 ${VM_IP_NET20[4]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[4]    ${VM_IP_NET20[4]}    ping -c 3 ${VM_IP_NET10[4]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[5]    ${VM_IP_NET10[5]}    ping -c 3 ${VM_IP_NET20[5]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[5]    ${VM_IP_NET20[5]}    ping -c 3 ${VM_IP_NET10[5]}
    Should Contain    ${output}    64 bytes

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}

Add Interfaces To Router
    [Documentation]    Add Interfaces to router
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET20}
    Log    L3 Datapath test across the networks using router
    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[1]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD[0]}    exportrt=${CREATE_EXPORT_RT[0]}    importrt=${CREATE_IMPORT_RT[0]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${CREATE_RD[1]}    exportrt=${CREATE_EXPORT_RT[1]}    importrt=${CREATE_IMPORT_RT[1]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[2]}    rd=${CREATE_RD[2]}    exportrt=${CREATE_EXPORT_RT[2]}    importrt=${CREATE_IMPORT_RT[2]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[3]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[4]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[5]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${network1_id}
    Associate L3VPN To Network    networkid=${network3_id}    vpnid=${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${network3_id}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[2]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    Should Contain    ${resp}    ${network2_id}

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
    Log    Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{VM_IP_NET10}[0]    ${dst_ip_list}
    Log    Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{VM_IP_NET20}[0]    ${dst_ip_list}

Create ITM Tunnel
    [Documentation]    Checks that vxlan tunnels are created successfully. This testcase expects that the two DPNs are in the same network hence populates the gateway accordingly.
    ${node_1_dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid} =    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_1_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${subnet} =    Get Subnet    ${OS_COMPUTE_1_IP}
    ${gateway} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ITM Create Tunnel    tunneltype=vxlan    vlanid=0    prefix=${subnet}    gateway=${gateway}    ipaddress1=${OS_COMPUTE_1_IP}    dpnid1=${node_1_dpid}
    ...    portname1=${node_1_adapter}    ipaddress2=${OS_COMPUTE_2_IP}    dpnid2=${node_2_dpid}    portname2=${node_2_adapter}
    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_1_IP}
    Get DumpFlows And Ovsconfig    ${OS_COMPUTE_2_IP}
    ${output} =    ITM Get Tunnels
    Log    ${output}

Configure Enterprise Network Host
    [Documentation]    Bring up EPhosts on DPN1 & DPN2
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[1]}    ${EPH1_CFG}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[4]    ${VM_IP_NET10[4]}    ${EPH2_CFG}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[3]    ${VM_IP_NET20[3]}    ${EPH3_CFG}

Delete ITM Tunnel
    [Documentation]    Delete tunnels with specific transport-zone.
    ITM Delete Tunnel    TZA

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[2]}

Delete Router And Router Interfaces
    [Documentation]    Delete Router and Interface to the subnets
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{ROUTER_SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTERS[0]}

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}

Delete Neutron Ports
    [Documentation]    Delete Neutron Ports in the given Port List.
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}

Delete Sub Networks
    [Documentation]    Delete Sub Nets in the given Subnet List.
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}

Delete Networks
    [Documentation]    Delete Networks in the given Net List
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}
