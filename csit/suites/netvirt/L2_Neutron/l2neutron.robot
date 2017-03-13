*** Settings ***
Documentation     Test suite to validate L2 Neutron functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS}       NET10    NET20
@{SUBNETS}        SUBNET1    SUBNET2
@{SUBNET_CIDR}    10.1.1.0/24    20.1.1.0/24
@{PORT_LIST}      PORT1    PORT2    PORT3    PORT4
@{ELAN1_PORT_LIST}    PORT1    PORT3
@{ELAN2_PORT_LIST}    PORT2    PORT4
${VM_NAMES}       VM11    VM12    VM21    VM22
@{VM_INSTANCES_DPN1}    VM11    VM21
@{VM_INSTANCES_DPN2}    VM12    VM22
${ROUTER}         ROUTER_1
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261111
${VPN_NAME}       vpn1
${CREATE_RD}      ["2200:2"]
${CREATE_EXPORT_RT}    ["2200:2"]
${CREATE_IMPORT_RT}    ["2200:2"]
${EPH1_CFG}       sudo ifconfig eth0:1 10.1.1.110 netmask 255.255.255.0 up
${EPH2_CFG}       sudo ifconfig eth0:1 20.1.1.110 netmask 255.255.255.0 up
@{BROADCAST_IP}    10.1.1.255    20.1.1.255
${MULTICAST_IP}    224.0.0.1
${SECURITY_GROUP}    sg-l2neutron

*** Test Cases ***
TC01 Broadcast/Unicast testing with L3VPN service
    [Documentation]    Generate broadcast&Unicast traffic from VM1 & Verify
    Log    Verification of FIB Entries and Flow
    ${vm_instances} =    Create List    @{VM_IP_NET10}    @{VM_IP_NET20}
    Wait Until Keyword Succeeds    30s    5s    Check For Elements At URI    ${CONFIG_API}/odl-fib:fibEntries/    ${vm_instances}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For L3VPN    ${OS_COMPUTE_2_IP}    ${VM_IP_NET20}
    ${SRCMAC_CPN1} =    Create List    ${VM_MACAddr_ELAN1[0]}
    ${SRCMAC_CPN2} =    Create List    ${VM_MACAddr_ELAN2[0]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CPN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CPN2}    ${VM_MACAddr_ELAN2}
    ${ELAN_Packets_1}    ${VPN_Packets_1}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${BROADCAST_IP[0]}
    Should Contain    ${output}    64 bytes
    ${ELAN_Packets_2}    ${VPN_Packets_2}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${ELAN_Packets_1} < ${ELAN_Packets_2}
    Should Be True    ${VPN_Packets_1} == ${VPN_Packets_2}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET10[1]}
    Should Contain    ${output}    64 bytes
    ${ELAN_Packets_3}    ${VPN_Packets_3}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${ELAN_Packets_2} < ${ELAN_Packets_3}
    Should Be True    ${VPN_Packets_2} == ${VPN_Packets_3}
    ${output} =    Execute Command on VM Instance    ${NETWORKS}[0]    ${VM_IP_NET10[0]}    ping -c 3 ${VM_IP_NET20[1]}
    Should Contain    ${output}    64 bytes
    ${ELAN_Packets_4}    ${VPN_Packets_4}    Get PacketCount from Flow Table    ${OS_COMPUTE_1_IP}    ${VM_IP_NET10[0]}    ${VM_MACAddr_ELAN2[1]}
    Should Be True    ${VPN_Packets_4} > ${VPN_Packets_3}

*** Keywords ***
Start Suite
    [Documentation]    Run before the suite execution
    DevstackUtils.Devstack Suite Setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    Configure Setup

Stop Suite
    [Documentation]    Run after the tests execution
    Unconfigure Setup
    Delete Ssh Allow Rule    ${SECURITY_GROUP}
    Close All Connections

Configure Setup
    [Documentation]    Create Two Networks, Two Subnets, Four Ports And Four VMs
    Log    Create two networks
    Create Network    ${NETWORKS[0]}
    Create Network    ${NETWORKS[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/networks/    ${NETWORKS}
    Log    Create two subnets for previously created networks
    Create SubNet    ${NETWORKS[0]}    ${SUBNETS[0]}    ${SUBNET_CIDR[0]}
    Create SubNet    ${NETWORKS[1]}    ${SUBNETS[1]}    ${SUBNET_CIDR[1]}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/subnets/    ${SUBNETS}
    Log    Create Service group rule
    Neutron Security Group Create    ${SECURITY_GROUP}
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    protocol=icmp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Neutron Security Group Rule Create    ${SECURITY_GROUP}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote_ip_prefix=0.0.0.0/0
    Log    Create four ports under previously created subnets
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[0]}    sg=${SECURITY_GROUP}
    Create Port    ${NETWORKS[0]}    ${PORT_LIST[1]}    sg=${SECURITY_GROUP}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[2]}    sg=${SECURITY_GROUP}
    Create Port    ${NETWORKS[1]}    ${PORT_LIST[3]}    sg=${SECURITY_GROUP}
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORT_LIST}
    Log    Create VM Instances
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[0]}    ${VM_INSTANCES_DPN1[0]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[2]}    ${VM_INSTANCES_DPN1[1]}    ${OS_COMPUTE_1_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[1]}    ${VM_INSTANCES_DPN2[0]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    Create Vm Instance With Port On Compute Node    ${PORT_LIST[3]}    ${VM_INSTANCES_DPN2[1]}    ${OS_COMPUTE_2_IP}    sg=${SECURITY_GROUP}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    ${VM_INSTANCES_NET10} =    Create List    ${VM_INSTANCES_DPN1[0]}    ${VM_INSTANCES_DPN2[0]}
    ${VM_INSTANCES_NET20} =    Create List    ${VM_INSTANCES_DPN1[1]}    ${VM_INSTANCES_DPN2[1]}
    : FOR    ${VM}    IN    @{VM_INSTANCES}
    \    Wait Until Keyword Succeeds    60s    5s    Verify VM Is ACTIVE    ${VM}
    Log    Check for routes
    ${VM_IP_NET10}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET10}
    Log    ${VM_IP_NET10}
    Set Suite Variable    ${VM_IP_NET10}
    ${VM_IP_NET20}    Wait Until Keyword Succeeds    30s    10s    Verify VMs received IP    ${VM_INSTANCES_NET20}
    Log    ${VM_IP_NET20}
    Set Suite Variable    ${VM_IP_NET20}
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN1_PORT_LIST}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}
    ${VM_MACAddr_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${ELAN2_PORT_LIST}
    Log    ${VM_MACAddr_ELAN2}
    Set Suite Variable    ${VM_MACAddr_ELAN2}
    Log    Create Router
    Create Router    ${ROUTER}
    ${router_list} =    Create List    ${ROUTER}
    Wait Until Keyword Succeeds    30s    1s    Check For Elements At URI    ${CONFIG_API}/neutron:neutron/routers/    ${router_list}
    Log    Add Interfaces to router
    ${devstack_conn_id} =    Get ControlNode Connection
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Add Router Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Contain    ${interface_output}    ${subnet_id}
    Log    Creates a L3VPN and then verify the same
    ${net_id} =    Get Net Id    @{NETWORKS}[0]    ${devstack_conn_id}
    ${tenant_id} =    Get Tenant ID From Network    ${net_id}
    VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${CREATE_RD}    exportrt=${CREATE_EXPORT_RT}    importrt=${CREATE_IMPORT_RT}    tenantid=${tenant_id}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    Should Contain    ${resp}    ${VPN_INSTANCE_ID}
    Log    Associating router to L3VPN
    ${router_id}=    Get Router Id    ${ROUTER}    ${devstack_conn_id}
    Associate VPN to Router    routerid=${router_id}    vpnid=${VPN_INSTANCE_ID}
    ${resp}=    VPN Get L3VPN    vpnid=${VPN_INSTANCE_ID}
    Should Contain    ${resp}    ${router_id}

Unconfigure Setup
    [Documentation]    Delete the created L3VPN, Router, VMs, ports, subnet and networks
    VPN Delete L3VPN    vpnid=${VPN_INSTANCE_ID}
    #Delete Interface
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    Remove Interface    ${ROUTER}    ${INTERFACE}
    ${interface_output} =    Show Router Interface    ${ROUTER}
    : FOR    ${INTERFACE}    IN    @{SUBNETS}
    \    ${subnet_id} =    Get Subnet Id    ${INTERFACE}    ${devstack_conn_id}
    \    Should Not Contain    ${interface_output}    ${subnet_id}
    # Delete Router and Interface to the subnets.
    Delete Router    ${ROUTER}
    ${router_output} =    List Router
    Log    ${router_output}
    Should Not Contain    ${router_output}    ${ROUTER}
    ${VM_INSTANCES} =    Create List    @{VM_INSTANCES_DPN1}    @{VM_INSTANCES_DPN2}
    : FOR    ${VmInstance}    IN    @{VM_INSTANCES}
    \    Delete Vm Instance    ${VmInstance}
    : FOR    ${Port}    IN    @{PORT_LIST}
    \    Delete Port    ${Port}
    : FOR    ${Subnet}    IN    @{SUBNETS}
    \    Delete SubNet    ${Subnet}
    : FOR    ${Network}    IN    @{NETWORKS}
    \    Delete Network    ${Network}

Verify VMs received IP
    [Arguments]    ${VM_NAMES}
    [Documentation]    Verify VM Instance received IP
    ${VM_IPS}    ${DHCP_IP1}    Verify VMs Received DHCP Lease    @{VM_NAMES}
    Log    ${VM_IPS}
    Should Not Contain    ${VM_IPS}    None
    [Return]    ${VM_IPS}

Get PacketCount from Flow Table
    [Arguments]    ${cnIp}    ${dest_ip}    ${dest_mac}
    [Documentation]    Get the packet count from given table using the destination nw_dst=ip or dl_dst=mac
    ${ELAN_REGEX} =    Set Variable    table=${ELAN_DMACTABLE}, n_packets=\\d+,\\s.*,dl_dst=${dest_mac}
    ${L3VPN_REGEX} =    Set Variable    table=${L3_TABLE}, n_packets=\\d+,\\s.*,nw_dst=${dest_ip}
    ${PACKET_COUNT_REGEX} =    Set Variable    n_packets=\\d+
    ${flow_output}=    Run Command On Remote System    ${cnIp}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${ELAN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_ELAN} =    Get from List    ${n_packets}    1
    ${n_packets_ELAN} =    Convert To Integer    ${n_packets_ELAN}
    Log    ${n_packets_ELAN}
    ${flowEntry} =    Get Regexp Matches    ${flowOutput}    ${L3VPN_REGEX}
    Log    ${flowEntry}
    ${match} =    Get Regexp Matches    ${flowEntry[0]}    ${PACKET_COUNT_REGEX}
    Log    ${match}
    ${n_packets} =    Split String    ${match[0]}    separator==
    ${n_packets_L3VPN}=    Get from List    ${n_packets}    1
    ${n_packets_L3VPN} =    Convert To Integer    ${n_packets_L3VPN}
    Log    ${n_packets_L3VPN}
    [Return]    ${n_packets_ELAN}    ${n_packets_L3VPN}

Delete Ssh Allow Rule
    [Arguments]    ${sg_name}
    [Documentation]    Delete Security group
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-delete ${sg_name}    40s
    Log    ${output}
    Should Match Regexp    ${output}    Deleted security_group: ${sg_name}|Deleted security_group\\(s\\): ${sg_name}
    Close Connection

Verify Flows Are Present For ELAN Service
    [Arguments]    ${ip}    ${srcMacAddrs}    ${destMacAddrs}
    [Documentation]    Verify Flows Are Present For ELAN service
    ${flow_output} =    Run Command On Remote System    ${ip}    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${flow_output}
    Should Contain    ${flow_output}    table=${ELAN_SMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_SMACTABLE}
    Log    ${sMac_output}
    : FOR    ${sMacAddr}    IN    @{srcMacAddrs}
    \    ${resp}=    Should Contain    ${sMac_output}    ${sMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_DMACTABLE}
    ${dMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_DMACTABLE}
    Log    ${dMac_output}
    : FOR    ${dMacAddr}    IN    @{destMacAddrs}
    \    ${resp}=    Should Contain    ${dMac_output}    ${dMacAddr}
    Should Contain    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    ${sMac_output} =    Get Lines Containing String    ${flow_output}    table=${ELAN_UNKNOWNMACTABLE}
    Log    ${sMac_output}
