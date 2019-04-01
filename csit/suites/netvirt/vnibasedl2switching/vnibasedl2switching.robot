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
${VNI_SECURITY_GROUP}    vni_l2_sg
@{VNI_NETWORKS}    vni_l2_net_1
@{VNI_SUBNETS}    vni_l2_sub_1    vni_l2_sub_2    vni_l2_sub_3
@{VNI_SUBNET_CIDRS}    71.1.1.0/24    72.1.1.0/24    73.1.1.0/24
@{VNI_NET_1_PORTS}    vni_l2_net_1_port_1    vni_l2_net_1_port_2
@{VNI_NET_1_VMS}    vni_l2_net_1_vm_1    vni_l2_net_1_vm_2

*** Test Cases ***
VNI Based L2 Switching
    [Documentation]    verify VNI id for L2 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    BuiltIn.Pass Execution If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"    "Test is not supported for combo node"
    ${port_mac1} =    OpenStackOperations.Get Port Mac    @{VNI_NET_1_PORTS}[0]
    ${port_mac2} =    OpenStackOperations.Get Port Mac    @{VNI_NET_1_PORTS}[1]
    ${segmentation_id} =    OpenStackOperations.Get Network Segmentation Id    @{VNI_NETWORKS}[0]
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{VNI_NETWORKS}[0]    @{VNI_NET_1_VM_IPS}[0]    ping -c ${DEFAULT_PING_COUNT} @{VNI_NET_1_VM_IPS}[1]
    ${egress_tun_id}    ${before_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${ELAN_DMACTABLE}    tun_id=${segmentation_id}    mac=${port_mac2}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${ELAN_DMACTABLE}    tun_id=${segmentation_id}    mac=${port_mac1}
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    tun_id=${segmentation_id}    mac=""
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    tun_id=${segmentation_id}    mac=""
    BuiltIn.Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{VNI_NETWORKS}[0]    @{VNI_NET_1_VM_IPS}[0]    ping -c ${DEFAULT_PING_COUNT} @{VNI_NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${tun_id}    ${after_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${ELAN_DMACTABLE}    tun_id=${segmentation_id}    mac=${port_mac2}
    ${tun_id}    ${after_count_ingress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    tun_id=${segmentation_id}    mac=""
    ${tun_id}    ${after_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${ELAN_DMACTABLE}    tun_id=${segmentation_id}    mac=${port_mac1}
    ${tun_id}    ${after_count_ingress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    tun_id=${segmentation_id}    mac=""
    ${diff_count_egress_port1} =    BuiltIn.Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    BuiltIn.Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    BuiltIn.Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    BuiltIn.Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    BuiltIn.Should Be True    ${diff_count_egress_port1} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_ingress_port1} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_egress_port2} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_ingress_port2} >= ${DEFAULT_PING_COUNT}

*** Keywords ***
Suite Setup
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs.
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[0]    @{VNI_SUBNETS}[0]    @{VNI_SUBNET_CIDRS}[0]
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[0]    @{VNI_NET_1_PORTS}[0]    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[0]    @{VNI_NET_1_PORTS}[1]    sg=${VNI_SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${VNI_NET_1_PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_1_PORTS}[0]    @{VNI_NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NET_1_PORTS}[1]    @{VNI_NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    @{VNI_NET_1_VM_IPS}    ${vni_net_1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VNI_NET_1_VMS}
    BuiltIn.Set Suite Variable    @{VNI_NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${VNI_NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${vni_net_1_dhcp_ip}    None
    OpenStackOperations.Show Debugs    @{VNI_NET_1_VMS}

Suite Teardown
    BuiltIn.Return From Keyword If    "${OPENSTACK_TOPO}" == "1cmb-0ctl-0cmp"
    OpenStackOperations.OpenStack Suite Teardown
