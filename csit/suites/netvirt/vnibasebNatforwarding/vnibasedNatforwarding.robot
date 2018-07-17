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
Resource          ../../../libraries/L2GatewayOperations.robot
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
${VNI_NAT_EXTERNAL_BGPVPN}    vni_nat_external_bgpvpn
${VNI_NAT_EXTERNAL_NETWORKS}    vni_nat_external_network
${VNI_NAT_EXTERNAL_SUBNET}    vni_nat_external_subnet
${VNI_NAT_EXTERNAL_SUBNET_CIDRS}    100.100.100.0/24
${VNI_NAT_NETWORKS}    vni_nat_net
@{VNI_NAT_PORTS}    vni_nat_port_1    vni_nat_port_2
${VNI_NAT_PROVIDER_NETWORK_TYPE}    gre
${VNI_NAT_ROUTER}    vni_nat_router
${VNI_NAT_SECURITY_GROUP}    vni_nat_sg
${VNI_NAT_SUBNET_CIDRS}    71.1.1.0/24
${VNI_NAT_SUBNETS}    vni_nat_sub
@{VNI_NAT_VMS}    vni_nat_vm_1    vni_nat_vm_2
${VNI_PORT}       vni_port3
${VNI_VM}         vni_vm3
${VNI_NAT_RDS}    ["2200:2"]
${VNI_NAT_VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441

*** Test Cases ***
Vni Based NAT Forwarding DNAT To DNAT
    [Documentation]    verify VNI id for L3 Unicast with NAT configured and DNAT traffic is successful over OVS datapaths that are on different hypervisors
    BuiltIn.Wait Until Keyword Succeeds    60s    5s    Verify Nat Based Vni Segmentation Id and Tunnel Id

Vni Based NAT Forwarding SNAT To DNAT
    [Documentation]    verify VNI id for L3 Unicast with NAT configured and SNAT to DNAT traffic is successful over OVS datapaths that are on different hypervisors
    #get nat switch
    ${napt_switch_id} =    OpenStackOperations.Get Napt Switch Id Rest
    ${dpn_id1} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP1_CONN_ID}
    ${dpn_id2} =    L2GatewayOperations.Get Dpnid Decimal    ${OS_CMP2_CONN_ID}
    BuiltIn.Run Keyword If    "${dpn_id1}" == "${napt_switch_id}"    Verify Snat Based Vni Segmentation Id and Tunnel Id    ${OS_CMP1_CONN_ID}    ${OS_CMP2_CONN_ID}    ${OS_CMP2_HOSTNAME}
    ... ELSE    Verify Snat Based Vni Segmentation Id and Tunnel Id    ${OS_CMP2_CONN_ID}    ${OS_CMP1_CONN_ID}    ${OS_CMP1_HOSTNAME}

*** Keywords ***
Verify Nat Based Vni Segmentation Id and Tunnel Id
    [Documentation]    verify VNI id for L3 Unicast frames exchanged with NAT Configured.
    ...    The two vms are having floating ip configured.
    ...    Send Ping traffic from vm1 to vm2 floating ip and verify the dnat traffic is successful.
    ${external_router_vni_value} =    OpenStackOperations.Get Vni Value    ${EMPTY}    ${VNI_NAT_VPN_INSTANCE_IDS}
    ${egress_tun_id}    ${before_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${external_router_vni_value}
    ...    dst_mac=@{VM_FLOATING_IPS}[1]
    BuiltIn.Should Be Equal As Numbers    ${external_router_vni_value}    ${egress_tun_id}
    ${egress_tun_id}    ${before_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${external_router_vni_value}
    ...    dst_mac=@{VM_FLOATING_IPS}[0]
    BuiltIn.Should Be Equal As Numbers    ${external_router_vni_value}    ${egress_tun_id}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    ${VNI_NAT_NETWORKS}    @{NET_VM_IPS}[0]    ping -c ${DEFAULT_PING_COUNT} @{VM_FLOATING_IPS}[1]
    BuiltIn.Should Contain    ${output}    64 bytes
    ${egress_tun_id}    ${after_count_egress_port1} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP1_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${external_router_vni_value}
    ...    dst_mac=@{VM_FLOATING_IPS}[1]
    BuiltIn.Should Be Equal As Numbers    ${external_router_vni_value}    ${egress_tun_id}
    ${egress_tun_id}    ${after_count_egress_port2} =    OVSDB.Get Tunnel Id And Packet Count    ${OS_CMP2_CONN_ID}    ${L3_TABLE}    direction=${EGRESS}    tun_id=${external_router_vni_value}
    ...    dst_mac=@{VM_FLOATING_IPS}[0]
    BuiltIn.Should Be Equal As Numbers    ${external_router_vni_value}    ${egress_tun_id}
    ${diff_count_egress_port1} =    BuiltIn.Evaluate    ${after_count_egress_port1} - ${before_count_egress_port1}
    ${diff_count_egress_port2} =    BuiltIn.Evaluate    ${after_count_egress_port2} - ${before_count_egress_port2}
    BuiltIn.Should Be True    ${diff_count_egress_port1} >= ${DEFAULT_PING_COUNT}
    BuiltIn.Should Be True    ${diff_count_egress_port2} >= ${DEFAULT_PING_COUNT}

Verify Snat Based Vni Segmentation Id and Tunnel Id
    [Arguments]    ${napt_switch_id}    ${non_napt_switch_id}    ${host_name}
    [Documentation]    verify VNI id for L3 Unicast frames exchanged with NAT Configured.
    ...    Boot VM (vm3) in nonnapt switch without association to floating IP.
    ...    Send netcat tcp/udp traffic from vm3 to vm1 floating ip and verify the snat traffic is successful.
    ${router_vni_value} =    OpenStackOperations.Get Vni Value    ${VNI_NAT_ROUTER}    ${EMPTY}
    OpenStackOperations.Create Port    ${VNI_NAT_NETWORKS}    ${VNI_PORT}    sg=${VNI_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    ${VNI_PORT}    ${VNI_VM}    ${host_name}    sg=${VNI_NAT_SECURITY_GROUP}
    ${VNI_NAT_VMS} =    Collections.Append To List    ${VNI_VM}
    @{NET_VM_IPS}    ${NET_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NAT_VMS}
    BuiltIn.Should Not Contain    ${NET_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_DHCP_IP}    None
    ${base_cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${INTERNAL_TUNNEL_TABLE} | grep ${router_vni_value}
    SSHLibrary.Switch Connection    ${napt_switch_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${base_cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${full_cmd} =    BuiltIn.Catenate    ${base_cmd}    | awk '{split($6,a,"[,=]"); {print a[5]}}'
    ${output} =    Utils.Write Commands Until Expected Prompt    ${full_cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${output} =    BuiltIn.Set Variable    @{list}[0]
    ${tunnel_id} =    BuiltIn.Convert To Integer    ${output}    16
    BuiltIn.Should Be Equal As Numbers    ${router_vni_value}    ${tunnel_id}
    ${base_cmd} =    BuiltIn.Set Variable    sudo ovs-ofctl dump-flows br-int -OOpenFlow13 | grep table=${PSNAT_TABLE} | grep ${router_vni_value}
    SSHLibrary.Switch Connection    ${non_napt_switch_id}
    ${output} =    Utils.Write Commands Until Expected Prompt    ${base_cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    ${full_cmd} =    BuiltIn.Catenate    ${base_cmd}    | awk '{split($7,a,"[:-]"); print a[2]}'
    ${output} =    Utils.Write Commands Until Expected Prompt    ${full_cmd}    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{list} =    String.Split String    ${output}
    ${output} =    BuiltIn.Set Variable    @{list}[0]
    ${tunnel_id} =    BuiltIn.Convert To Integer    ${output}    16
    BuiltIn.Should Be Equal As Numbers    ${router_vni_value}    ${tunnel_id}
    OpenStackOperations.Test Netcat Operations From Vm Instance    ${VNI_NAT_NETWORKS}    @{NET_VM_IPS}[2]    @{VM_FLOATING_IPS}[0]

Start Suite
    [Documentation]    Create Basic setup for the feature. Creates single network, subnet, two ports and two VMs, Router.
    ...    Associate subnet to router
    ...    Create External network and associate it to router
    ...    Create floating IPs and associate them to the Vms created
    VpnOperations.Basic Suite Setup
    OpenStackOperations.Create Allow All SecurityGroup    ${VNI_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Network    ${VNI_NAT_NETWORKS}
    OpenStackOperations.Create SubNet    ${VNI_NAT_NETWORKS}    ${VNI_NAT_SUBNETS}    ${VNI_NAT_SUBNET_CIDRS}
    OpenStackOperations.Create Port    ${VNI_NAT_NETWORKS}    @{VNI_NAT_PORTS}[0]    sg=${VNI_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Port    ${VNI_NAT_NETWORKS}    @{VNI_NAT_PORTS}[1]    sg=${VNI_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Router    ${VNI_NAT_ROUTER}
    OpenStackOperations.Add Router Interface    ${VNI_NAT_ROUTER}    ${VNI_NAT_SUBNETS}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NAT_PORTS}[0]    @{VNI_NAT_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${VNI_NAT_SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{VNI_NAT_PORTS}[1]    @{VNI_NAT_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${VNI_NAT_SECURITY_GROUP}
    @{NET_VM_IPS}    ${NET_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{VNI_NAT_VMS}
    BuiltIn.Set Suite Variable    @{NET_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_DHCP_IP}    None
    ${net_additional_args} =    BuiltIn.Catenate    --external --provider-network-type ${VNI_NAT_PROVIDER_NETWORK_TYPE}
    OpenStackOperations.Create Network    ${VNI_NAT_EXTERNAL_NETWORKS}    ${net_additional_args}
    OpenStackOperations.Create SubNet    ${VNI_NAT_EXTERNAL_NETWORKS}    ${VNI_NAT_EXTERNAL_SUBNET}    ${VNI_NAT_EXTERNAL_SUBNET_CIDRS}
    OpenStackOperations.Add Router Gateway    ${VNI_NAT_ROUTER}    ${VNI_NAT_EXTERNAL_NETWORKS}
    ${net_id} =    OpenStackOperations.Get Net Id    ${VNI_NAT_EXTERNAL_NETWORKS}
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VNI_NAT_VPN_INSTANCE_IDS}    name=${VNI_NAT_EXTERNAL_BGPVPN}    rd=${VNI_NAT_RDS}    exportrt=${VNI_NAT_RDS}    importrt=${VNI_NAT_RDS}    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VNI_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${VNI_NAT_VPN_INSTANCE_IDS}
    VpnOperations.Associate L3VPN To Network    networkid=${net_id}    vpnid=${VNI_NAT_VPN_INSTANCE_IDS}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VNI_NAT_VPN_INSTANCE_IDS}
    BuiltIn.Should Contain    ${resp}    ${net_id}
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${VNI_NAT_EXTERNAL_NETWORKS}    @{VNI_NAT_VMS}
    BuiltIn.Set Suite Variable    ${VM_FLOATING_IPS}
