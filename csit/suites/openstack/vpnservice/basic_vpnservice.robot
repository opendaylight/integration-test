*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get OvsDebugInfo
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
@{VM_INSTANCES}    VM11    VM21    VM12    VM22
@{NET10_VM_IPS}    10.1.1.3    10.1.1.4
@{NET20_VM_IPS}    20.1.1.3    20.1.1.4
@{ROUTERS}        ROUTER_1    ROUTER_2
# Values passed by the calling method to API
@{CREATE_ID}      "4ae8cd92-48ca-49b5-94e1-b2921a261111"    "4ae8cd92-48ca-49b5-94e1-b2921a261112"    "4ae8cd92-48ca-49b5-94e1-b2921a261113"
@{CREATE_NAME}    "vpn1"    "vpn2"    "vpn3"
${CREATE_ROUTER_DISTINGUISHER}    ["2200:2"]
${CREATE_EXPORT_RT}    ["3300:2","8800:2"]
${CREATE_IMPORT_RT}    ["3300:2","8800:2"]
${CREATE_TENANT_ID}    "6c53df3a-3456-11e5-a151-feff819c1111"
@{VPN_INSTANCE}    vpn_instance_template.json
@{VPN_INSTANCE_NAME}    4ae8cd92-48ca-49b5-94e1-b2921a2661c7    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
# Values passed for extra routes
${EXT_RT1}        destination=40.1.1.0/24,nexthop=10.1.1.3
${EXT_RT2}        destination=50.1.1.0/24,nexthop=10.1.1.3
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

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    ${SUB_LIST}    List Subnets
    Log    ${SUB_LIST}
    Should Contain    ${SUB_LIST}    ${SUBNETS[0]}
    Should Contain    ${SUB_LIST}    ${SUBNETS[1]}

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}

Check OpenDaylight Neutron Ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    ${resp}    RequestsLibrary.Get Request    session    ${NEUTRON_PORTS_API}
    Log    ${resp.content}
    Should be Equal As Strings    ${resp.status_code}    200

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES[0]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES[1]}    ${OS_COMPUTE_2_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES[2]}    ${OS_COMPUTE_1_IP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES[3]}    ${OS_COMPUTE_2_IP}
    Log    Check for routes
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[0]    ping -c 3 @{NET10_VM_IPS}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    @{NET20_VM_IPS}[0]    ping -c 3 @{NET20_VM_IPS}[1]
    Should Contain    ${output}    64 bytes

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    ${dst_ip_list} =    Create List    @{NET10_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET20_VM_IPS}[0]    @{NET20_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{NET10_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}
    ${dst_ip_list} =    Create List    @{NET20_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list} =    Create List    @{NET10_VM_IPS}[0]    @{NET10_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{NET20_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation
    Log    "Adding extra one route to VM"
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP1}
    ${CONFIG_EXTRA_ROUTE_IP2} =    Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IP}[1] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[0]    ifconfig
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}    ${EXT_RT2}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    @{NET20_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    @{NET10_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[0]
    Should Contain    ${output}    64 bytes

Delete Extra Route
    [Documentation]    Delete the extra routes
    Update Router    @{ROUTERS}[0]    ${RT_CLEAR}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[0]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Get L3VPN    ${CREATE_ID[0]}

Associate L3VPN to Routers
    [Documentation]    Associating router to L3VPN
    [Tags]    Associate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}

Dissociate L3VPN to Routers
    [Documentation]    Dissociating router to L3VPN
    [Tags]    Dissociate
    ${devstack_conn_id}=    Get ControlNode Connection
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    ${router_id}    ${VPN_INSTANCE_NAME[1]}

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_NAME[1]}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_NAME[1]}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${devstack_conn_id} =    Get ControlNode Connection
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_NAME[1]}
    Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_NAME[1]}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    ${CREATE_ID[0]}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    ${ROUTERS[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[0]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[1]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Create L3VPN    ${VPN_INSTANCE[0]}    CREATE_ID=${CREATE_ID[2]}    CREATE_EXPORT_RT=${CREATE_EXPORT_RT}    CREATE_IMPORT_RT=${CREATE_IMPORT_RT}    CREATE_TENANT_ID=${CREATE_TENANT_ID}
    VPN Get L3VPN    ${CREATE_ID[0]}
    VPN Get L3VPN    ${CREATE_ID[1]}
    VPN Get L3VPN    ${CREATE_ID[2]}

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs
    VPN Delete L3VPN    ${CREATE_ID[0]}
    VPN Delete L3VPN    ${CREATE_ID[1]}
    VPN Delete L3VPN    ${CREATE_ID[2]}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Vm Instances
    [Documentation]    Delete Vm instances in the given Instance List
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
    [Documentation]    Checks that vxlan tunnels are created successfully. The proc expects that the two DPNs are in the same network and populates the gateway accordingly.
    ${node_1_dpid} =    Get DPID    ${OS_COMPUTE_1_IP}
    ${node_2_dpid} =    Get DPID    ${OS_COMPUTE_2_IP}
    ${node_1_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_1_IP}
    ${node_2_adapter} =    Get Ethernet Adapter    ${OS_COMPUTE_2_IP}
    ${first_two_octets}    ${third_octet}    ${last_octet}=    Split String From Right    ${OS_COMPUTE_1_IP}    .    2
    ${subnet} =    Set Variable    ${first_two_octets}.0.0/16
    ${gateway} =    Get Default Gateway    ${OS_COMPUTE_1_IP}
    ITM Create Tunnel    tunnel-type=vxlan    vlan-id=0    ip-address1="${OS_COMPUTE_1_IP}"    dpn-id1=${node_1_dpid}    portname1="${node_1_adapter}"    ip-address2="${OS_COMPUTE_2_IP}"
    ...    dpn-id2=${node_2_dpid}    portname2="${node_2_adapter}"    prefix="${subnet}"    gateway-ip="${gateway}"
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
