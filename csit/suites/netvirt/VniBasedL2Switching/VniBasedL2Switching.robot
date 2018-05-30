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
Test Setup        Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP1_CONN_ID}
...               AND    OpenStackOperations.Get DumpFlows And Ovsconfig    ${OS_CMP2_CONN_ID}
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/Genius.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${vni_security_group}    vni_sg
@{vni_networks}    vni_net_1
@{vni_subnets}    vni_sub_1    vni_sub_2    vni_sub_3
@{vni_subnet_cidrs}    81.1.1.0/24    82.1.1.0/24    83.1.1.0/24
@{vni_net_1_ports}    vni_net_1_port_1    vni_net_1_port_2
@{vni_net_1_vms}    vni_net_1_vm_1    vni_net_1_vm_2
@{table_ids}      51    36

*** Test Cases ***
VNI Based L2 Switching
    [Documentation]    verify VNI id for L2 Unicast frames exchanged over OVS datapaths that are on different hypervisors
    ${port_mac1} =    Get Port Mac    ${vni_net_1_ports[0]}
    ${port_mac2} =    Get Port Mac    ${vni_net_1_ports[1]}
    ${segmentation_id} =    Get Segmentation Id    ${OS_CMP1_CONN_ID}    @{vni_networks}[0]
    ${egress_tun_id}    ${before_count_egress_port1} =    Get Tunnel Id And Packet Count For Egress    ${OS_CMP1_CONN_ID}    ${port_mac2}    ${port_mac1}    @{table_ids}[0]
    Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    Get Tunnel Id And Packet Count For Egress    ${OS_CMP2_CONN_ID}    ${port_mac1}    ${port_mac2}    @{table_ids}[0]
    Should Be Equal As Numbers    ${segmentation_id}    ${egress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port1} =    Get Tunnel Id And Packet Count For Ingress    ${OS_CMP1_CONN_ID}    @{table_ids}[1]
    Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${ingress_tun_id}    ${before_count_ingress_port2} =    Get Tunnel Id And Packet Count For Ingress    ${OS_CMP2_CONN_ID}    @{table_ids}[1]
    Should Be Equal As Numbers    ${segmentation_id}    ${ingress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{vni_networks}[0]    @{vni_net_1_vm_ips}[0]    ping -c 3 @{vni_net_1_vm_ips}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${tun_id}    ${after_count_egress_port1} =    Get Tunnel Id And Packet Count For Egress    ${OS_CMP1_CONN_ID}    ${port_mac2}${port_mac1}    @{table_ids}[0]
    ${tun_id}    ${after_count_ingress_port1} =    Get Tunnel Id And Packet Count For Ingress    ${OS_CMP1_CONN_ID}    @{table_ids}[1]
    ${tun_id}    ${after_count_egress_port2} =    Get Tunnel Id And Packet Count For Egress    ${OS_CMP2_CONN_ID}    ${port_mac1}${port_mac2}    @{table_ids}[0]
    ${tun_id}    ${after_count_ingress_port2} =    Get Tunnel Id And Packet Count For Ingress    ${OS_CMP2_CONN_ID}    @{table_ids}[1]
    ${diff_count_egress_port1} =    Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_ingress_port1} =    Evaluate    ${after_count_ingress_port1} - ${before_count_ingress_port1}
    ${diff_count_egress_port2} =    Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    ${diff_count_ingress_port2} =    Evaluate    ${after_count_ingress_port2} - ${before_count_ingress_port2}
    Should Not Be Equal    ${diff_count_egress_port1}    0
    Should Not Be Equal    ${diff_count_ingress_port1}    0
    Should Not Be Equal    ${diff_count_egress_port2}    0
    Should Not Be Equal    ${diff_count_ingress_port2}    0

*** Keywords ***
Get Tunnel Id And Packet Count For Egress
    [Arguments]    ${conn_id}    ${port_mac1}    ${port_mac2}    ${table_id}
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | grep ${port_mac1} |awk '{split($7,a,"[:-]"); print a[2]}'
    ${output} =    Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${output} =    Set Variable    ${list[0]}
    ${tunnel_id} =    Convert To Integer    ${output}    16
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | grep ${port_mac2} |awk '{split($4,a,"[=,]"); {print a[2]}}'
    ${output} =    Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${packet_count} =    Set Variable    ${list[0]}
    [Return]    ${tunnel_id}    ${packet_count}

Get Tunnel Id And Packet Count For Ingress
    [Arguments]    ${conn_id}    ${table_id}
    SSHLibrary.Switch Connection    ${conn_id}
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | awk '{split($6,a,"=");print a[3]}'
    ${output} =    Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${output} =    Set Variable    ${list[0]}
    ${tunnel_id} =    Convert To Integer    ${output}    16
    ${cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${table_id} | awk '{split($4,a,"[=,]"); {print a[2]}}'
    ${output} =    Write Commands Until Expected Prompt    ${cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    Split String    ${output}
    ${packet_count} =    Set Variable    ${list[0]}
    [Return]    ${tunnel_id}    ${packet_count}

Get Segmentation Id
    [Arguments]    ${conn_id}    ${network_name}
    SSHLibrary.Switch Connection    ${conn_id}
    ${output} =    OpenStack CLI    openstack network show ${network_name} | grep segmentation_id | awk '{print $4}'
    @{list} =    Split String    ${output}
    ${output} =    Set Variable    ${list[0]}
    [Return]    ${output}

Start Suite
    [Documentation]    Basic setup.
    OpenStackOperations.OpenStack Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${vni_security_group}
    OpenStackOperations.Create Network    @{vni_networks}[0]
    OpenStackOperations.Create SubNet    @{vni_networks}[0]    @{vni_subnets}[0]    ${vni_subnet_cidrs[0]}
    OpenStackOperations.Create Port    @{vni_networks}[0]    ${vni_net_1_ports[0]}    sg=${vni_security_group}
    OpenStackOperations.Create Port    @{vni_networks}[0]    ${vni_net_1_ports[1]}    sg=${vni_security_group}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${PORT_URL}    ${vni_net_1_ports}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${vni_net_1_ports[0]}    ${vni_net_1_vms[0]}    ${OS_CMP1_HOSTNAME}    sg=${vni_security_group}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${vni_net_1_ports[1]}    ${vni_net_1_vms[1]}    ${OS_CMP2_HOSTNAME}    sg=${vni_security_group}
    @{vni_net_1_vm_ips}    ${vni_net_1_dhcp_ip} =    OpenStackOperations.Get VM IPs    @{vni_net_1_vms}
    BuiltIn.Set Suite Variable    @{vni_net_1_vm_ips}
    BuiltIn.Should Not Contain    ${vni_net_1_vm_ips}    None
    BuiltIn.Should Not Contain    ${vni_net_1_dhcp_ip}    None
