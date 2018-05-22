*** Settings ***
Documentation     Test suite to validate subnet routing and multicast functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${AS_ID}          100
${SECURITY_GROUP}    sg-multicastservice
${NUM_OF_PORTS_PER_NETWORK}    4
@{INTERFACE_STATE}    up    down
@{REQ_NETWORKS}    multicast_net1    multicast_net2    multicast_net3
@{NET_1_VMS}      multicast_net1_vm1_1    multicast_net1_vm2_1    multicast_net1_vm3_2    multicast_net1_vm4_2
@{NET_2_VMS}      multicast_net2_vm1_1    multicast_net2_vm2_1    multicast_net2_vm3_2    multicast_net2_vm4_2
@{NET_3_VMS}      multicast_net3_vm1_1    multicast_net3_vm2_1    multicast_net3_vm3_2    multicast_net3_vm4_2
@{NET_1_PORTS}    multicast_net1_port1_1    multicast_net1_port2_1    multicast_net1_port3_2    multicast_net1_port4_2
@{NET_2_PORTS}    multicast_net2_port1_1    multicast_net2_port2_1    multicast_net2_port3_2    multicast_net2_port4_2
@{NET_3_PORTS}    multicast_net3_port1_1    multicast_net3_port2_1    multicast_net3_port3_2    multicast_net3_port4_2
@{REQ_SUBNETS}    multicast_subnet1    multicast_subnet2    multicast_subnet3
@{REQ_SUBNET_CIDR}    10.1.0.0/24    10.2.0.0/24    10.3.0.0/24
@{VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
@{VPN_NAME}       multicast_vpn1
@{DCGW_RD}        ["2200:2"]
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
@{EXTRA_NW_SUBNET}    10.1.0.100    10.2.0.100    10.3.0.100
@{MASK}           32    255.255.255.0
${RPING_MIP_IP}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[0] @{EXTRA_NW_SUBNET}[0]
${RPING_MIP_IP1}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[1] @{EXTRA_NW_SUBNET}[1]
${RPING_MIP_IP2}    sudo arping -I eth0:1 -c 5 -b -s @{EXTRA_NW_SUBNET}[2] @{EXTRA_NW_SUBNET}[2]
${BGP_CONFIG_SERVER_CMD}    bgp-connect -h ${ODL_SYSTEM_IP} -p 7644 add
@{REQ_VM_INSTANCES_NET1}    multicast_net1_vm1_1    multicast_net1_vm2_1    multicast_net1_vm3_2    multicast_net1_vm4_2
@{REQ_VM_INSTANCES_NET2}    multicast_net2_vm1_1    multicast_net2_vm2_1    multicast_net2_vm3_2    multicast_net2_vm4_2
@{REQ_VM_INSTANCES_NET3}    multicast_net3_vm1_1    multicast_net3_vm2_1    multicast_net3_vm3_2    multicast_net3_vm4_2
${LOOPBACK_IP}    5.5.5.2
${DCGW_RD}        2200:2

*** Test Cases ***
Verify the subnet route when neutron port hosting subnet route is down/up on single VSwitch topology
    [Documentation]    Verify the subnet route when neutron port hosting subnet route is down/up
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[1]
    ${allowed_ip_list} =    BuiltIn.Create List    @{EXTRA_NW_SUBNET}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${allowed_ip_list}
    Verify Ping between Inter Intra And Enterprise host

Verify Enterprise Hosts Reachability After VM Reboot
    [Documentation]    After VM reboot verifying the enterprise hosts reachability
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    : FOR    ${VM}    IN    @{NET_1_VMS}[0]
    \    OpenStackOperations.Reboot Nova VM    ${VM}
    ${nslist} =    Utils.Write Commands Until Expected Prompt    ip netns list    ${DEFAULT_LINUX_PROMPT_STRICT}
    @{VM_IP_NET1}    ${NET1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{REQ_VM_INSTANCES_NET1}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}
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

Create Neutron Networks
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{REQ_NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${REQ_NETWORKS}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    ${REQ_NETWORKS[${index}]}    ${REQ_SUBNETS[${index}]}    ${REQ_SUBNET_CIDR[${index}]}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${REQ_SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    ${allowed_address_pairs_args1} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1]
    ${allowed_address_pairs_args2} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[1] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[2]
    ${allowed_address_pairs_args3} =    BuiltIn.Set Variable    --allowed-address ip-address=@{EXTRA_NW_SUBNET}[2] --allowed-address ip-address=@{EXTRA_NW_SUBNET}[0]
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_NETWORK}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[0]    @{NET_1_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args1}
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_network}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[1]    @{NET_2_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args2}
    : FOR    ${index}    IN RANGE    0    ${num_of_ports_per_network}
    \    OpenStackOperations.Create Port    @{REQ_NETWORKS}[2]    @{NET_3_PORTS}[${index}]    sg=${SECURITY_GROUP}    additional_args=${allowed_address_pairs_args3}

Create Nova VMs
    [Arguments]    ${NUM_OF_VMS_PER_DPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
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
    OpenStackOperations.Create Nano Flavor
    OpenStackOperations.Set Instance Quota    30
    Create Neutron Networks    ${3}
    Create Neutron Subnets    ${3}
    OpenStackOperations.Create And Configure Security Group    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs    ${6}
    Create Sub Interfaces And Verify
    Create L3VPN    ${1}
    VpnOperations.Associate Multiple Networks To L3VPN    @{VPN_INSTANCE_ID}[0]    ${REQ_NETWORKS}
    Create BGP Config On ODL
    Create BGP Config On DCGW
    OpenStackOperations.Get ControlNode Connection
    BuiltIn.Wait Until Keyword Succeeds    60s    10s    VpnOperations.Verify Tunnel Status as UP
    Create External Tunnel Endpoint
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[0]    ${RPING_MIP_IP}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${RPING_MIP_IP1}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{REQ_NETWORKS}[2]    @{VM_IP_NET3}[0]    ${RPING_MIP_IP2}
    BuiltIn.Should Contain    ${output}    broadcast    Received 0 reply

Create Sub Interfaces And Verify
    [Documentation]    Create Sub Interface and verify for all VMs
    : FOR    ${vm_ip}    IN    ${VM_IP_NET1[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[0]}    ${EXTRA_NW_SUBNET[0]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET2[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${EXTRA_NW_SUBNET[1]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[1]}    ${EXTRA_NW_SUBNET[1]}
    \    ...    ${vm_ip}
    : FOR    ${vm_ip}    IN    ${VM_IP_NET3[0]}
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Configure_IP_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${EXTRA_NW_SUBNET[2]}
    \    ...    ${vm_ip}    ${MASK[1]}    @{INTERFACE_STATE}[0]
    \    BuiltIn.Wait Until Keyword Succeeds    30s    5s    Verify_IP_Configured_On_Sub_Interface    ${REQ_NETWORKS[2]}    ${EXTRA_NW_SUBNET[2]}
    \    ...    ${vm_ip}

Create L3VPN
    [Arguments]    ${NUM_OF_L3VPN}    ${additional_args}=${EMPTY}    ${verbose}=TRUE
    [Documentation]    Create L3VPN and verify the same
    ${net_id} =    OpenStackOperations.Get Net Id    @{REQ_NETWORKS}[0]
    ${tenant_id} =    OpenStackOperations.Get Tenant ID From Network    ${net_id}
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID[0]}    name=${VPN_NAME[0]}    rd=${DCGW_RD[0]}    exportrt=${DCGW_RD[0]}    importrt=${DCGW_RD[0]}    tenantid=${tenant_id}
    ${resp} =    VpnOperations.VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Contain    ${resp}    ${VPN_INSTANCE_ID[0]}
    BuiltIn.Should Match Regexp    ${resp}    .*export-RT.*\\n.*${DCGW_RD[0]}.*
    BuiltIn.Should Match Regexp    ${resp}    .*import-RT.*\\n.*${DCGW_RD[0]}.*
    BuiltIn.Should Match Regexp    ${resp}    .*route-distinguisher.*\\n.*${DCGW_RD[0]}.*

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAME[0]}    ${DCGW_RD}
    ...    ${LOOPBACK_IP}
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IP}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    show running-config
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

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
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET2}[0]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[0]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[0]    @{VM_IP_NET1}[2]    ${dst_ip_list}
    OpenStackOperations.Test Operations From Vm Instance    @{REQ_NETWORKS}[1]    @{VM_IP_NET2}[2]    ${dst_ip_list}
