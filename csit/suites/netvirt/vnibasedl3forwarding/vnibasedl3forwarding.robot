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
${IP}             ipv4
${VNI_SECURITY_GROUP}    vni_sg
@{VNI_NETWORKS}    vni_l3_net_0    vni_l3_net_1    vni_l3_net_2    vni_l3_net_3    vni_l3_net_4    vni_l3_net_5
@{VNI_SUBNETS}    vni_l3_sub_0    vni_l3_sub_1    vni_l3_sub_2    vni_l3_sub_3    vni_l3_sub_4    vni_l3_sub_5
@{VNI_SUBNET_CIDRS}    61.1.1.0/24    62.1.1.0/24    63.1.1.0/24    64.1.1.0/24    65.1.1.0/24    66.1.1.0/24
@{VNI_NET_0_PORTS}    vni_l3_net_0_port_1    vni_l3_net_0_port_2
@{VNI_NET_1_PORTS}    vni_l3_net_1_port_1    vni_l3_net_1_port_2
@{VNI_NET_2_PORTS}    vni_l3_net_2_port_1    vni_l3_net_2_port_2
@{VNI_NET_3_PORTS}    vni_l3_net_3_port_1    vni_l3_net_3_port_2
@{VNI_NET_4_PORTS}    vni_l3_net_4_port_1    vni_l3_net_4_port_2
@{VNI_NET_5_PORTS}    vni_l3_net_5_port_1    vni_l3_net_5_port_2
@{VNI_NET_0_VMS}    vni_l3_net_0_vm
@{VNI_NET_1_VMS}    vni_l3_net_1_vm
@{VNI_NET_2_VMS}    vni_l3_net_2_vm
@{VNI_NET_3_VMS}    vni_l3_net_3_vm
@{VNI_NET_4_VMS}    vni_l3_net_4_vm
@{VNI_NET_5_VMS}    vni_l3_net_5_vm
@{VNI_ROUTER}     vni_l3_router1    vni_l3_router2
@{VNI_BGPVPN}     vni_l3_bgpvpn
@{VNI_RDS}        ["2200:2"]    ["2300:2"]    ["2400:2"]    ["2500:2"]
@{VNI_VPN_NAMES}    vni_l3_vpn_1    vni_l3_vpn_2    vni_l3_vpn_3    vni_l3_vpn_4
@{VNI_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441    4ae8cd92-48ca-49b5-94e1-b2921a261442    4ae8cd92-48ca-49b5-94e1-b2921a261443    4ae8cd92-48ca-49b5-94e1-b2921a261444

*** Test Cases ***
VNI Based L3 Forwarding
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_0_PORTS}[0]    @{VNI_NET_1_PORTS}[0]    @{VNI_NETWORKS}[0]
    ...    @{VNI_NETWORKS}[1]    @{NET_0_VM_IPS}[0]    @{NET_1_VM_IPS}[0]    ${IP}

VNI Based L3 Forwarding With BGPVPN Router Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Router associated to a BGPVPN.
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]    name=@{VNI_VPN_NAMES}[0]    rd=@{VNI_RDS}[0]    exportrt=@{VNI_RDS}[0]    importrt=@{VNI_RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VNI_VPN_INSTANCE_IDS}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI_ROUTER}[0]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_0_PORTS}[0]    @{VNI_NET_1_PORTS}[0]    @{VNI_NETWORKS}[0]
    ...    @{VNI_NETWORKS}[1]    @{NET_0_VM_IPS}[0]    @{NET_1_VM_IPS}[0]    ${IP}

VNI Based L3 Forwarding With BGPVPN Network Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Networks associated to a BGPVPN.
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[2]
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[3]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[2]    @{VNI_SUBNETS}[2]    @{VNI_SUBNET_CIDRS}[2]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[3]    @{VNI_SUBNETS}[3]    @{VNI_SUBNET_CIDRS}[3]
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[2]    @{VNI_NET_2_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[3]    @{VNI_NET_3_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[2]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI_RDS}[1]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]    name=@{VNI_VPN_NAMES}[1]    rd=@{VNI_RDS}[1]    exportrt=@{VNI_RDS}[1]    importrt=@{VNI_RDS}[1]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    @{VNI_VPN_INSTANCE_IDS}[1]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[2]
    ${network3_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[3]
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    ${network2_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network3_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    ${network3_id}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_2_PORTS}[0]    @{VNI_NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_3_PORTS}[0]    @{VNI_NET_3_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_2_PORTS}[0]    @{VNI_NET_3_PORTS}[0]    @{VNI_NETWORKS}[2]
    ...    @{VNI_NETWORKS}[3]    @{NET_2_VM_IPS}[0]    @{NET_3_VM_IPS}[0]    ${IP}

VNI Based L3 Forwarding With BGPVPN With Irt Ert
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With two Networks associated to two BGPVPN.
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[4]
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[5]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[4]    @{VNI_SUBNETS}[4]    @{VNI_SUBNET_CIDRS}[4]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[5]    @{VNI_SUBNETS}[5]    @{VNI_SUBNET_CIDRS}[5]
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[4]    @{VNI_NET_4_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[5]    @{VNI_NET_5_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[4]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI_RDS}[2]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[2]    name=@{VNI_VPN_NAMES}[2]    rd=@{VNI_RDS}[2]    exportrt=@{VNI_RDS}[2]    importrt=@{VNI_RDS}[3]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    @{VNI_VPN_INSTANCE_IDS}[2]
    ${network4_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[4]
    VpnOperations.Associate L3VPN To Network    networkid=${network4_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[2]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    ${network4_id}
    BuiltIn.Log    @{VNI_RDS}[3]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[3]    name=@{VNI_VPN_NAMES}[3]    rd=@{VNI_RDS}[3]    exportrt=@{VNI_RDS}[3]    importrt=@{VNI_RDS}[2]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[3]
    BuiltIn.Should Contain    ${resp}    @{VNI_VPN_INSTANCE_IDS}[3]
    ${network5_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[5]
    VpnOperations.Associate L3VPN To Network    networkid=${network5_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[3]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[3]
    BuiltIn.Should Contain    ${resp}    ${network5_id}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_4_PORTS}[0]    @{VNI_NET_4_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_5_PORTS}[0]    @{VNI_NET_5_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    @{NET_4_VM_IPS}    ${NET_4_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_4_VMS}
    @{NET_5_VM_IPS}    ${NET_5_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_5_VMS}
    BuiltIn.Set Suite Variable    @{NET_4_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_5_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_4_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_5_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_4_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_5_DHCP_IP}    None
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    OVSDB.Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_4_PORTS}[0]    @{VNI_NET_5_PORTS}[0]    @{VNI_NETWORKS}[4]
    ...    @{VNI_NETWORKS}[5]    @{NET_4_VM_IPS}[0]    @{NET_5_VM_IPS}[0]    ${IP}

*** Keywords ***
Suite Setup
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    ...    Create Two VMs for TC1 : (VM1, N1, Compute1) and (VM2, N2, Compute2) and R1
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[0]
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[0]    @{VNI_SUBNETS}[0]    @{VNI_SUBNET_CIDRS}[0]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[1]    @{VNI_SUBNETS}[1]    @{VNI_SUBNET_CIDRS}[1]
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[0]    @{VNI_NET_0_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[1]    @{VNI_NET_1_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Router    @{VNI_ROUTER}[0]
    OpenStackOperations.Add Router Interface    @{VNI_ROUTER}[0]    @{VNI_SUBNETS}[0]
    OpenStackOperations.Add Router Interface    @{VNI_ROUTER}[0]    @{VNI_SUBNETS}[1]
    ${interface_output} =    OpenStackOperations.Show Router Interface    @{VNI_ROUTER}[0]
    ${GWMAC_ADDRS}    ${GWIP_ADDRS} =    VpnOperations.Get Gateway MAC And IP Address    @{VNI_ROUTER}[0]
    BuiltIn.Set Suite Variable    ${GWMAC_ADDRS}
    BuiltIn.Set Suite Variable    ${GWIP_ADDRS}
    ${router_list} =    BuiltIn.Create List    @{VNI_ROUTER}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_0_PORTS}[0]    @{VNI_NET_0_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_1_PORTS}[0]    @{VNI_NET_1_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    @{NET_0_VM_IPS}    ${NET_0_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_0_VMS}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_0_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_0_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_0_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    OpenStackOperations.Show Debugs    @{VNI_NET_0_VMS}    @{VNI_NET_1_VMS}

Suite Teardown
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    OpenStackOperations.OpenStack Suite Teardown
