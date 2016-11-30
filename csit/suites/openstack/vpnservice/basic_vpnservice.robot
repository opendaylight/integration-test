*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
...               AND    Enable ODL DHCP Service
...               AND    Enable ODL Karaf Log
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keyword If Test Failed    Get OvsDebugInfo
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
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{ROUTERS}        ROUTER_1    ROUTER_2
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111    4ae8cd92-48ca-49b5-94e1-b2921a261112    4ae8cd92-48ca-49b5-94e1-b2921a261113
@{VPN_NAME}       vpn1    vpn2    vpn3
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2","8800:2"]
${CREATE_IMPORT_RT}    ["2200:2","8800:2"]
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
# Values passed for extra routes
${RT_OPTIONS}     --routes type=dict list=true
${RT_CLEAR}       --routes action=clear

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
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=sg-vpnservice
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=sg-vpnservice
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=sg-vpnservice
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=sg-vpnservice
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate
    ${VM_IP_NET10}    ${DHCP_IP1}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    ${DHCP_IP2}    Wait Until Keyword Succeeds    30s    10s    Verify VMs Received DHCP Lease    @{VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    ${PING_PASS}

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
    ${interface_output} =    show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
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

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation
    Log    "Adding extra one route to VM"
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${CONFIG_EXTRA_ROUTE_IP2} =    Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IP}[1] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ifconfig
    ${EXT_RT1} =    Set Variable    destination=40.1.1.0/24,nexthop=${VM_IP_NET10[0]}
    ${EXT_RT2} =    Set Variable    destination=50.1.1.0/24,nexthop=${VM_IP_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}    ${EXT_RT2}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    Log    "Verify FIB table"
    ${vm_instances} =    Create List    @{EXTRA_NW_SUBNET}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    ${PING_PASS}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[0]
    Should Contain    ${output}    ${PING_PASS}

Delete Extra Route
    [Documentation]    Delete the extra routes
    Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    Show Router    @{ROUTERS}[0]    -D

Delete And Recreate Extra Route
    [Documentation]    Recreate multiple extra route and check data path before L3VPN creation
    Log    "Adding extra route to VM"
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${EXT_RT1} =    Set Variable    destination=40.1.1.0/24,nexthop=${VM_IP_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[0]
    Should Contain    ${output}    ${PING_PASS}
    Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    Show Router    @{ROUTERS}[0]    -D

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
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
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Log    Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{VM_IP_NET10}[0]    ${dst_ip_list}
    Log    Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{VM_IP_NET20}[0]    ${dst_ip_list}

Dissociate L3VPN To Routers
    [Documentation]    Dissociating router from L3VPN
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete Router and Interface to the subnets with L3VPN assciate
    # Asscoiate router with L3VPN
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    # Verify Router Entry removed from L3VPN
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}
    Log    "Verify FIB entries"
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements Not At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN    ${OS_COMPUTE_2_IP}

Delete Router With Unknown ID
    [Documentation]    UC_20 Delete router with unknown ID
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output} =    Write Commands Until Prompt    neutron router-delete unknowRouter    30s
    Close Connection
    Should Contain    ${output}    Unable to find router with name or id

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network1_id}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network2_id}

Verify L3VPN datapath with Networks Association
    [Documentation]    Datapath test across the networks using L3VPN with network association.
    Log    Verify FIB and Flow
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${SUBNET_CIDR}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${SUBNET_CIDR}
    Get OvsDebugInfo
    Log    L3 Datapath test across the networks 
    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network1_id}
    Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network2_id}
    Log    "Verify FIB entries"
    Wait Until Keyword Succeeds    60s    10s    Check For Elements Not At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${SUBNET_CIDR}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Delete L3VPN with unknowID
    [Documentation]    Delete L3VPN with UnknowID
    ${json_body} =    OperatingSystem.Get File    ${CURDIR}/../../../variables/vpnservice/l3vpn_delete/post_data.json
    Log    ${json_body}
    ${json_body} =    Replace String    ${json_body}    $vpnid    4ae8cd92-48ca-49b5-94e1-b2921a261119
    ${resp} =    RequestsLibrary.Post Request    session    ${CONFIG_API}/neutronvpn:deleteL3VPN    ${json_body}
    Log    ${resp.content}
    Log    ${resp.status_code}
    Should Be Equal As Strings    ${resp.status_code}    400

Verify L3VPN Datapath with network and router asscoation
    [Documentation]    Verify the datapath for L3VPN with Router and Network associate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network1_id}
    Create Router    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${ROUTERS[0]}
    Add Router Interface    ${ROUTERS[0]}    ${SUBNETS[1]}
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    Log    "Verify FIB entries and Flow table"
    ${vm_instances} =    Create List    ${SUBNET_CIDR[0]}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    5s    1s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    # Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[1]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[0]}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[2]}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
    @{VM_INSTANCES}    Collections.Combine Lists    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
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

Delete ITM Tunnel
    [Documentation]    Delete tunnels with specific transport-zone.
    ITM Delete Tunnel    TZA

*** Keywords ***
Basic Vpnservice Suite Setup
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Basic Vpnservice Suite Teardown
    Delete All Sessions

Wait For Routes To Propogate
    ${devstack_conn_id} =    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[0]
    ${net_id} =    Get Net Id    @{NETWORKS}[1]    ${devstack_conn_id}
    ${output} =    Write Commands Until Expected Prompt    sudo ip netns exec qdhcp-${net_id} ip route    ]>
    Should Contain    ${output}    @{SUBNET_CIDR}[1]

Enable ODL DHCP Service
    [Documentation]    Enable and Verify ODL DHCP service
    TemplatedRequests.Post_As_Json_Templated    folder=${CURDIR}/../../../variables/vpnservice/enable_dhcp    mapping={}    session=session
    ${resp} =    RequestsLibrary.Get Request    session    ${CONFIG_API}/dhcpservice-config:dhcpservice-config
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    "controller-dhcp-enabled":true

Enable ODL Karaf Log
    [Documentation]    Uses log:set TRACE org.opendaylight.netvirt to enable log
    Log    "Enabled ODL Karaf log for org.opendaylight.netvirt"
    ${output}=    Issue Command On Karaf Console    log:set TRACE org.opendaylight.netvirt
    Log    ${output}
