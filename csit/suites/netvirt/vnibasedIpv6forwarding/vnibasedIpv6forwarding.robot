*** Settings ***
Documentation     Test Suite for vni-based-l2-l3-nat:
...               This feature attempts to realize the use of VxLAN VNI
...               (Virtual Network Identifier) for VxLAN tenant traffic
...               flowing on the cloud data-network. This is applicable
...               to L2 switching, L3 forwarding and NATing for all VxLAN
...               based provider networks. In doing so, it eliminates the
...               presence of LPort tags, ELAN tags and MPLS labels on the
...               wire and instead, replaces them with VNIs supplied by the
...               tenant’s OpenStack.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Test Setup        VpnOperations.VNI Test Setup
Test Teardown     VpnOperations.VNI Test Teardown
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${EGRESS}         Egress
${INGRESS}        Ingress
${IP}             ipv6
${VNI6_SECURITY_GROUP}    vni6_sg
@{VNI6_NETWORKS}    vni6_net_0    vni6_net_1    vni6_net_2    vni6_net_3
@{VNI6_SUBNETS}    vni6_sub_0    vni6_sub_1    vni6_sub_2    vni6_sub_3
@{VNI6_SUBNET_CIDRS}    2001:db8:0:4::/64    2001:db8:0:5::/64    2001:db8:0:6::/64    2001:db8:0:7::/64
@{VNI6_NET_0_PORTS}    vni6_net_0_port_1    vni6_net_0_port_2
@{VNI6_NET_1_PORTS}    vni6_net_1_port_1    vni6_net_1_port_2
@{VNI6_NET_2_PORTS}    vni6_net_2_port_1    vni6_net_2_port_2
@{VNI6_NET_3_PORTS}    vni6_net_3_port_1    vni6_net_3_port_2
@{VNI6_NET_0_VMS}    vni6_net_0_vm_1
@{VNI6_NET_1_VMS}    vni6_net_1_vm_1
@{VNI6_NET_2_VMS}    vni6_net_2_vm_1
@{VNI6_NET_3_VMS}    vni6_net_3_vm_1
@{VNI6_ROUTER}    vni6_router1    vni6_router2    vni6_router3
@{VNI6_RDS}       ["2600:2"]    ["2700:2"]    ["2800:2"]
@{VNI6_VPN_NAMES}    VNI6_vpn_1    VNI6_vpn_2    VNI6_vpn_3
@{VNI6_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261551    4ae8cd92-48ca-49b5-94e1-b2921a261552    4ae8cd92-48ca-49b5-94e1-b2921a261553
${NET0_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac --allocation-pool start=2001:db8:0:4::2,end=2001:db8:0:4:ffff:ffff:ffff:fffe
${NET1_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac --allocation-pool start=2001:db8:0:5::2,end=2001:db8:0:5:ffff:ffff:ffff:fffe
${NET2_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac --allocation-pool start=2001:db8:0:6::2,end=2001:db8:0:6:ffff:ffff:ffff:fffe
${NET3_ADDITIONAL_ARGS}    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac --allocation-pool start=2001:db8:0:7::2,end=2001:db8:0:7:ffff:ffff:ffff:fffe

*** Test Cases ***
VNI Based IPv6 Forwarding
    [Documentation]    verify VNI id for IPv6 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_0_PORTS}[0]    @{VNI6_NET_1_PORTS}[0]    @{VNI6_NETWORKS}[0]
    ...    @{VNI6_NETWORKS}[1]    @{VM_IP_NET0}[0]    @{VM_IP_NET1}[0]    ${IP}

VNI Based IPv6 Forwarding With BGPVPN Router Association
    [Documentation]    verify VNI id for IPv6 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Router associated to a BGPVPN.
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]    name=@{VNI6_VPN_NAMES}[0]    rd=@{VNI6_RDS}[0]    exportrt=@{VNI6_RDS}[0]    importrt=@{VNI6_RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI6_ROUTER}[0]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_0_PORTS}[0]    @{VNI6_NET_1_PORTS}[0]    @{VNI6_NETWORKS}[0]
    ...    @{VNI6_NETWORKS}[1]    @{VM_IP_NET0}[0]    @{VM_IP_NET1}[0]    ${IP}

VNI Based IPv6 Forwarding With Two Routers And BGPVPN With Irt Ert
    [Documentation]    verify VNI id for IPv6 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Two Routers each associated to a BGPVPN and The Two BGPVPN is connected with irt and ert.
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[2]
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[3]
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[2]    @{VNI6_SUBNETS}[2]    @{VNI6_SUBNET_CIDRS}[2]    ${NET2_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[3]    @{VNI6_SUBNETS}[3]    @{VNI6_SUBNET_CIDRS}[3]    ${NET3_ADDITIONAL_ARGS}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[2]    @{VNI6_NET_2_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[3]    @{VNI6_NET_3_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Router    @{VNI6_ROUTER}[1]
    OpenStackOperations.Add Router Interface    @{VNI6_ROUTER}[1]    @{VNI6_SUBNETS}[2]
    OpenStackOperations.Create Router    @{VNI6_ROUTER}[2]
    OpenStackOperations.Add Router Interface    @{VNI6_ROUTER}[2]    @{VNI6_SUBNETS}[3]
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[2]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]    name=@{VNI6_VPN_NAMES}[1]    rd=@{VNI6_RDS}[1]    exportrt=@{VNI6_RDS}[1]    importrt=@{VNI6_RDS}[2]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[1]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI6_ROUTER}[1]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]    name=@{VNI6_VPN_NAMES}[2]    rd=@{VNI6_RDS}[2]    exportrt=@{VNI6_RDS}[2]    importrt=@{VNI6_RDS}[1]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[2]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI6_ROUTER}[2]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_2_PORTS}[0]    @{VNI6_NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_3_PORTS}[0]    @{VNI6_NET_3_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Poll VM Is ACTIVE    @{VNI6_NET_2_VMS}[0]
    OpenStackOperations.Poll VM Is ACTIVE    @{VNI6_NET_3_VMS}[0]
    @{networks} =    BuiltIn.Create List    @{VNI6_NETWORKS}[2]    @{VNI6_NETWORKS}[3]
    @{subnet_cidrs} =    BuiltIn.Create List    @{VNI6_SUBNET_CIDRS}[2]    @{VNI6_SUBNET_CIDRS}[3]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${networks}    ${subnet_cidrs}
    ${prefix_net2} =    String.Replace String    @{VNI6_SUBNET_CIDRS}[2]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${VNI6_NET_2_VMS}    network=@{VNI6_NETWORKS}[2]    subnet=${prefix_net2}
    ${prefix_net3} =    String.Replace String    @{VNI6_SUBNET_CIDRS}[3]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${VNI6_NET_3_VMS}    network=@{VNI6_NETWORKS}[3]    subnet=${prefix_net3}
    ${VM_IP_NET2} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${VNI6_NET_2_VMS}    network=@{VNI6_NETWORKS}[2]    subnet=${prefix_net2}
    ${VM_IP_NET3} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${VNI6_NET_3_VMS}    network=@{VNI6_NETWORKS}[3]    subnet=${prefix_net3}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{VNI6_NET_2_VMS}[0]    30s
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{VNI6_NET_3_VMS}[0]    30s
    OpenStackOperations.Copy DHCP Files From Control Node
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_2_PORTS}[0]    @{VNI6_NET_3_PORTS}[0]    @{VNI6_NETWORKS}[2]
    ...    @{VNI6_NETWORKS}[3]    @{VM_IP_NET2}[0]    @{VM_IP_NET3}[0]    ${IP}

*** Keywords ***
Suite Setup
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    ...    Create Two VMs for TC1 : (VM1, N1, Compute1) and (VM2, N2, Compute2) and R1
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI6_SECURITY_GROUP}    IPv6
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[0]
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[0]    @{VNI6_SUBNETS}[0]    @{VNI6_SUBNET_CIDRS}[0]    ${NET0_ADDITIONAL_ARGS}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[1]    @{VNI6_SUBNETS}[1]    @{VNI6_SUBNET_CIDRS}[1]    ${NET1_ADDITIONAL_ARGS}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[0]    @{VNI6_NET_0_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[1]    @{VNI6_NET_1_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Router    @{VNI6_ROUTER}[0]
    OpenStackOperations.Add Router Interface    @{VNI6_ROUTER}[0]    @{VNI6_SUBNETS}[0]
    OpenStackOperations.Add Router Interface    @{VNI6_ROUTER}[0]    @{VNI6_SUBNETS}[1]
    ${interface_output} =    OpenStackOperations.Show Router Interface    @{VNI6_ROUTER}[0]
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    @{VNI6_ROUTER}[0]
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    ${router_list} =    BuiltIn.Create List    @{VNI6_ROUTER}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_0_PORTS}[0]    @{VNI6_NET_0_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_1_PORTS}[0]    @{VNI6_NET_1_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Poll VM Is ACTIVE    @{VNI6_NET_0_VMS}[0]
    OpenStackOperations.Poll VM Is ACTIVE    @{VNI6_NET_1_VMS}[0]
    @{networks} =    BuiltIn.Create List    @{VNI6_NETWORKS}[0]    @{VNI6_NETWORKS}[1]
    @{subnet_cidrs} =    BuiltIn.Create List    @{VNI6_SUBNET_CIDRS}[0]    @{VNI6_SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    OpenStackOperations.Wait For Routes To Propogate    ${networks}    ${subnet_cidrs}
    ${prefix_net0} =    Replace String    @{VNI6_SUBNET_CIDRS}[0]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${VNI6_NET_0_VMS}    network=@{VNI6_NETWORKS}[0]    subnet=${prefix_net0}
    ${prefix_net1} =    Replace String    @{VNI6_SUBNET_CIDRS}[1]    ::/64    (:[a-f0-9]{,4}){,4}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Wait Until Keyword Succeeds    3x    60s    OpenStackOperations.Collect VM IPv6 SLAAC Addresses
    ...    fail_on_none=true    vm_list=${VNI6_NET_1_VMS}    network=@{VNI6_NETWORKS}[1]    subnet=${prefix_net1}
    ${VM_IP_NET0} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${VNI6_NET_0_VMS}    network=@{VNI6_NETWORKS}[0]    subnet=${prefix_net0}
    ${VM_IP_NET1} =    OpenStackOperations.Collect VM IPv6 SLAAC Addresses    fail_on_none=false    vm_list=${VNI6_NET_1_VMS}    network=@{VNI6_NETWORKS}[1]    subnet=${prefix_net1}
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET0}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{VNI6_NET_0_VMS}[0]    30s
    ${status}    ${message}    Run Keyword And Ignore Error    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    Run Keyword If    '${status}' == 'FAIL'    OpenStack CLI    openstack console log show @{VNI6_NET_1_VMS}[0]    30s
    OpenStackOperations.Copy DHCP Files From Control Node
    BuiltIn.Set Suite Variable    ${VM_IP_NET0}
    BuiltIn.Set Suite Variable    ${VM_IP_NET1}
    BuiltIn.Should Not Contain    ${VM_IP_NET0}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    OpenStackOperations.Show Debugs    @{VNI6_NET_0_VMS}    @{VNI6_NET_1_VMS}

Suite Teardown
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    OpenStackOperations.OpenStack Suite Teardown
