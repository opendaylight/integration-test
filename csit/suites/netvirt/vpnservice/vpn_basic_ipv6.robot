*** Settings ***
Documentation     Test suite to validate IPv6 vpnservice functionality in an Openstack integrated environment.
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
${SECURITY_GROUP}    vpn6_sg
@{NETWORKS}       vpn6_net_1    vpn6_net_2
@{SUBNETS}        vpn6_sub_1    vpn6_sub_2
@{SUBNET_CIDRS}    2001:db8:0:2::/64    2001:db8:0:3::/64
@{PORTS}          vpn6_net_1_port_1    vpn6_net_1_port_2    vpn6_net_2_port_1    vpn6_net_2_port_2
@{NET_1_VMS}      vpn6_net_1_vm_1    vpn6_net_1_vm_2
@{NET_2_VMS}      vpn6_net_2_vm_1    vpn6_net_2_vm_2
${ROUTER}         vpn6_router
@{EXTRA_NW_IP}    2001:db9:cafe:d::10    2001:db9:abcd:d::20
@{EXTRA_NW_SUBNET}    2001:db9:cafe:d::/64    2001:db9:abcd:d::/64
${UPDATE_NETWORK}    UpdateNetworkV6
${UPDATE_SUBNET}    UpdateSubnetV6
${UPDATE_PORT}    UpdatePortV6
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261661    4ae8cd92-48ca-49b5-94e1-b2921a261662    4ae8cd92-48ca-49b5-94e1-b2921a261663
@{VPN_NAMES}      vpn6_1    vpn6_2    vpn6_3
@{RDS}            ["2206:2"]    ["2306:2"]    ["2406:2"]

*** Test Cases ***
Create Neutron Networks
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}

Create Neutron Subnets
    ${net1_additional_args}=    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET1_IPV6_ADDR_POOL}
    ${net2_additional_args}=    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${NET2_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]    ${net1_additional_args}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]    ${net2_additional_args}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}
    OpenStackOperations.Update SubNet    @{SUBNETS}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}

Create Router
    OpenStackOperations.Create Router    ${ROUTER}
    ${router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${router_list}

Add Interfaces To Router
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    : FOR    ${interface}    IN    @{SUBNETS}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${interface}
    \    BuiltIn.Should Contain    ${interface_output}    ${subnet_id}
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}    ${IP6_REGEX}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}

Add Ssh V6 Allow All Rule
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv6

Create Neutron Ports
    ${allowed_address_pairs_args}=    Set Variable If    '${OPENSTACK_BRANCH}'=='stable/newton'    --allowed-address ip_address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip_address=@{EXTRA_NW_SUBNET}[1]    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1]
    Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${PORT_URL}    ${PORTS}
    OpenStackOperations.Update Port    @{PORTS}[0]    additional_args=--name ${UPDATE_PORT}
    ${output} =    Show Port    ${UPDATE_PORT}
    BuiltIn.Should Contain    ${output}    ${UPDATE_PORT}
    OpenStackOperations.Update Port    ${UPDATE_PORT}    additional_args=--name @{PORTS}[0]

Create Nova VMs
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${vms}=    BuiltIn.Create List    @{NET_1_VMS}    @{NET_2_VMS}
    : FOR    ${vm}    IN    @{vms}
    \    OpenStackOperations.Poll VM Is ACTIVE    ${vm}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Wait For Routes To Propogate    ${NETWORKS}    ${SUBNET_CIDRS}
    ${prefix_net10} =    Replace String    @{SUBNET_CIDRS}[0]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_1_VMS}    network=@{NETWORKS}[0]    subnet=${prefix_net10}
    ${prefix_net20} =    Replace String    @{SUBNET_CIDRS}[1]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${NET_2_VMS}    network=@{NETWORKS}[1]    subnet=${prefix_net20}
    ${VM_IP_NET10} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_1_VMS}    network=@{NETWORKS}[0]    subnet=${prefix_net10}
    ${VM_IP_NET20} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${NET_2_VMS}    network=@{NETWORKS}[1]    subnet=${prefix_net20}
    ${VM_INSTANCES} =    Collections.Combine Lists    ${NET_1_VMS}    ${NET_2_VMS}
    ${VM_IPS}=    Collections.Combine Lists    ${VM_IP_NET10}    ${VM_IP_NET20}
    ${LOOP_COUNT}    BuiltIn.Get Length    ${NET_1_VMS}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{VM_IPS}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{VM_INSTANCES}[${index}]    30s
    OpenStackOperations.Copy DHCP Files From Control Node
    BuiltIn.Set Suite Variable    ${VM_IP_NET10}
    BuiltIn.Set Suite Variable    ${VM_IP_NET20}
    BuiltIn.Should Not Contain    ${VM_IP_NET10}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET20}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Check ELAN Datapath Traffic Within The Networks
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ping6 -c 3 @{VM_IP_NET10}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output}=    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IP_NET20}[0]    ping6 -c 3 @{VM_IP_NET20}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Check L3_Datapath Traffic Across Networks With Router
    BuiltIn.Log    Verification of FIB Entries and Flow
    @{tcpdump_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes    tcpdump_vpn6    ${EMPTY}    ${OS_CONTROL_NODE_IP}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    ${vm_ips} =    BuiltIn.Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET20}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}    ipv6
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}    ipv6
    ${dst_ip_list} =    BuiltIn.Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ${dst_ip_list}
    ${dst_ip_list} =    BuiltIn.Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{VM_IP_NET20}[0]    ${dst_ip_list}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${tcpdump_conn_ids}

Add Multiple Extra Routes And Check Datapath Before L3VPN Creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IP}[0]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ${CONFIG_EXTRA_ROUTE_IP1}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ip -6 a
    ${CONFIG_EXTRA_ROUTE_IP2} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IP}[1]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ip -6 a
    ${EXT_RT1} =    Set Variable    destination=@{EXTRA_NW_SUBNET}[0],gateway=@{VM_IP_NET10}[0]
    ${EXT_RT2} =    Set Variable    destination=@{EXTRA_NW_SUBNET}[1],gateway=@{VM_IP_NET10}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${EXT_RT1}    ${RT_OPTIONS}    ${EXT_RT2}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${vm_ips} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_ips}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[1]    ping6 -c 3 @{EXTRA_NW_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{VM_IP_NET20}[1]    ping6 -c 3 @{EXTRA_NW_IP}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[1]    ping6 -c 3 @{EXTRA_NW_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes

Delete Extra Route
    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    OpenStackOperations.Show Router    ${ROUTER}    -D

Delete And Recreate Extra Route
    [Documentation]    Recreate multiple extra route and check data path before L3VPN creation
    ${CONFIG_EXTRA_ROUTE_IP1} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IP}[1]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ${CONFIG_EXTRA_ROUTE_IP1}
    ${EXT_RT1} =    Set Variable    destination=@{EXTRA_NW_SUBNET}[0],gateway=@{VM_IP_NET10}[0]
    ${cmd} =    BuiltIn.Catenate    ${RT_OPTIONS}    ${EXT_RT1}
    OpenStackOperations.Update Router    ${ROUTER}    ${cmd}
    OpenStackOperations.Show Router    ${ROUTER}    -D
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[1]    ping6 -c 3 @{EXTRA_NW_IP}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    # clear off extra-routes before the next set of tests
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Update Router    ${ROUTER}    ${RT_CLEAR}
    ...    AND    OpenStackOperations.Show Router    ${ROUTER}    -D
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]

Associate L3VPN To Routers
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}

Verify L3VPN Datapath With Router Association
    BuiltIn.Log    Verify VPN interfaces, FIB entries and Flow table
    ${vm_instances} =    BuiltIn.Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${VPN_IFACES_URL}    ${vm_instances}
    ${RD} =    Strip String    @{RDS}[0]    characters="[]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${vm_instances}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Entry On ODL    ${GWMAC_ADDRS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_1_IP}    ipv6
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    VpnOperations.Verify GWMAC Flow Entry On Flow Table    ${OS_COMPUTE_2_IP}    ipv6
    BuiltIn.Log    Check datapath from network1 to network2
    ${dst_ip_list} =    BuiltIn.Create List    @{VM_IP_NET10}[1]    @{VM_IP_NET20}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{VM_IP_NET10}[0]    ${dst_ip_list}
    BuiltIn.Log    Check datapath from network2 to network1
    ${dst_ip_list} =    BuiltIn.Create List    @{VM_IP_NET20}[1]    @{VM_IP_NET10}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{VM_IP_NET20}[0]    ${dst_ip_list}

Dissociate L3VPN From Routers
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete Router And Router Interfaces With L3VPN
    ${router_id}=    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    OpenStackOperations.Get Subnet Id    ${INTERFACE}
    \    BuiltIn.Should Not Contain    ${interface_output}    ${subnet_id}
    OpenStackOperations.Delete Router    ${ROUTER}
    ${router_output} =    OpenStackOperations.List Routers
    BuiltIn.Should Not Contain    ${router_output}    ${ROUTER}
    @{router_list} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements Not At URI    ${ROUTER_URL}    ${router_list}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_1_IP}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Verify GWMAC Flow Entry Removed From Flow Table    ${OS_COMPUTE_2_IP}

Delete Router With NonExistentRouter Name
    ${rc}    ${output}=    Run And Return Rc And Output    neutron router-delete nonExistentRouter
    BuiltIn.Should Match Regexp    ${output}    Unable to find router with name or id 'nonExistentRouter'|Unable to find router\\(s\\) with id\\(s\\) 'nonExistentRouter'

Associate L3VPN To Networks
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Associate L3VPN To Network    networkid=${network1_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network1_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${network2_id}

Dissociate L3VPN From Networks
    ${network1_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[1]
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network1_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${network1_id}
    VpnOperations.Dissociate L3VPN From Networks    networkid=${network2_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Not Contain    ${resp}    ${network2_id}

Delete L3VPN
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]

Create Multiple L3VPN
    ${net_id} =    Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]    name=@{VPN_NAMES}[1]    rd=@{RDS}[1]    exportrt=@{RDS}[1]    importrt=@{RDS}[1]    tenantid=${tenant_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]    name=@{VPN_NAMES}[2]    rd=@{RDS}[2]    exportrt=@{RDS}[2]    importrt=@{RDS}[2]    tenantid=${tenant_id}
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[0]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[1]
    ${resp}=    VpnOperations.VPN Get L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    @{VPN_INSTANCE_IDS}[2]

Delete Multiple L3VPN
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[1]
    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_IDS}[2]
