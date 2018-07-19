*** Settings ***
Documentation     Test suite to validate network address translation(snat/dnat) functionality in openstack integrated environment.
...               All the testcases were written to do flow validation since dc gateway is unavailable in csit environment.
...               This suite assumes proper integration bridges and vxlan tunnels are configured in the environment.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           RequestsLibrary
Library           SSHLibrary
Library           Collections
Library           String
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    nat_sg
${RUN_CONFIG}     show running-config
${NETWORK_TYPE}    nat_gre
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${LOOPBACK_IP}    5.5.5.2
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261441
${DCGW_RD}        1:1
${TELNET_REGEX}    No route to host
${SNAT_ENABLED}         "enable_snat": true
${SNAT_DISABLED}        "enable_snat": false
${ROUTER}         nat_router
@{NETWORKS}       nat_net_1    nat_net_2
@{EXTERNAL_NETWORKS}    nat_ext_11    nat_ext_22
@{EXTERNAL_SUB_NETWORKS}    nat_ext_sub_net_1    nat_ext_sub_net_2
@{SUBNETS}        nat_sub_net_1    nat_sub_net_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
@{BOOL_VALUES}    true    false
@{PORTS}          nat_port_1    nat_port_2    nat_port_3    nat_port_4
@{NET_1_VMS}      nat_net_1_vm_1    nat_net_1_vm_2    nat_net_1_vm_3    nat_net_1_vm_4

*** Test Cases ***
Verify successful creation of external network with router external set to TRUE
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}
    ${output} =    OpenStackOperations.Show Network    @{EXTERNAL_NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    @{EXTERNAL_NETWORKS}[0]

Verify successful update of router with external_gateway_info, disable SNAT and enable SNAT
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --disable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_DISABLED}
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}

Verify successful deletion of external network
    OpenStackOperations.Remove Gateway    ${ROUTER}
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Not Contain    ${output}    ${SNAT_ENABLED}

Verify update router with single external IP while router is hosting single subnet
    [Documentation]    Integrated verify successful creation of external network with router external set to true testcase
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=${DCGW_RD}    exportrt=${DCGW_RD}    importrt=${DCGW_RD}
    ${ext_net_id} =    OpenStackOperations.Get Net Id    @{EXTERNAL_NETWORKS}[0]
    VpnOperations.Associate L3VPN To Network    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID}
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}
    ${ext_ip} =    Get External Ip From Router    ${ROUTER}
    ${output} =    Verify Telnet Status    @{NETWORKS}[0]    ${vm1_ip}    ${LOOPBACK_IP}    ${TELNET_REGEX}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${TABLE_NO_46}    True    ${EMPTY}    actions=set_field:${ext_ip}
    OVSDB.Verify Dump Flows For Specific Table    ${OS_COMPUTE_1_IP}    ${TABLE_NO_44}    True    ${EMPTY}    nw_dst=${ext_ip}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup

Create Setup
    Create Neutron Networks
    Create Neutron Subnets
    OpenStackOperations.Create SubNet    @{EXTERNAL_NETWORKS}[0]    @{EXTERNAL_SUB_NETWORKS}[0]    @{EXT_SUBNET_CIDRS}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs
    Create BGP Config On ODL
    Create BGP Config On DCGW
    OpenStackOperations.Create Router    @{ROUTER}[0]
    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    @{SUBNETS}[0]

Create Neutron Networks
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    OpenStackOperations.Create Network    @{EXTERNAL_NETWORKS}[0]    --external --provider-network-type ${NETWORK_TYPE}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron Subnets
    [Arguments]    ${NUM_OF_NETWORK}
    [Documentation]    Create required number of subnets for previously created networks
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_NETWORK}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNET_CIDRS}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}
    ${PORTS} =    BuiltIn.Create List    @{PORTS_HOST1}    @{PORTS}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}

Create Nova VMs
    [Documentation]    Create Vm instances on compute nodes
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[2]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_1_VMS}[3]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    ${VPN_NAMES[0]}    @{DCGW_RD}[0]
    ...    ${LOOPBACK_IPS}
    BgpOperations.Add Loopback Interface On DCGW    ${DCGW_SYSTEM_IP}    lo    ${LOOPBACK_IPS}
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    ${RUN_CONFIG}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}

Verify Telnet Status
    [Arguments]    ${net}    ${vm_ip1}    ${ip}    ${telnet_regx}
    [Documentation]    Telnet from given vm to destined ip and check the status
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    240s    10s    OpenStackOperations.Execute Command on VM Instance    ${net}    ${vm_ip1}
    ...    telnet ${ip}
    BuiltIn.Should Contain    ${output}    ${telnet_regx}
    [Return]    ${output}

Get External Ip From Router
    [Arguments]    ${router_name}
    [Documentation]    Gets external ip associated to router
    ${ip} =    OpenStackOperations.Show Router    ${router_name}    |grep ip_address| awk '{print $12}'
    ${flt_ip} =    BuiltIn.Should Match Regexp    ${ip}    [0-9]\.+
    @{vm} =    String.Split String    ${flt_ip}    "
    ${float_out} =    BuiltIn.Set Variable    ${vm[0]}
    [Return]    ${float_out}
