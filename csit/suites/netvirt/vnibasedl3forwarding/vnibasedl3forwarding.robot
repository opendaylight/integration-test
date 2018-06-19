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
${PING_COUNT}     5
${EGRESS}         Egress
${INGRESS}        Ingress
${VNI_SECURITY_GROUP}    vni_sg
@{VNI_NETWORKS}    vni_net_0    vni_net_1    vni_net_2    vni_net_3    vni_net_4    vni_net_5
@{VNI_SUBNETS}    vni_sub_0    vni_sub_1    vni_sub_2    vni_sub_3    vni_sub_4    vni_sub_5
@{VNI_SUBNET_CIDRS}    61.1.1.0/24    62.1.1.0/24    63.1.1.0/24    64.1.1.0/24    65.1.1.0/24    66.1.1.0/24
@{VNI_NET_0_PORTS}    vni_net_0_port_1    vni_net_0_port_2
@{VNI_NET_1_PORTS}    vni_net_1_port_1    vni_net_1_port_2
@{VNI_NET_2_PORTS}    vni_net_2_port_1    vni_net_2_port_2
@{VNI_NET_3_PORTS}    vni_net_3_port_1    vni_net_3_port_2
@{VNI_NET_0_VMS}    vni_net_0_vm_1
@{VNI_NET_1_VMS}    vni_net_1_vm_1
@{VNI_NET_2_VMS}    vni_net_2_vm_1
@{VNI_NET_3_VMS}    vni_net_3_vm_1
@{VNI_ROUTER}         vni_router1    vni_router2
@{VNI_BGPVPN}         VNI_BGPVPN1
@{VNI_RDS}            ["2200:2"]    ["2300:2"]    ["2400:2"]
@{VNI_VPN_NAMES}      vni_vpn_1    vni_vpn_2    vni_vpn_3
@{VNI_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441    4ae8cd92-48ca-49b5-94e1-b2921a261442    4ae8cd92-48ca-49b5-94e1-b2921a261443

*** Test Cases ***
VNI Based L3 Forwarding
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_0_PORTS}[0]    @{VNI_NET_1_PORTS}[0]    @{VNI_NETWORKS}[0]    @{VNI_NETWORKS}[1]    @{VNI_NET_0_VMS}[0]    @{VNI_NET_1_VMS}[0]

VNI Based L3 Forwarding With BGPVPN Router Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Router associated to a BGPVPN.
    ${net_id} =    OpenStackOperations.Get Net Id    @{VNI_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    BuiltIn.Log    @{VNI_RDS}[1]
    VpnOperations.VPN Create L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[1]    name=@{VNI_VPN_NAMES}[0]    rd=@{VNI_RDS}[0]    exportrt=@{VNI_RDS}[0]    importrt=@{VNI_RDS}[0]    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    @{VNI_VPN_INSTANCE_IDS}[0]
    ${router_id} =    OpenStackOperations.Get Router Id    @{VNI_ROUTER}[0]
    VpnOperations.Associate VPN to Router    routerid=${router_id}    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=@{VNI_VPN_INSTANCE_IDS}[0]
    BuiltIn.Should Contain    ${resp}    ${router_id}
    Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_0_PORTS}[0]    @{VNI_NET_1_PORTS}[0]    @{VNI_NETWORKS}[0]    @{VNI_NETWORKS}[1]    @{VNI_NET_0_VMS}[0]    @{VNI_NET_1_VMS}[0]

VNI Based L3 Forwarding With BGPVPN Network Association
    [Documentation]    verify VNI id for L3 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ...    With Networks associated to a BGPVPN.
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[2]
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[3]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[2]    @{VNI_SUBNETS}[2]    ${VNI_SUBNET_CIDRS[2]}
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
    Verify Vni Segmentation Id and Tunnel Id    @{VNI_NET_2_PORTS}[0]    @{VNI_NET_3_PORTS}[0]    @{VNI_NETWORKS}[2]    @{VNI_NETWORKS}[3]    @{VNI_NET_2_VMS}[0]    @{VNI_NET_3_VMS}[0]

*** Keywords ***
Verify Vni Segmentation Id and Tunnel Id
    [Arguments]    ${port1}    ${port2}    ${net1}    ${net2}    ${vm1_ip}    ${vm2_ip}
    [Documentation]    Get tunnel id and packet count from specified table id and destination port mac address
    ${port_mac1} =    OpenStackOperations.Get Port Mac    ${port1}
    ${port_mac2} =    OpenStackOperations.Get Port Mac    ${port2}
    ${segmentation_id1} =    OpenStackOperations.Get Network Segmentation Id    ${OS_CMP1_CONN_ID}    ${net1}
    ${segmentation_id2} =    OpenStackOperations.Get Network Segmentation Id    ${OS_CMP1_CONN_ID}    ${net2}
    ${egress_tun_id}    ${before_count_egress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    dst_mac=${port_mac2}
    Should Be Equal As Numbers    ${segmentation_id2}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    dst_mac=${port_mac1}
    Should Be Equal As Numbers    ${segmentation_id1}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    Should Be Equal As Numbers    ${segmentation_id1}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    Should Be Equal As Numbers    ${segmentation_id2}    ${ingress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${net1}    ${vm1_ip}    ping -c ${PING_COUNT} ${vm2_ip}
    BuiltIn.Should Contain    ${output}    64 bytes
    ${tun_id}    ${after_count_egress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    dst_mac=${port_mac2}
    ${tun_id}    ${after_count_ingress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    ${tun_id}    ${after_count_egress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    dst_mac=${port_mac1}
    ${tun_id}    ${after_count_ingress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    ${diff_count_egress_port1} =    Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    Should Be True    ${diff_count_egress_port1} = ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port1} = ${PING_COUNT}
    Should Be True    ${diff_count_egress_port2} = ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port2} = ${PING_COUNT}

Get Tunnel Id And Packet Count
    [Arguments]    ${conn_id}    ${table_id}    ${direction}    ${dst_mac}=""
    [Documentation]    Get tunnel id and packet count from specified table id and destination port mac address
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id}
    ${cmd1} =    BuiltIn.Run Keyword If    "${direction}" == "Egress"    BuiltIn.Catenate    ${cmd}    | grep ${dst_mac} | awk '{split($7,a,"[:-]"); print a[2]}'
    ...    ELSE    BuiltIn.Catenate    ${cmd} | awk '{split($6,a,"[,=]"); {print a[4]}}'
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd1}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${output} =    Set Variable    ${list[0]}
    ${tunnel_id} =    Convert To Integer    ${output}    16
    ${cmd1} =    BuiltIn.Run Keyword If    "${direction}" == "Egress"    BuiltIn.Catenate    ${cmd}    | grep ${dst_mac} | awk '{split($4,a,"[=,]"); {print a[2]}}'
    ...    ELSE    BuiltIn.Catenate    ${cmd} | awk '{split($4,a,"[=,]"); {print a[2]}}'
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd1}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${packet_count} =    Set Variable    ${list[0]}
    [Return]    ${tunnel_id}    ${packet_count}

Start Suite
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    ...    Create Two VMs for TC1 : (VM1, N1, Compute1) and (VM2, N2, Compute2) and R1
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[0]
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[1]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[0]    @{VNI_SUBNETS}[0]    ${VNI_SUBNET_CIDRS[0]}
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
