*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Basic Vpnservice Suite Setup
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
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNETS_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT11    PORT21    PORT12    PORT22
@{VM_INSTANCES_NET10}    VM11    VM21
@{VM_INSTANCES_NET20}    VM12    VM22
@{ROUTERS}        ROUTER_1
@{EXTRA_NW_IP}    40.1.1.2    50.1.1.2
@{EXTRA_NW_SUBNET}    40.1.1.0/24    50.1.1.0/24
${SECURITY_GROUP}    sg-vpnservice
${UPDATE_NETWORK}    UpdateNetwork
${UPDATE_SUBNET}    UpdateSubnet
${UPDATE_PORT}    UpdatePort

*** Test Cases ***
Create Neutron Networks
    [Documentation]    Create two networks
    # TODO: Many of these steps to verify if updates occurred should be in a different suite
    # that is checking for such operations.
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    Update Network    ${NETWORKS[0]}    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    Show Network    ${NETWORKS[0]}
    Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    [Documentation]    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNETS_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNETS_CIDR[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    Update SubNet    ${SUBNETS[0]}    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    Show SubNet    ${SUBNETS[0]}
    Should Contain    ${output}    ${UPDATE_SUBNET}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Neutron Ports
    [Documentation]    Create four ports under previously created subnets
    ${allowed_address_pairs_args}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    --allowed-address ip_address=${EXTRA_NW_SUBNET[0]} --allowed-address ip_address=${EXTRA_NW_SUBNET[1]}    --allowed-address ip-address=${EXTRA_NW_SUBNET[0]} --allowed-address ip-address=${EXTRA_NW_SUBNET[1]}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}
    ${PORTS_MACADDR} =    Get Ports MacAddr    ${PORT_LIST}
    Set Suite Variable    ${PORTS_MACADDR}
    Update Port    ${PORT_LIST[0]}    additional_args=--description ${UPDATE_PORT}
    ${output} =    Show Port    ${PORT_LIST[0]}
    Should Contain    ${output}    ${UPDATE_PORT}

Create Nova VMs
    [Documentation]    Create Vm instances on compute node with port
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_NET10[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_NET10[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_NET20[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_NET20[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    @{VM_IP_NET10}    ${DHCP_IP1} =    Get VM IPs    @{VM_INSTANCES_NET10}
    @{VM_IP_NET20}    ${DHCP_IP2} =    Get VM IPs    @{VM_INSTANCES_NET20}
    Set Suite Variable    @{VM_IP_NET10}
    Set Suite Variable    @{VM_IP_NET20}
    Should Not Contain    ${VM_IP_NET10}    None
    Should Not Contain    ${VM_IP_NET20}    None
    Should Not Contain    ${DHCP_IP1}    None
    Should Not Contain    ${DHCP_IP2}    None
    Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS_CIDR}
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES_NET10}    @{VM_INSTANCES_NET20}
    ...    AND    Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes

Create Routers
    [Documentation]    Create Router
    Create Router    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${ROUTER_URL}    ${ROUTERS}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTERS[0]}
    Set Suite Variable    ${GWMAC_ADDRS}
    Set Suite Variable    ${GWIP_ADDRS}

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    Datapath test across the networks using router for L3.
    Log    Verification of FIB Entries and Flow
    ${cn1_conn_id} =    Start Packet Capture on Node    ${OS_COMPUTE_1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Start Packet Capture on Node    ${OS_COMPUTE_2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    10s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    ${dst_ip_list} =    Create List    ${VM_IP_NET10[1]}    @{VM_IP_NET20}
    Test Operations From Vm Instance    ${NETWORKS[0]}    ${VM_IP_NET10[0]}    ${dst_ip_list}
    ${dst_ip_list} =    Create List    ${VM_IP_NET20[1]}    @{VM_IP_NET10}
    Test Operations From Vm Instance    ${NETWORKS[1]}    ${VM_IP_NET20[0]}    ${dst_ip_list}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    [Documentation]    Add multiple extra routes and check data path before L3VPN creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${CONFIG_EXTRA_ROUTE_IP2} =    Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IP}[1] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ifconfig
    ${EXT_RT1} =    Set Variable    destination=40.1.1.0/24,gateway=${VM_IP_NET10[0]}
    ${EXT_RT2} =    Set Variable    destination=50.1.1.0/24,gateway=${VM_IP_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}    ${RT_OPTIONS}    ${EXT_RT2}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    ${vm_instances} =    Create List    @{EXTRA_NW_SUBNET}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[1]    ${VM_IP_NET20[1]}    ping -c 3 @{EXTRA_NW_IP}[1]
    Should Contain    ${output}    64 bytes
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[0]
    Should Contain    ${output}    64 bytes

Delete Extra Route
    [Documentation]    Delete the extra routes
    Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    Show Router    @{ROUTERS}[0]    -D

Delete And Recreate Extra Route
    [Documentation]    Recreate multiple extra route and check data path before L3VPN creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[0]}    ${CONFIG_EXTRA_ROUTE_IP1}
    ${EXT_RT1} =    Set Variable    destination=40.1.1.0/24,gateway=${VM_IP_NET10[0]}
    ${cmd} =    Catenate    ${RT_OPTIONS}    ${EXT_RT1}
    Update Router    @{ROUTERS}[0]    ${cmd}
    Show Router    @{ROUTERS}[0]    -D
    ${output} =    Execute Command on VM Instance    @{NETWORKS}[0]    ${VM_IP_NET10[1]}    ping -c 3 @{EXTRA_NW_IP}[0]
    Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    [Teardown]    Run Keywords    Update Router    @{ROUTERS}[0]    ${RT_CLEAR}
    ...    AND    Show Router    @{ROUTERS}[0]    -D
    ...    AND    Get Test Teardown Debugs

Create L3VPN
    [Documentation]    Creates L3VPN and verify the same
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    Log    @{RDS}[0]
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across the networks using L3VPN with router association.
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    10s    Check For Elements At URI    ${VPN_IFACES_URL}    ${vm_instances}
    ${RD} =    Strip String    ${RDS[0]}    characters="[]
    Wait Until Keyword Succeeds    60s    15s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    Wait Until Keyword Succeeds    60s    15s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    60s    15s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    Wait Until Keyword Succeeds    30s    15s    Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    Wait Until Keyword Succeeds    30s    15s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    15s    Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    Log    Check datapath from network1 to network2
    ${dst_ip_list} =    Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    Test Operations From Vm Instance    ${NETWORKS[0]}    @{VM_IP_NET10}[0]    ${dst_ip_list}
    Log    Check datapath from network2 to network1
    ${dst_ip_list} =    Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    Test Operations From Vm Instance    ${NETWORKS[1]}    @{VM_IP_NET20}[0]    ${dst_ip_list}

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    [Documentation]    Delete Router and Interface to the subnets with L3VPN assciate
    ${router_id}=    Get Router Id    ${ROUTERS[0]}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${router_id}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTERS[0]}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTERS[0]}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    Delete Router    ${ROUTERS[0]}
    ${router_output} =    List Routers
    Should Not Contain    ${router_output}    ${ROUTERS[0]}
    ${router_list} =    Create List    ${ROUTERS[0]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${router_id}
    Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Delete Router With NonExistentRouter Name
    [Documentation]    Delete router with nonExistentRouter name
    ${rc}    ${output}=    Run And Return Rc And Output    neutron router-delete nonExistentRouter
    Should Match Regexp    ${output}    Unable to find router with name or id 'nonExistentRouter'|Unable to find router\\(s\\) with id\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Associate L3VPN To Network    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network1_id}
    Associate L3VPN To Network    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${network2_id}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${network1_id} =    Get Net Id    ${NETWORKS[0]}    ${devstack_conn_id}
    ${network2_id} =    Get Net Id    ${NETWORKS[1]}    ${devstack_conn_id}
    Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network1_id}
    Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Not Contain    ${resp}    ${network2_id}

Delete L3VPN
    [Documentation]    Delete L3VPN
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${RDS[0]}    exportrt=${RDS[0]}    importrt=${RDS[0]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[1]}    name=${VPN_NAME[1]}    rd=${RDS[1]}    exportrt=${RDS[1]}    importrt=${RDS[1]}    tenantid=${tenant_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[2]}    name=${VPN_NAME[2]}    rd=${RDS[2]}    exportrt=${RDS[2]}    importrt=${RDS[2]}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[1]}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID[2]}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    Log    This test will be added in the next patch

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[1]}
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[2]}
