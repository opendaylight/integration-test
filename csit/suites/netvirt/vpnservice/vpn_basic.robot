*** Settings ***
Documentation     Test suite to validate vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       VpnOperations.Basic Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
${SECURITY_GROUP}    vpn_sg
@{NETWORKS}       vpn_net_1    vpn_net_2
@{SUBNETS}        vpn_sub_1    vpn_sub_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24
@{PORTS}          vpn_net_1_port_1    vpn_net_1_port_2    vpn_net_2_port_1    vpn_net_2_port_2
@{NET_1_VMS}      vpn_net_1_vm_1    vpn_net_1_vm_2
@{NET_2_VMS}      vpn_net_2_vm_1    vpn_net_2_vm_2
${ROUTER}         vpn_router
@{EXTRA_NW_IP}    71.1.1.2    72.1.1.2
@{EXTRA_NW_SUBNET}    71.1.1.0/24    72.1.1.0/24
${UPDATE_NETWORK}    UpdateNetwork
${UPDATE_SUBNET}    UpdateSubnet
${UPDATE_PORT}    UpdatePort
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441    4ae8cd92-48ca-49b5-94e1-b2921a261442    4ae8cd92-48ca-49b5-94e1-b2921a261443
@{VPN_NAMES}      vpn_1    vpn_2    vpn_3
@{RDS}            ["2200:2"]    ["2300:2"]    ["2400:2"]

*** Test Cases ***
Create Neutron Networks
    # TODO: Many of these steps to verify if updates occurred should be in a different suite
    # that is checking for such operations.
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}

Add Ssh Allow All Rule
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Neutron Ports
    ${allowed_address_pairs_args} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1]
    Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}
    ${PORTS_MACADDR} =    Get Ports MacAddr    ${PORTS}
    Set Suite Variable    ${PORTS_MACADDR}
    Update Port    @{PORTS}[0]    additional_args=--description ${UPDATE_PORT}
    ${output} =    Show Port    @{PORTS}[0]
    Should Contain    ${output}    ${UPDATE_PORT}

Create Nova VMs
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS}    ${SUBNET_CIDRS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Create Router
    OpenStackOperations.Create Router    ${ROUTER}
    ${router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}

Check L3_Datapath Traffic Across Networks With Router
    @{tcpdump_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes    tcpdump_vpn    ${EMPTY}    ${OS_CONTROL_NODE_IP}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    ${vm_ips} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]    @{NET_2_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${dst_ip_list}
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_2_VM_IPS}[1]    @{NET_1_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ${dst_ip_list}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${tcpdump_conn_ids}

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

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{RDS}[0]
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]

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
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}
    BuiltIn.Log    Check datapath from network1 to network2
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_1_VM_IPS}[1]    @{NET_2_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${dst_ip_list}
    BuiltIn.Log    Check datapath from network2 to network1
    ${dst_ip_list} =    BuiltIn.Create List    @{NET_2_VM_IPS}[1]    @{NET_1_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ${dst_ip_list}

Delete Router Failure When Associated With L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack router delete ${ROUTER}
    Should Contain    ${output}    Not sure what output to expect here. need to test first!!!!!!!!
    BuiltIn.Should Be True    '${rc}' == '1'
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Contain    ${router_output}    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    15s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}

Remove Router Interfaces
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
    \    BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}

Disassociate L3VPN From Router
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router
    Delete Router    ${ROUTER}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Delete Router With NonExistentRouter Name
    [Documentation]    Delete router with nonExistentRouter name
    ${rc}    ${output}=    Run And Return Rc And Output    neutron router-delete nonExistentRouter
    BuiltIn.Should Match Regexp    ${output}    Unable Not At URIto find router with name or id 'nonExistentRouter'|Unable to find router\\(s\\) with id\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    [Documentation]    Associates L3VPN to networks and verify
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Associate L3VPN To Network    networkid=${network1_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network1_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network2_id}

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

Delete L3VPN
    [Documentation]    Delete L3VPN
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]

Create Multiple L3VPN
    [Documentation]    Creates three L3VPNs and then verify the same
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]    name=@{VPN_NAMES}[1]    rd=@{RDS}[1]    exportrt=@{RDS}[1]    importrt=@{RDS}[1]    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]    name=@{VPN_NAMES}[2]    rd=@{RDS}[2]    exportrt=@{RDS}[2]    importrt=@{RDS}[2]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[1]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[2]

Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    [Tags]    exclude
    BuiltIn.Log    This test will be added in the next patch

Delete Multiple L3VPN
    [Documentation]    Delete three L3VPNs created using Multiple L3VPN Test
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]
