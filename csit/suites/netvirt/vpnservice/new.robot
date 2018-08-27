*** Settings ***
Documentation     Test suite to validate subnet routing functionality for hidden IPv4/IPv6 address in an Openstack
...               integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/VpnOperations.robot

*** Variables ***
${SECURITY_GROUP}    vpn_sg_dualstack_subnet
@{NETWORKS}       vpn_net_1_dualstack_subnet    vpn_net_2_dualstack_subnet
@{SUBNETS4}       vpn_net_ipv4_1_dualstack_subnet    vpn_net_ipv4_2_dualstack_subnet
@{SUBNETS6}       vpn_net_ipv6_1_dualstack_subnet    vpn_net_ipv6_2_dualstack_subnet
@{SUBNETS4_CIDR}    30.1.1.0/24    40.1.1.0/24
@{SUBNETS6_CIDR}    2001:db5:0:2::/64    2001:db5:0:3::/64
${SUBNET_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac
@{PORTS}          vpn_port_1_dualstack_subnet    vpn_port_2_dualstack_subnet    vpn_port_3_dualstack_subnet    vpn_port_4_dualstack_subnet
@{NET_1_VMS}    vpn_net_1_vm_1_dualstack_subnet    vpn_net_1_vm_2_dualstack_subnet
@{NET_2_VMS}    vpn_net_2_vm_1_dualstack_subnet    vpn_net_2_vm_2_dualstack_subnet
@{EXTRA_NW_IPV4}    30.1.1.209    30.1.1.210    30.1.1.211    40.1.1.209    40.1.1.210    40.1.1.211
@{EXTRA_NW_IPV6}    2001:db5:0:2::10    2001:db5:0:2::20    2001:db5:0:2::30    2001:db5:0:3::10    2001:db5:0:3::20    2001:db5:0:3::30
@{EXTRA_NW_SUBNET_IPv4}    30.1.1.0/24    40.1.1.0/24
@{EXTRA_NW_SUBNET_IPv6}    2001:db5:0:2::/64    2001:db5:0:3::/64
${ROUTER}         vpn_router_dualstack_subnet
${UPDATE_NETWORK}    UpdateNetwork_dualstack_subnet
${UPDATE_SUBNET}    UpdateSubnet_dualstack_subnet
${UPDATE_PORT}    UpdatePort_dualstack_subnet
@{VPN_INSTANCE_ID}    1bc8cd92-48ca-49b5-94e1-b2921a261661    1bc8cd92-48ca-49b5-94e1-b2921a261662    1bc8cd92-48ca-49b5-94e1-b2921a261663
@{VPN_NAME}       vpn1_dualstack_subnet    vpn2_dualstack_subnet    vpn3_dualstack_subnet
@{RDS}            ["2506:2"]    ["2606:2"]    ["2706:2"]

*** Test Cases ***
Check ELAN Datapath Traffic Within The Networks
    [Documentation]    Checks datapath within the same network with different vlans.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ping -I @{NET_1_VM_IPV4}[0] -c 3 @{NET_1_VM_IPV4}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ping6 -I @{NET_1_VM_IPV6}[0] -c 3 @{NET_1_VM_IPV6}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ping -I @{NET_2_VM_IPV4}[0] -c 3 @{NET_2_VM_IPV4}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ping6 -I @{NET_2_VM_IPV6}[0] -c 3 @{NET_2_VM_IPV6}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Check L3_Datapath Traffic Across Networks With Router
    [Documentation]    L3 Datapath test across networks using previously created router.
    BuiltIn.Log    Verification of FIB Entries and Flow
    @{tcpdump_conn_ids} =    OpenStackOperations.Start Packet Capture On Nodes    tcpdump_vpndssr    ${EMPTY}    @{OS_ALL_IPS}
    ${vm_instances} =    BuiltIn.Create List    @{NET_1_VM_IPV4}    @{NET_2_VM_IPV4}    @{NET_1_VM_IPV6}    @{NET_2_VM_IPV6}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${vm_instances}
    : FOR    ${vm}    IN    ${vm_instances}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${vm}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW1_MAC_ADDRS}
    ${GWMAC_ADDRS} =    BuiltIn.Create List    @{GW1_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    ${GWIP_ADDRS} =    BuiltIn.Create List    @{GW_IPV4_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    Verify GWMAC Flow Entry On Flow Table On All Compute Nodes    ipv4
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW2_MAC_ADDRS}
    ${GWMAC_ADDRS} =    BuiltIn.Create List    @{GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    ${GWIP_ADDRS} =    BuiltIn.Create List    @{GW_IPV6_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    Verify GWMAC Flow Entry On Flow Table On All Compute Nodes    ipv6
    BuiltIn.Log    L3 Datapath test across the networks using router
    ${dst_ips} =    BuiltIn.Create List    @{NET_1_VM_IPV4}[1]    @{NET_2_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_2_VM_IPV4}[1]    @{NET_1_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_1_VM_IPV6}[1]    @{NET_2_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_2_VM_IPV6}[1]    @{NET_1_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ${dst_ips}
    [Teardown]    VpnOperations.Test Teardown With Tcpdump Stop    ${tcpdump_conn_ids}

Create L3VPN
    [Documentation]    Create L3VPN
    ${net_id} =    OpenStackOperations.Get Net Id    @{NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}

Associate L3VPN To Routers
    [Documentation]    Associating router to L3VPN.
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${router_id}

Configure Extra IPv4/IPv6 Addresss On Interface For Subnet Routing
    [Documentation]    Extra IPv4/IPv6 Address configuration on Interfaces
    ${CONFIG_EXTRA_ROUTE_IP2} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IPV6}[0]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ${CONFIG_EXTRA_ROUTE_IP2}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ip -6 a
    ${CONFIG_EXTRA_ROUTE_IP3} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IPV6}[1]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[1]    ${CONFIG_EXTRA_ROUTE_IP3}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[1]    ip -6 a
    ${CONFIG_EXTRA_ROUTE_IP4} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IPV6}[3]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ${CONFIG_EXTRA_ROUTE_IP4}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ip -6 a
    ${CONFIG_EXTRA_ROUTE_IP5} =    BuiltIn.Catenate    sudo ip -6 addr add @{EXTRA_NW_IPV6}[4]/64 dev eth0
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[1]    ${CONFIG_EXTRA_ROUTE_IP5}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[1]    ip -6 a
    ${CONFIG_EXTRA_ROUTE_IP6} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[0] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ${CONFIG_EXTRA_ROUTE_IP6}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ip a
    ${CONFIG_EXTRA_ROUTE_IP7} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[1] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[1]    ${CONFIG_EXTRA_ROUTE_IP7}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[1]    ip a
    ${CONFIG_EXTRA_ROUTE_IP8} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[3] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ${CONFIG_EXTRA_ROUTE_IP8}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ip a
    ${CONFIG_EXTRA_ROUTE_IP9} =    BuiltIn.Catenate    sudo ifconfig eth0:1 @{EXTRA_NW_IPV4}[4] netmask 255.255.255.0 up
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[1]    ${CONFIG_EXTRA_ROUTE_IP9}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[1]    ip a

Verify L3VPN Datapath With Router Association
    [Documentation]    Datapath test across networks using L3VPN associated with router.
    BuiltIn.Log    Verify VPN interfaces, FIB entries and Flow table
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Utils.Check For Elements At URI    ${VPN_IFACES_URL}    ${VM_IPS}
    ${RD} =    Strip String    ${RDS[0]}    characters="[]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    Utils.Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/vrfTables/${RD}/    ${VM_IPS}
    Verify Flows Are Present For L3VPN On All Compute Nodes    ${VM_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW1_MAC_ADDRS}
    ${GWMAC_ADDRS} =    BuiltIn.Create List    @{GW1_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    ${GWIP_ADDRS} =    BuiltIn.Create List    @{GW_IPV4_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    Verify GWMAC Flow Entry On Flow Table On All Compute Nodes
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    VpnOperations.Verify GWMAC Entry On ODL    ${GW2_MAC_ADDRS}
    ${GWMAC_ADDRS} =    BuiltIn.Create List    @{GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    ${GWIP_ADDRS} =    BuiltIn.Create List    @{GW_IPV6_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    Verify GWMAC Flow Entry On Flow Table On All Compute Nodes    ipv6
    BuiltIn.Log    L3 Datapath test across the networks using L3VPN
    ${dst_ips} =    BuiltIn.Create List    @{NET_1_VM_IPV4}[1]    @{NET_2_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_2_VM_IPV4}[1]    @{NET_1_VM_IPV4}
    Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV4}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_1_VM_IPV6}[1]    @{NET_2_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ${dst_ips}
    ${dst_ips} =    BuiltIn.Create List    @{NET_2_VM_IPV6}[1]    @{NET_1_VM_IPV6}
    Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ${dst_ips}

Verify Data Traffic On Configured Subnet Ipv4/IPv6 Address
    [Documentation]    Check Dual Stack data path verifcation within and across network.
    Verify Ipv4 Data Traffic
    Verify Ipv6 Data Traffic

Dissociate L3VPN From Routers
    [Documentation]    Dissociating router from L3VPN.
    ${router_id} =    OpenStackOperations.Get Router Id    ${ROUTER}
    VpnOperations.Dissociate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID[0]}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Not Contain    ${resp}    ${router_id}

Delete L3VPN
    [Documentation]    Delete L3VPN.
    VpnOperations.VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID[0]}

*** Keywords ***
Suite Setup
    [Documentation]    Create basic setup for feature.Create two network,subnet,four ports and four VMs
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Network    @{NETWORKS}[0]
    OpenStackOperations.Create Network    @{NETWORKS}[1]
    ${NET_LIST} =    OpenStackOperations.List Networks
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}
    OpenStackOperations.Update Network    @{NETWORKS}[0]    additional_args=--description ${UPDATE_NETWORK}
    ${output} =    OpenStackOperations.Show Network    @{NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_NETWORK}
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS4}[0]    @{SUBNETS4_CIDR}[0]
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS6}[0]    @{SUBNETS6_CIDR}[0]    ${SUBNET_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS4}[1]    @{SUBNETS4_CIDR}[1]
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS6}[1]    @{SUBNETS6_CIDR}[1]    ${SUBNET_ADDITIONAL_ARGS}
    ${SUB_LIST} =    OpenStackOperations.List Subnets
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS4}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS6}
    OpenStackOperations.Update SubNet    @{SUBNETS4}[0]    additional_args=--description ${UPDATE_SUBNET}
    ${output} =    OpenStackOperations.Show SubNet    @{SUBNETS4}[0]
    BuiltIn.Should Contain    ${output}    ${UPDATE_SUBNET}
    OpenStackOperations.Create Router    ${ROUTER}
    @{ROUTER_LIST} =    BuiltIn.Create List    ${ROUTER}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${ROUTER_URL}    ${ROUTER_LIST}
    : FOR    ${port}    IN    @{SUBNETS4}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${port}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GW1_MAC_ADDRS}    ${GW_IPV4_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}
    : FOR    ${port}    IN    @{SUBNETS6}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${port}
    ${interface_output} =    OpenStackOperations.Show Router Interface    ${ROUTER}
    ${GW2_MAC_ADDRS}    ${GW_IPV6_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    ${ROUTER}    ${IP6_REGEX}
    BuiltIn.Set Suite Variable    ${GW1_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW2_MAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV4_ADDRS}
    BuiltIn.Set Suite Variable    ${GW_IPV6_ADDRS}
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}    IPv4
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=tcp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    protocol=icmp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    OpenStackOperations.Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    ethertype=IPv6    port_range_max=65535    port_range_min=1    protocol=udp
    ${allowed_address_pairs_args} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV4}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET_IPV6}[1]
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${PORTS}
    ${PORTS_MACADDR} =    OpenStackOperations.Get Ports MacAddr    ${PORTS}
    BuiltIn.Set Suite Variable    ${PORTS_MACADDR}
    OpenStackOperations.Update Port    @{PORTS}[0]    additional_args=--name ${UPDATE_PORT}
    ${output} =    Show Port    ${UPDATE_PORT}
    BuiltIn.Should Contain    ${output}    ${UPDATE_PORT}
    OpenStackOperations.Update Port    ${UPDATE_PORT}    additional_args=--name @{PORTS}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    ${NET_1_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    ${NET_1_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    ${NET_2_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    ${NET_2_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES} =    BuiltIn.Create List    @{NET_1_VMS}    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    ${VM_INSTANCES}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS4_CIDR}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${NETWORKS}    ${SUBNETS6_CIDR}
    @{NET_1_VM_IPV4}    ${NET_1_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPV4}    ${NET_2_DHCP_IPV4} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IPV4}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IPV4}    None
    BuiltIn.Log    Collect VMs IPv6 addresses
    ${prefix_net10} =    String.Replace String    @{SUBNETS6_CIDR}[0]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${prefix_net20} =    String.Replace String    @{SUBNETS6_CIDR}[1]    ${IP6_SUBNET_CIDR_SUFFIX}    ${IP6_ADDR_SUFFIX}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_1_VMS}    @{NETWORKS}[0]    ${prefix_net10}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    true    ${NET_2_VMS}    @{NETWORKS}[1]    ${prefix_net20}
    ${NET_1_VM_IPV6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_1_VMS}    @{NETWORKS}[0]    ${prefix_net10}
    ${NET_2_VM_IPV6} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    false    ${NET_2_VMS}    @{NETWORKS}[1]    ${prefix_net20}
    ${LOOP_COUNT}    Get Length    ${NET_1_VMS}
    : FOR    ${index}    IN RANGE    0    ${LOOP_COUNT}
    \    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{NET_1_VM_IPV6}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_1_VMS}[${index}]    30s
    \    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    @{NET_2_VM_IPV6}[${index}]    None
    \    Run Keyword If    '${status}' == 'FAIL'    Write Commands Until Prompt    nova console-log @{NET_2_VMS}[${index}]    30s
    BuiltIn.Set Suite Variable    ${NET_1_VM_IPV4}
    BuiltIn.Set Suite Variable    ${NET_2_VM_IPV4}
    BuiltIn.Set Suite Variable    ${NET_1_VM_IPV6}
    BuiltIn.Set Suite Variable    ${NET_2_VM_IPV6}
    ${VM_IPS} =    BuiltIn.Create List    @{NET_1_VM_IPV4}    @{NET_2_VM_IPV4}    @{NET_1_VM_IPV6}    @{NET_2_VM_IPV6}
    BuiltIn.Set Suite Variable    ${VM_IPS}
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    OpenStackOperations.Get Suite Debugs

Verify Ipv4 Data Traffic
    [Documentation]    Check Ipv4 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_1_VM_IPV4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[4]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_1_VM_IPV4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[4]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[3]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_1_VM_IPV4}[0]    ping -c 3 @{EXTRA_NW_IPV4}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_1_VM_IPV4}[1]    ping -c 3 @{EXTRA_NW_IPV4}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Verify Ipv6 Data Traffic
    [Documentation]    Check Ipv6 data path verification within and across network
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[4]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[4]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPV6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[3]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[0]    ping6 -c 3 @{EXTRA_NW_IPV6}[0]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPV6}[1]    ping6 -c 3 @{EXTRA_NW_IPV6}[1]
    BuiltIn.Should Contain    ${output}    64 bytes

Suite Teardown
    [Documentation]    Delete the setup
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[0]
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[1]
    BuiltIn.Run Keyword And Ignore Error    VpnOperations.VPN Delete L3VPN    vpnid=@{VPN_INSTANCE_ID}[2]
    OpenStackOperations.OpenStack Suite Teardown
