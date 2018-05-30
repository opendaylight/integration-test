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
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${EGRESS}         Egress
${INGRESS}        Ingress
@{direction}      Egress    Ingress
${PING_COUNT}     5
${VNI_SECURITY_GROUP}    vni_sg
@{VNI_NETWORKS}    vni_net_1
@{VNI_SUBNETS}    vni_sub_1    vni_sub_2    vni_sub_3
@{VNI_SUBNET_CIDRS}    71.1.1.0/24    72.1.1.0/24    73.1.1.0/24
@{VNI_NET_1_PORTS}    vni_net_1_port_1    vni_net_1_port_2
@{VNI_NET_1_VMS}    vni_net_1_vm_1    vni_net_1_vm_2

*** Test Cases ***
VNI Based L2 Switching
    [Documentation]    verify VNI id for L2 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ${port_mac1} =    OpenStackOperations.Get Port Mac    ${VNI_NET_1_PORTS[0]}
    ${port_mac2} =    OpenStackOperations.Get Port Mac    ${VNI_NET_1_PORTS[1]}
    ${segmentation_id} =    OpenStackOperations.Get Network Segmentation Id    ${OS_CMP1_CONN_ID}    @{VNI_NETWORKS}[0]
    ${egress_tun_id}    ${before_count_egress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${ELAN_DMACTABLE}    direction=${EGRESS}    dst_mac=${port_mac2}
    Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${ELAN_DMACTABLE}    direction=${EGRESS}    dst_mac=${port_mac1}
    Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{VNI_NETWORKS}[0]    @{vni_net_1_vm_ips}[0]    ping -c ${PING_COUNT} @{vni_net_1_vm_ips}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${tun_id}    ${after_count_egress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${ELAN_DMACTABLE}    direction=${EGRESS}    dst_mac=${port_mac2}
    ${tun_id}    ${after_count_ingress_port1} =    Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    ${tun_id}    ${after_count_egress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${ELAN_DMACTABLE}    direction=${EGRESS}    dst_mac=${port_mac1}
    ${tun_id}    ${after_count_ingress_port2} =    Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${INTERNAL_TUNNEL_TABLE}    direction=${INGRESS}
    ${diff_count_egress_port1} =    Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    Should Be True    ${diff_count_egress_port1} >= ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port1} >= ${PING_COUNT}
    Should Be True    ${diff_count_egress_port2} >= ${PING_COUNT}
    Should Be True    ${diff_count_ingress_port2} >= ${PING_COUNT}

*** Keywords ***
Get Tunnel Id And Packet Count
    [Arguments]    ${conn_id}    ${table_id}    ${direction}    ${dst_mac}=""
    [Documentation]    Get tunnel id and packet count from specified table id and destination port mac address
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | grep ${dst_mac} | awk '{split($7,a,"[:-]"); print a[2]}'
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
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
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Network    @{VNI_NETWORKS}[0]
    OpenStackOperations.Create SubNet    @{VNI_NETWORKS}[0]    @{VNI_SUBNETS}[0]    ${VNI_SUBNET_CIDRS[0]}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[0]    ${VNI_NET_1_PORTS[0]}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Port    @{VNI_NETWORKS}[0]    ${VNI_NET_1_PORTS[1]}    sg=${VNI_SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${VNI_NET_1_PORTS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${VNI_NET_1_PORTS[0]}    ${VNI_NET_1_VMS[0]}    ${OS_CMP1_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${VNI_NET_1_PORTS[1]}    ${VNI_NET_1_VMS[1]}    ${OS_CMP2_HOSTNAME}    sg=${VNI_SECURITY_GROUP}
    @{vni_net_1_vm_ips}    ${vni_net_1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{VNI_NET_1_VMS}
    BuiltIn.Set Suite Variable    @{vni_net_1_vm_ips}
    BuiltIn.Should Not Contain    ${vni_net_1_vm_ips}    None
    BuiltIn.Should Not Contain    ${vni_net_1_dhcp_ip}    None
