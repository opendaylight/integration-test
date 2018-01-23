*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${num_of_network}    3
${num_of_ports_per_host}    3
${num_of_vms_per_host}    3
${SECURITY_GROUP}    vpn_sg
${PORT_NEW}       vpn_net_1_port_new
${VM_NAME_NEW}    vpn_net_1_vm_new
${NUM_OF_L3VPN}    3
${AS_ID}          100
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${RUN_CONFIG}     show running-config
${BGP_ROUTE_CMD}    show ip bgp vrf 2200:2
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{NETWORKS}       vpn_net_1    vpn_net_2    vpn_net_3
@{SUBNETS}        vpn_sub_1    vpn_sub_2    vpn_sub_3
@{PORTS}          vpn_net_1_port_1    vpn_net_2_port_1    vpn_net_3_port_1    vpn_net_1_port_2    vpn_net_2_port_2    vpn_net_3_port_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24    30.1.1.0/24
@{SUBNET_CIDRS_1}    10.1.1.0/24    20.1.1.0/24
@{PORTS_HOST1}    vpn_net_1_port_1    vpn_net_2_port_1    vpn_net_3_port_1
@{PORTS_HOST2}    vpn_net_1_port_2    vpn_net_2_port_2    vpn_net_3_port_2
@{VMS_HOST1}      vpn_net_1_vm_1    vpn_net_2_vm_1    vpn_net_3_vm_1
@{VMS_HOST2}      vpn_net_1_vm_2    vpn_net_2_vm_2    vpn_net_3_vm_2
@{NET_1_VMS}      vpn_net_1_vm_1    vpn_net_1_vm_2
@{NET_2_VMS}      vpn_net_2_vm_1    vpn_net_2_vm_2
@{NET_3_VMS}      vpn_net_3_vm_1    vpn_net_3_vm_2
${ROUTER}         vpn_router
${INVALID_VPN_INSTANCE_ID}    AAAAAAAA-4848-4949-9494-666666666666
@{EXTRA_NW_IP}    71.1.1.2    72.1.1.2    
@{EXTRA_NW_SUBNET}    71.1.1.0/24    72.1.1.0/24
${UPDATE_NETWORK}    UpdateNetwork
${UPDATE_SUBNET}    UpdateSubnet
${UPDATE_PORT}    UpdatePort
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441    4ae8cd92-48ca-49b5-94e1-b2921a261442    4ae8cd92-48ca-49b5-94e1-b2921a261443
@{VPN_NAMES}      vpn_1    vpn_2    vpn_3
@{RDS}            ["2200:2"]    ["2300:2"]    ["2400:2"]
${CREATE_RT}      ["2200:2","2300:2","2400:2"]
${RT_LIST_1}      ["2200:2","2300:2"]
${RT_LIST_2}      ["2200:2","2400:2"]
@{DCGW_RD}        2200:2    2300:2    2400:2
@{LOOPBACK_IPS}    5.5.5.2    2.2.2.2    3.3.3.3
@{LOOPBACK_NAMES}    int1    int2    int3

*** Test Cases ***
Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create Neutron Networks
    # TODO: Many of these steps to verify if updates occurred should be in a different suite
    # that is checking for such operations.
    : FOR    ${NET}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    : FOR    ${index}    IN RANGE    0    ${num_of_network}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNET_CIDRS}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}

Add Ssh Allow All Rule
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Neutron Ports
    ${allowed_address_pairs_args}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    --allowed-address ip_address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip_address=@{EXTRA_NW_SUBNET}[1]    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1]
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_host}
    \    Create Port    @{NETWORKS}[${index}]    @{PORTS_HOST1}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_host}
    \    Create Port    @{NETWORKS}[${index}]    @{PORTS_HOST2}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}
    ${PORTS_MACADDR} =    Get Ports MacAddr    ${PORTS}
    Set Suite Variable    ${PORTS_MACADDR}
    Update Port    @{PORTS}[0]    additional_args=--description ${UPDATE_PORT}
    ${output} =    Show Port    @{PORTS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_PORT}

Create Router
    OpenStackOperations.Create Router    ${ROUTER}
    ${router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}

Create Nova VMs
    : FOR    ${index}    IN RANGE    0    ${num_of_vms_per_host}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST1}[${index}]    @{VMS_HOST1}[${index}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    : FOR    ${index}    IN RANGE    0    ${num_of_vms_per_host}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST2}[${index}]    @{VMS_HOST2}[${index}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS} 
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS} 
    BuiltIn.Set Suite Variable    @{NET_3_VM_IPS} 
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    @{NET_3_VM_IPS}    None 
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Set Suite Variable    ${tenant_id}
    BuiltIn.Log    @{RDS}[0]
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}

Check L3_Datapath Traffic Across Networks With Router
    ${cn1_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CMP1_IP}    file_Name=tcpDumpCN1
    ${cn2_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CMP2_IP}    file_Name=tcpDumpCN2
    ${os_conn_id} =    Tcpdump.Start Packet Capture on Node    ${OS_CONTROL_NODE_IP}    file_Name=tcpDumpOS
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP2_IP}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_CMP2_IP}
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]    @{NET_2_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${dst_ip_list}
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_2_VM_IPS}[1]    @{NET_1_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ${dst_ip_list}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${cn1_conn_id}    ${cn2_conn_id}    ${os_conn_id}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP1}
    ${CONFIG_EXTRA_ROUTE_IP2} =    BuiltIn.Catenate    sudo ifconfig eth0:2 @{EXTRA_NW_IP}[1] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ifconfig
    ${ext_rt1} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET}[0],gateway=@{NET_1_VM_IPS}[0]
    ${ext_rt2} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET}[1],gateway=@{NET_1_VM_IPS}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt1}    ${RT_OPTIONS}    ${ext_rt2}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${vm_ips} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

Delete Extra Route
    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTER}    -D

Delete And Recreate Extra Route
    [Documentation]    Recreate multiple extra route and check data path before L3VPN creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IP}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${CONFIG_EXTRA_ROUTE_IP1}
    ${ext_rt1} =    BuiltIn.Set Variable    destination=@{EXTRA_NW_SUBNET}[0],gateway=@{NET_1_VM_IPS}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${ext_rt1}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ping -c 3 @{EXTRA_NW_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    ...    AND    OpenStackOperations.Show Router    ${ROUTER}    -D
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Associate L3VPN To Routers
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    ${vm_instances} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${VPN_IFACES_URL}    ${vm_instances}
    ${RD} =    Strip String    @{RDS}[0]    characters="[]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP2_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_CMP2_IP}
    BuiltIn.Log    Check datapath from network1 to network2
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]    @{NET_2_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${dst_ip_list}
    BuiltIn.Log    Check datapath from network2 to network1
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_2_VM_IPS}[1]    @{NET_1_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ${dst_ip_list}

Disassociate L3VPN From Router
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    #VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    #${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    #BuiltIn.Should Contain    ${resp}    ${router_id}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    VpnOperations.Get Fib Entries    session
    BuiltIn.Log    ${output}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
    \    BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}
    Delete Router    ${ROUTER}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id} 
    ${output}=    Wait Until Keyword Succeeds    60s    10s    VpnOperations.Get Fib Entries    session
    BuiltIn.Log    ${output}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_CMP1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_CMP2_IP}

Delete Router With NonExistentRouter Name
    [Documentation]    Delete router with nonExistentRouter name
    ${rc}    ${output}=    Run And Return Rc And Output    neutron router-delete nonExistentRouter
    BuiltIn.Should Match Regexp    ${output}    Unable Not At URIto find router with name or id 'nonExistentRouter'|Unable to find router\\(s\\) with id\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    sleep    180s
    #VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    #VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id} 
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Associate L3VPN To Network    networkid=${network1_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network1_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network2_id}

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    ${output}=    Wait Until Keyword Succeeds    60s    10s    VpnOperations.Get Fib Entries    session
    BuiltIn.Log    ${output}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

Create BGP Config On ODL
    [Documentation]    Create BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP Config on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[0]    ${DCGW_RD[0]}
    ...    @{LOOPBACK_IPS}[0]
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    @{LOOPBACK_NAMES}[0]    @{LOOPBACK_IPS}[0]
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    ${RUN_CONFIG}
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}

Verify BGP Neighbor Status
    [Documentation]    Verify BGP status established
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${output}
    ${output1} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    ${BGP_ROUTE_CMD}
    BuiltIn.Log    ${output1}

Verification of route update after VM port removed and re added to VPN
    [Documentation]    Verify route update after VM port removed and re added to VPN
    BuiltIn.Log    Delete neutron port vpn_net_1_port_1
    Delete Port    @{PORTS_HOST1}[0]
    ${output}=    Wait Until Keyword Succeeds    60s    10s    VpnOperations.Get Fib Entries    session
    BuiltIn.Log    ${output}
    Should Not Contain    ${output}    ${NET_1_VM_IPS[0]}
    BuiltIn.Log    Delete and recreate vm and port
    Delete Vm Instance    @{NET_1_VMS}[0]
    Create Port    @{NETWORKS}[0]    @{PORTS_HOST1}[0]    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS_HOST1}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST1}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    ${VM_IPs}=    Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    Set Suite Variable    ${VM_IPs}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${NET_1_VM_IPS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

Verification of route update after reconfiguring vpn by adding new ports
    [Documentation]    Verify route update after reconfiguring vpn by adding new ports
    BuiltIn.Log    "Create VM15 on openvswitch1 and check datapath traffic from all other vms and ASR"
    Create Port    @{NETWORKS}[0]    ${PORT_NEW}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_NEW}    ${VM_NAME_NEW}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    Poll VM Is ACTIVE    ${VM_NAME_NEW}
    ${status}    ${ips_and_console_log}    Run Keyword And Ignore Error    Wait Until Keyword Succeeds    180s    15s
    ...    Get VM IP    true    ${VM_NAME_NEW}
    ${output}=    Get Fib Entries    session
    Log    ${output}
    Should Contain    ${output}    ${ips_and_console_log[0]}
    BuiltIn.Log    "Delete new VM"
    Delete Vm Instance    ${VM_NAME_NEW}
    Delete Port    ${PORT_NEW}

Dissociate L3VPN From Networks
    [Documentation]    Dissociate L3VPN from networks
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${network1_id}
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${network2_id}

Delete Unknown L3VPN
    [Documentation]    Verification of successful response of deletion of unknown L3VPN
    Log    "STEP 1 : delete VPN with wrong ID"
    ${status}    ${message}    Run Keyword And Ignore Error    VPN Delete L3VPN    vpnid=${INVALID_VPN_INSTANCE_ID}
    Should Contain    ${status}    FAIL

Delete L3VPN
    [Documentation]    Delete L3VPN
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=@{RDS}[${index}]    importrt=@{RDS}[${index}]
    \    ...    tenantid=${tenant_id}
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]
    \    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[${index}]

Verification of route download with 3 vpns in SE & qbgp with 1-1 export import route target
    [Documentation]    Verification of route download with 5 vpns in SE & qbgp with 1-1 export import route target
    : FOR    ${index}    IN RANGE    1    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    \    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    @{LOOPBACK_NAMES}[${index}]    @{LOOPBACK_IPS}[${index}]
    Associate Multiple L3VPN To Networks    ${num_of_network}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Get Fib Entries    session
    Log    ${output}
    comment    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS}    @{LOOPBACK_IPS}
    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    [Teardown]    Pretest Cleanup

Verification of route download with 3 vpns in SE & qbgp with 1-many export import route target
    [Documentation]    Verification of route download with 5 vpns in SE & qbgp with 1-many export import route target
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=${CREATE_RT}    importrt=@{RDS}[0]    tenantid=${tenant_id}
    : FOR    ${index}    IN RANGE    1    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=@{RDS}[${index}]    importrt=${RT_LIST_${index}}
    \    ...    tenantid=${tenant_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    \    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    @{LOOPBACK_NAMES}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${Req_no_of_networks} =    Evaluate    2
    Associate Multiple L3VPN To Networks    ${Req_no_of_networks}
    ${output}=    Wait Until Keyword Succeeds    60s    10s    Get Fib Entries    session
    Log    ${output}
    comment    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}    @{LOOPBACK_IPS}
    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    [Teardown]    Pretest Cleanup

Verification of route download with 3 vpns in SE & qbgp with many-1 export import route target
    [Documentation]    Verification of route download with 5 vpns in SE & qbgp with many-1 export import route target
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=${CREATE_RT}    tenantid=${tenant_id}
    : FOR    ${index}    IN RANGE    1    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=${RT_LIST_${index}}    importrt=@{RDS}[${index}]
    \    ...    tenantid=${tenant_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    \    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    @{LOOPBACK_NAMES}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${Req_no_of_networks} =    Evaluate    2
    Associate Multiple L3VPN To Networks    ${Req_no_of_networks}
    comment    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}    @{LOOPBACK_IPS}
    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    [Teardown]    Pretest Cleanup

Verification of route download with 5 vpns in SE & qbgp with many-many export import route target
    [Documentation]    Verification of route download with 5 vpns in SE & qbgp with many-1 export import route target
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=${CREATE_RT}    importrt=${CREATE_RT}
    \    ...    tenantid=${tenant_id}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    ${DCGW_RD[${index}]}    @{LOOPBACK_IPS}[${index}]
    \    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    @{LOOPBACK_NAMES}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${Req_no_of_networks} =    Evaluate    2
    Associate Multiple L3VPN To Networks    ${Req_no_of_networks}
    comment    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}    @{LOOPBACK_IPS}
    ${fib_values} =    BuiltIn.Create List    @{VM_IPs}    @{SUBNET_CIDRS_1}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    
Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]

*** Keywords ***
Start Suite
    [Documentation]    Basic setup.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    OpenStackOperations.Create Nano Flavor

Associate Multiple L3VPN To Networks
    [Arguments]    ${num_of_network}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Associate L3VPN to the number of networks received as an argument
    : FOR    ${index}    IN RANGE    0    ${num_of_network}
    \    ${network_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[${index}]
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[${index}]
    \    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]
    \    Should Contain    ${resp}    ${network_id}

Pretest Cleanup
    [Documentation]    Test Case Cleanup
    Log To Console    "Running Test case level Pretest Cleanup"
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]
    BgpOperations.Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    OpenStackOperations.Get Test Teardown Debugs
