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
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        Run Keywords    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
${PING_COUNT}     5
${VNI6_SECURITY_GROUP}    vni6_sg
@{VNI6_NETWORKS}    vni6_net_0    vni6_net_1    vni6_net_2    vni6_net_3    vni6_net_4    vni6_net_5
@{VNI6_SUBNETS}    vni6_sub_0    vni6_sub_1    vni6_sub_2    vni6_sub_3    vni6_sub_4    vni6_sub_5
@{VNI6_SUBNET_CIDRS}    2001:db8:0:4::/64    2001:db8:0:5::/64    2001:db8:0:6::/64    2001:db8:0:7::/64    2001:db8:0:8::/64    2001:db8:0:9::/64
${VNI6_NET0_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:4::2,end=2001:db8:0:4:ffff:ffff:ffff:fffe
${VNI6_NET1_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:5::2,end=2001:db8:0:5:ffff:ffff:ffff:fffe
${VNI6_NET2_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:6::2,end=2001:db8:0:6:ffff:ffff:ffff:fffe
${VNI6_NET3_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:7::2,end=2001:db8:0:7:ffff:ffff:ffff:fffe
${VNI6_NET4_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:8::2,end=2001:db8:0:8:ffff:ffff:ffff:fffe
${VNI6_NET5_IPV6_ADDR_POOL}    --allocation-pool start=2001:db8:0:9::2,end=2001:db8:0:9:ffff:ffff:ffff:fffe
@{VNI6_NET_0_PORTS}    vni6_net_0_port_1    vni6_net_0_port_2
@{VNI6_NET_1_PORTS}    vni6_net_1_port_1    vni6_net_1_port_2
@{VNI6_NET_2_PORTS}    vni6_net_2_port_1    vni6_net_2_port_2
@{VNI6_NET_3_PORTS}    vni6_net_3_port_1    vni6_net_3_port_2
@{VNI6_NET_4_PORTS}    vni6_net_4_port_1    vni6_net_4_port_2
@{VNI6_NET_5_PORTS}    vni6_net_5_port_1    vni6_net_5_port_2
@{VNI6_NET_0_VMS}    vni6_net_0_vm_1
@{VNI6_NET_1_VMS}    vni6_net_1_vm_1
@{VNI6_NET_2_VMS}    vni6_net_2_vm_1
@{VNI6_NET_3_VMS}    vni6_net_3_vm_1
@{VNI6_NET_4_VMS}    vni6_net_4_vm_1
@{VNI6_ROUTER}    vni6_router1    vni6_router2
@{VNI6_BGPVPN}    VNI6_BGPVPN1
@{VNI6_RDS}       ["2600:2"]    ["2700:2"]    ["2800:2"]    ["2900:2"]
@{VNI6_VPN_NAMES}    VNI6_vpn_1    VNI6_vpn_2    VNI6_vpn_3    VNI6_vpn_4
@{VNI6_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261551    4ae8cd92-48ca-49b5-94e1-b2921a261552    4ae8cd92-48ca-49b5-94e1-b2921a261553    4ae8cd92-48ca-49b5-94e1-b2921a261554

*** Test Cases ***
VNI Based L3 Forwarding
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    Wait Until Keyword Succeeds    20s    5s    Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_0_PORTS}[0]    @{VNI6_NET_1_PORTS}[0]    @{VNI6_NETWORKS}[0]
    ...    @{VNI6_NETWORKS}[1]    @{NET_0_VM_IPS}[0]    @{NET_1_VM_IPS}[0]

VNI Based L3 Forwarding With BGPVPN Router Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Router associated to a BGPVPN.
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI6_RDS}[0]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]    name=@{VNI6_VPN_NAMES}[0]    rd=@{VNI6_RDS}[0]    exportrt=@{VNI6_RDS}[0]    importrt=@{VNI6_RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI6_ROUTER}[0]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    Wait Until Keyword Succeeds    20s    5s    Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_0_PORTS}[0]    @{VNI6_NET_1_PORTS}[0]    @{VNI6_NETWORKS}[0]
    ...    @{VNI6_NETWORKS}[1]    @{NET_0_VM_IPS}[0]    @{NET_1_VM_IPS}[0]

VNI Based L3 Forwarding With BGPVPN Network Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Networks associated to a BGPVPN.
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[2]
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[3]
    ${net2_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET2_IPV6_ADDR_POOL}
    ${net3_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET3_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[2]    @{VNI6_SUBNETS}[2]    @{VNI6_SUBNET_CIDRS}[2]    ${net2_additional_args}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[3]    @{VNI6_SUBNETS}[3]    @{VNI6_SUBNET_CIDRS}[3]    ${net3_additional_args}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[2]    @{VNI6_NET_2_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[3]    @{VNI6_NET_3_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[2]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI6_RDS}[1]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]    name=@{VNI6_VPN_NAMES}[1]    rd=@{VNI6_RDS}[1]    exportrt=@{VNI6_RDS}[1]    importrt=@{VNI6_RDS}[1]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[1]
    ${network2_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[2]
    ${network3_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[3]
    VpnOperations.Associate L3VPN To Network    networkid=${network2_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    ${network2_id}
    VpnOperations.Associate L3VPN To Network    networkid=${network3_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[1]
    BuiltIn.Should Contain    ${resp}    ${network3_id}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_2_PORTS}[0]    @{VNI6_NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_3_PORTS}[0]    @{VNI6_NET_3_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None
    Wait Until Keyword Succeeds    20s    5s    Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_2_PORTS}[0]    @{VNI6_NET_3_PORTS}[0]    @{VNI6_NETWORKS}[2]
    ...    @{VNI6_NETWORKS}[3]    @{NET_2_VM_IPS}[0]    @{NET_3_VM_IPS}[0]

VNI Based L3 Forwarding With BGPVPN With Irt Ert
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Networks associated to a BGPVPN.
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[4]
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[5]
    ${net4_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET4_IPV6_ADDR_POOL}
    ${net5_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET5_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[4]    @{VNI6_SUBNETS}[4]    @{VNI6_SUBNET_CIDRS}[4]    ${net4_additional_args}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[5]    @{VNI6_SUBNETS}[5]    @{VNI6_SUBNET_CIDRS}[5]    ${net5_additional_args}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[4]    @{VNI6_NET_4_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI6_NETWORKS}[5]    @{VNI6_NET_5_PORTS}[0]    sg=${VNI6_SECURITY_GROUP}
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[4]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI6_RDS}[2]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]    name=@{VNI6_VPN_NAMES}[2]    rd=@{VNI6_RDS}[2]    exportrt=@{VNI6_RDS}[2]    importrt=@{VNI6_RDS}[3]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[2]
    ${network4_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[4]
    VpnOperations.Associate L3VPN To Network    networkid=${network4_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[2]
    BuiltIn.Should Contain    ${resp}    ${network4_id}
    BuiltIn.Log    @{VNI6_RDS}[3]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[3]    name=@{VNI6_VPN_NAMES}[3]    rd=@{VNI6_RDS}[3]    exportrt=@{VNI6_RDS}[3]    importrt=@{VNI6_RDS}[2]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[3]
    BuiltIn.Should Contain    ${resp}    @{VNI6_VPN_INSTANCE_IDS}[3]
    ${network5_id} =    OpenStackOperations.Get Net Id    @{VNI6_NETWORKS}[5]
    VpnOperations.Associate L3VPN To Network    networkid=${network5_id}    vpnid=@{VNI6_VPN_INSTANCE_IDS}[3]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI6_VPN_INSTANCE_IDS}[3]
    BuiltIn.Should Contain    ${resp}    ${network5_id}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_4_PORTS}[0]    @{VNI6_NET_4_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI6_NET_5_PORTS}[0]    @{VNI6_NET_5_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${VNI6_SECURITY_GROUP}
    @{NET_4_VM_IPS}    ${NET_4_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_4_VMS}
    @{NET_5_VM_IPS}    ${NET_5_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_5_VMS}
    BuiltIn.Set Suite Variable    @{NET_4_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_5_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_4_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_5_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_4_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_5_DHCP_IP}    None
    Wait Until Keyword Succeeds    20s    5s    Verify Vni Segmentation Id and Tunnel Id    @{VNI6_NET_4_PORTS}[0]    @{VNI6_NET_5_PORTS}[0]    @{VNI6_NETWORKS}[4]
    ...    @{VNI6_NETWORKS}[5]    @{NET_4_VM_IPS}[0]    @{NET_5_VM_IPS}[0]

*** Keywords ***
Verify Vni Segmentation Id and Tunnel Id
    [Arguments]    ${port1}    ${port2}    ${net1}    ${net2}    ${vm1_ip}    ${vm2_ip}
    [Documentation]    Get tunnel id and packet count from specified table id and destination port mac address
    ${port_mac1} =    OpenStackOperations.Get Port Mac    ${port1}
    ${port_mac2} =    OpenStackOperations.Get Port Mac    ${port2}
    ${segmentation_id1} =    OpenStackOperations.Get Network Segmentation Id    ${net1}
    ${segmentation_id2} =    OpenStackOperations.Get Network Segmentation Id    ${net2}
    ${egress_tun_id}    ${before_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${segmentation_id2}
    ...    dst_mac=${port_mac2}
    Should Be Equal As Numbers    ${segmentation_id2}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${segmentation_id1}
    ...    dst_mac=${port_mac1}
    Should Be Equal As Numbers    ${segmentation_id1}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}    tun_id=${segmentation_id1}
    Should Be Equal As Numbers    ${segmentation_id1}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}    tun_id=${segmentation_id2}
    Should Be Equal As Numbers    ${segmentation_id2}    ${ingress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net1}    ${vm1_ip}    ping -c ${PING_COUNT} ${vm2_ip}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${tun_id}    ${after_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${segmentation_id2}
    ...    dst_mac=${port_mac2}
    ${tun_id}    ${after_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}    tun_id=${segmentation_id1}
    ${tun_id}    ${after_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${segmentation_id1}
    ...    dst_mac=${port_mac1}
    ${tun_id}    ${after_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}    tun_id=${segmentation_id2}
    ${diff_count_egress_port1} =    Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    Should Be True    ${diff_count_egress_port1} == ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port1} >= ${PING_COUNT}
    Should Be True    ${diff_count_egress_port2} == ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port2} >= ${PING_COUNT}

Start Suite
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    ...    Create Two VMs for TC1 : (VM1, N1, Compute1) and (VM2, N2, Compute2) and R1
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI6_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[0]
    OpenStackOperations.Create Network    @{VNI6_NETWORKS}[1]
    ${net0_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET0_IPV6_ADDR_POOL}
    ${net1_additional_args} =    BuiltIn.Catenate    --ip-version=6 --ipv6-address-mode=slaac --ipv6-ra-mode=slaac ${VNI6_NET1_IPV6_ADDR_POOL}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[0]    @{VNI6_SUBNETS}[0]    ${VNI6_SUBNET_CIDRS[0]}    ${net0_additional_args}
    OpenStackOperations.Create SubNet    @{VNI6_NETWORKS}[1]    @{VNI6_SUBNETS}[1]    @{VNI6_SUBNET_CIDRS}[1]    ${net1_additional_args}
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
    @{NET_0_VM_IPS}    ${NET_0_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_0_VMS}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI6_NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_0_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_0_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_0_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
