*** Settings ***
Documentation     Test suite to validate subnet routing and multicast functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/VpnOperations.robot

*** Variables ***
${AS_ID}          100
${SECURITY_GROUP}    mc_sg
${NUM_OF_PORTS_PER_NETWORK}    4
${NUM_OF_INSTANCES}    20
${RUN_CONFIG}     show running-config
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_NAME}       mc_vpn1
${LOOPBACK_IP}    5.5.5.2
${L3VPN_RD}       2200:2
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[0] @{EXTRA_NW_SUBNET}[0]
${RPING_MIP_IP1}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[1] @{EXTRA_NW_SUBNET}[1]
${RPING_MIP_IP2}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[2] @{EXTRA_NW_SUBNET}[2]
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{INTERFACE_STATE}    up    down
@{REQ_NETWORKS}    mc_net_1    mc_net_2    mc_net_3
@{NET_1_VMS}      mc_net_1_vm_1    mc_net_1_vm_2    mc_net_1_vm_3    mc_net_1_vm_4
@{NET_2_VMS}      mc_net_2_vm_1    mc_net_2_vm_2    mc_net_2_vm_3    mc_net_2_vm_4
@{NET_3_VMS}      mc_net_3_vm_1    mc_net_3_vm_2    mc_net_3_vm_3    mc_net_3_vm_4
@{NET_1_PORTS}    mc_net_1_port_1    mc_net_1_port_2    mc_net_1_port_3    mc_net_1_port_4
@{NET_2_PORTS}    mc_net_2_port_1    mc_net_2_port_2    mc_net_2_port_3    mc_net_2_port_4
@{NET_3_PORTS}    mc_net_3_port_1    mc_net_3_port_2    mc_net_3_port_3    mc_net_3_port_4
@{REQ_SUBNETS}    mc_sub_1    mc_sub_2    mc_sub_3
@{REQ_SUBNET_CIDR}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24
@{EXTRA_NW_SUBNET}    10.1.0.100    10.2.0.100    10.3.0.100
@{MASK}           32    255.255.255.0
@{REQ_VM_INSTANCES_NET1}    mc_net_1_vm_1    mc_net_1_vm_2    mc_net_1_vm_3    mc_net_1_vm_4
@{REQ_VM_INSTANCES_NET2}    mc_net_2_vm_1    mc_net_2_vm_2    mc_net_2_vm_3    mc_net_2_vm_4
@{REQ_VM_INSTANCES_NET3}    mc_net_3_vm_1    mc_net_3_vm_2    mc_net_3_vm_3    mc_net_3_vm_4

*** Test Cases ***
Verify the subnet route when neutron port hosting subnet route is down/up on single VSwitch topology
    [Documentation]    Verify the subnet route when neutron port hosting subnet route is down/up
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[1]
    ${allowed_ip_list} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify Enterprise Hosts Reachability After VM Reboot
    [Documentation]    After VM reboot verifying the enterprise hosts reachability
    OpenStackOperations.Get ControlNode Connection
    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    OpenStackOperations.Reboot Nova VM    @{NET_1_VMS}[0]
    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for multiple subnets on multi VSwitch topology when DC-GW is restarted
    [Documentation]    Verify The Subnet Route For One Subnet When DC-GW Is Restarted
    BgpOperations.Restart BGP Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create BGP Config On DCGW
    Verify Ping between Inter Intra And Enterprise host

Verify the subnet route for multiple subnets on multi VSwitch topology when QBGP is restarted
    [Documentation]    Verify Enterprise Hosts Reachability After Qbgp Restart
    BgpOperations.Restart BGP Processes On ODL    ${ODL_SYSTEM_IP}
    Verify Ping between Inter Intra And Enterprise host

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup

Stop Suite
    [Documentation]    Test Teardown for Subnet_Routing_and_Multicast_Deployments.
    BgpOperations.Delete BGP Configuration On ODL    session
    BgpOperations.Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    OpenStackOperations.OpenStack Suite Teardown

Create Neutron Networks
    [Documentation]    Create required number of networks
    : FOR    ${net}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${net}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${REQ_NETWORKS}

Create Neutron Subnets
    [Arguments]    ${num_of_network}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${num_of_network}
    \    OpenStackOperations.Create SubNet    @{REQ_NETWORKS}[${index}]    @{REQ_SUBNETS}[${index}]    @{REQ_SUBNET_CIDR}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${REQ_SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    ${allowed_address_pairs_args1} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1]
    ${allowed_address_pairs_args2} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[2]
    ${allowed_address_pairs_args3} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[2] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0]
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_NETWORK}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{NET_1_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args1}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_NETWORK}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{NET_2_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args2}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_NETWORK}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[2]    @{NET_3_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args3}

Create Nova VMs
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    2
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_1_PORTS}[${index}]    @{NET_1_VMS}[${index}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_1_PORTS}[${index+2}]    @{NET_1_VMS}[${index+2}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_2_PORTS}[${index}]    @{NET_2_VMS}[${index}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_2_PORTS}[${index+2}]    @{NET_2_VMS}[${index+2}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_3_PORTS}[${index}]    @{NET_3_VMS}[${index}]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{NET_3_PORTS}[${index+2}]    @{NET_3_VMS}[${index+2}]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    @{VM_IP_NET2}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET2}
    @{VM_IP_NET3}    ${NET3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET3}
    BuiltIn.Set Suite Variable    @{VM_IP_NET1}
    BuiltIn.Set Suite Variable    @{VM_IP_NET2}
    BuiltIn.Set Suite Variable    @{VM_IP_NET3}
    BuiltIn.Should Not Contain    ${VM_IP_NET1}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET2}    None
    BuiltIn.Should Not Contain    ${VM_IP_NET3}    None

Create Setup
    [Documentation]    Create basic topology
    OpenStackOperations.OpenStack Suite Setup
    ${id} =    OpenStackOperations.Get Project Id    ${ODL_RESTCONF_USER}
    OpenStackOperations.Set Instance Quota For Project    ${NUM_OF_INSTANCES}    ${id}
    Create Neutron Networks
    Create Neutron Subnets    ${3}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs
    Create Sub Interfaces And Verify
    Create L3VPN
    : FOR    ${network}    IN    @{REQ_NETWORKS}
    \    ${network_id} =    OpenStackOperations.Get Net Id    ${network}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=${VPN_INSTANCE_ID}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${RPING_MIP_IP1}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ${RPING_MIP_IP2}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply

Create Sub Interfaces And Verify
    [Documentation]    Create Sub Interface and verify for all VMs
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    @{REQ_NETWORKS}[0]    @{EXTRA_NW_SUBNET}[0]    @{VM_IP_NET1}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[1]    @{EXTRA_NW_SUBNET}[1]    @{VM_IP_NET2}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    @{REQ_NETWORKS}[1]    @{EXTRA_NW_SUBNET}[1]    @{VM_IP_NET2}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    @{REQ_NETWORKS}[2]    @{EXTRA_NW_SUBNET}[2]    @{VM_IP_NET3}[0]
    ...    @{MASK}[1]    @{INTERFACE_STATE}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    @{REQ_NETWORKS}[2]    @{EXTRA_NW_SUBNET}[2]    @{VM_IP_NET3}[0]

Create L3VPN
    [Documentation]    Create L3VPN and verify the same
    ${net_id} =    OpenStackOperations.Get Net Id    @{REQ_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=["${L3VPN_RD}"]    exportrt=["${L3VPN_RD}"]    importrt=["${L3VPN_RD}"]    tenantid=${tenant_id}
    VpnOperations.Verify L3VPN On ODL    ${VPN_INSTANCE_ID}
    BuiltIn.Should Match Regexp    ${resp}    .*export-RT.*\\n.*["${L3VPN_RD}"].*
    BuiltIn.Should Match Regexp    ${resp}    .*import-RT.*\\n.*["${L3VPN_RD}"].*
    BuiltIn.Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*["${L3VPN_RD}"].*

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME}    ${L3VPN_RD}
    ...    ${LOOPBACK_IP}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    ${RUN_CONFIG}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}

Configure_IP_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${mask}    ${sub_interface_state}=${EMPTY}    ${interface}=eth0
    ...    ${sub_interface_number}=1
    [Documentation]    Keyword for configuring specified IP on specified interface and the corresponding specified sub interface
    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number} ${ip} netmask ${mask} ${sub_interface_state}

Verify_IP_Configured_On_Sub_Interface
    [Arguments]    ${network_name}    ${ip}    ${vm_ip}    ${interface}=eth0    ${sub_interface_number}=1
    [Documentation]    Keyword for verifying specified IP on specified interface and the corresponding specified sub interface
    ${resp} =    OpenStackOperations.Execute Command on VM Instance    ${network_name}    ${vm_ip}    sudo ifconfig ${interface}:${sub_interface_number}
    BuiltIn.Should Contain    ${resp}    ${ip}

Verify Ping between Inter Intra And Enterprise host
    [Documentation]    Ping Enterprise Host for Intra, Inter from different and same network
    ${dst_ip_list} =    BuiltIn.Create List    @{VM_IP_NET1}    @{VM_IP_NET2}    @{EXTRA_NW_SUBNET}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[2]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[2]    ${dst_ip_list}
