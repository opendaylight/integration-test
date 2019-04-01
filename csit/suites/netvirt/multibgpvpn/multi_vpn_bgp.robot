*** Settings ***
Documentation     Test suite to validate multiple vpnservice functionality in an openstack integrated environment.
...               The assumption of this suite is that the environment is already configured with the proper
...               integration bridges and vxlan tunnels.
Suite Setup       Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${NUM_OF_PORTS_PER_HOST}    3
${NUM_OF_VMS_PER_HOST}    3
${NUM_OF_L3VPN}    3
${AS_ID}          100
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${NET}            mvpn_net_new
${ROUTER}         mvpn_router
${LOOPBACK_IP}    5.5.5.2/32
${CREATE_RT}      ["2200:2","2300:2","2400:2"]
${RT_LIST_1}      ["2200:2","2300:2"]
${RT_LIST_2}      ["2200:2","2400:2"]
@{SECURITY_GROUP}    mvpn_sg    mvpn_custom_sg
@{REQ_PREFIXLENGTHS}    40.1.0.0/28    41.1.0.0/16
@{REQ_SUBNETS_PREFIX}    mvpn_subnet10    mvpn_subnet11
@{NETWORKS}       mvpn_net_1    mvpn_net_2    mvpn_net_3
@{SUBNETS}        mvpn_sub_1    mvpn_sub_2    mvpn_sub_3
@{SUBNET_CIDRS}    11.1.1.0/24    22.1.1.0/24    33.1.1.0/24
@{PORTS_HOST1}    mvpn_net_1_port_1    mvpn_net_2_port_1    mvpn_net_3_port_1    mvpn_net_1_port1_csg    mvpn_net_2_port1_csg
@{PORTS_HOST2}    mvpn_net_1_port_2    mvpn_net_2_port_2    mvpn_net_3_port_2    mvpn_net_2_port2_csg
@{VMS_HOST1}      mvpn_net_1_vm_1    mvpn_net_2_vm_1    mvpn_net_3_vm_1    mvpn_net_1_vm1_csg    mvpn_net_2_vm1_csg
@{VMS_HOST2}      mvpn_net_1_vm_2    mvpn_net_2_vm_2    mvpn_net_3_vm_2    mvpn_net_2_vm2_csg
@{NET_1_VMS}      mvpn_net_1_vm_1    mvpn_net_1_vm_2    mvpn_net_1_vm1_csg
@{NET_2_VMS}      mvpn_net_2_vm_1    mvpn_net_2_vm_2    mvpn_net_2_vm1_csg    mvpn_net_2_vm2_csg
@{NET_3_VMS}      mvpn_net_3_vm_1    mvpn_net_3_vm_2
@{VPN_INSTANCE_IDS}    4ae8cd92-48ca-49b5-94e1-b2921a261441    4ae8cd92-48ca-49b5-94e1-b2921a261442    4ae8cd92-48ca-49b5-94e1-b2921a261443
@{VPN_NAMES}      mvpn_1    mvpn_2    mvpn_3
@{RDS}            ["2200:2"]    ["2300:2"]    ["2400:2"]
@{DCGW_RD}        2200:2    2300:2    2400:2
@{LOOPBACK_IPS}    5.5.5.2    2.2.2.2    3.3.3.3
@{LOOPBACK_NAMES}    int1    int2    int3

*** Test Cases ***
Check Datapath Traffic Across Networks With L3VPN
    [Documentation]    Datapath Test Across the networks with VPN.
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 20 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 20 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 20 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[2]    ping -c 20 @{NET_2_VM_IPS}[2]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[2]    ping -c 20 @{NET_2_VM_IPS}[3]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}

Verify Route Update In Bgp For Routes With Default Route And Various Prefix Lengths
    [Documentation]    Create network with different prefix lengths and check the route update in bgp.
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${SUBNET_CIDRS}
    OpenStackOperations.Create Network    ${NET}
    ${length} =    BuiltIn.Get Length    ${REQ_SUBNETS_PREFIX}
    : FOR    ${idx}    IN RANGE    ${length}
    \    OpenStackOperations.Create SubNet    ${NET}    @{REQ_SUBNETS_PREFIX}[${idx}]    @{REQ_PREFIXLENGTHS}[${idx}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${REQ_SUBNETS_PREFIX}
    ${net_id} =    OpenStackOperations.Get Net Id    ${NET}
    VpnOperations.Associate L3VPN To Network    networkid=${net_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_INSTANCE_IDS}[0]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${REQ_PREFIXLENGTHS}
    [Teardown]    BuiltIn.Run Keywords    VpnOperations.Dissociate L3VPN From Networks    networkid=${net_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    ...    AND    OpenStackOperations.Delete Network    ${NET}
    ...    AND    Post Test Cleanup    @{VPN_INSTANCE_IDS}[0]

Verification Of Route Download With Three Vpns In SE And Qbgp With One-One Export Import Route Target
    [Documentation]    Check the datapath traffic with one-one export import route target with three vpns.
    Create Multiple L3VPN    @{NETWORKS}[0]    ${3}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    VpnOperations.Associate L3VPNs To Networks    ${VPN_INSTANCE_IDS}    ${NETWORKS}
    ${fib_values} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{NET_3_VM_IPS}    @{SUBNET_CIDRS}    @{LOOPBACK_IPS}
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    ${fib1_values} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{SUBNET_CIDRS}[0]    @{LOOPBACK_IPS}[0]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BgpOperations.Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    @{DCGW_RD}[0]    ${fib1_values}
    ${fib2_values} =    BuiltIn.Create List    @{NET_2_VM_IPS}    @{SUBNET_CIDRS}[1]    @{LOOPBACK_IPS}[1]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BgpOperations.Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    @{DCGW_RD}[1]    ${fib2_values}
    ${fib3_values} =    BuiltIn.Create List    @{NET_3_VM_IPS}    @{SUBNET_CIDRS}[2]    @{LOOPBACK_IPS}[2]
    BuiltIn.Wait Until Keyword Succeeds    60s    15s    BgpOperations.Verify Routes On Quagga    ${DCGW_SYSTEM_IP}    @{DCGW_RD}[2]    ${fib3_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_1_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[0]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    ${output} =    OpenStackOperations.Execute Command on VM Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ping -c 3 @{NET_2_VM_IPS}[1]
    BuiltIn.Should Contain    ${output}    ${NO_PING_REGEXP}
    [Teardown]    Post Test Cleanup    @{VPN_INSTANCE_IDS}

Verification Of Route Download With Three Vpns In SE And Qbgp With One-Many Export Import Route Target
    [Documentation]    Check the datapath traffic with one-many export import route target with three vpns.
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=${CREATE_RT}    importrt=@{RDS}[0]
    : FOR    ${index}    IN RANGE    1    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=@{RDS}[${index}]    importrt=${RT_LIST_${index}}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${networks} =    BuiltIn.Create List    @{NETWORKS}[0]    @{NETWORKS}[1]
    VpnOperations.Associate L3VPNs To Networks    ${VPN_INSTANCE_IDS}    ${networks}
    ${fib_values} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{SUBNET_CIDRS}[0]    @{SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    [Teardown]    Post Test Cleanup    @{VPN_INSTANCE_IDS}

Verification Of Route Download With Three Vpns In SE And Qbgp With Many-One Export Import Route Target
    [Documentation]    Check the datapath traffic with many-one export import route target with three vpns.
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=${CREATE_RT}
    : FOR    ${index}    IN RANGE    1    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=${RT_LIST_${index}}    importrt=@{RDS}[${index}]
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${networks} =    BuiltIn.Create List    @{NETWORKS}[0]    @{NETWORKS}[1]
    VpnOperations.Associate L3VPNs To Networks    ${VPN_INSTANCE_IDS}    ${networks}
    ${fib_values} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{SUBNET_CIDRS}[0]    @{SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}
    [Teardown]    Post Test Cleanup    @{VPN_INSTANCE_IDS}

Verification Of Route Download With Three Vpns In SE And Qbgp With Many-Many Export Import Route Target
    [Documentation]    Check the datapath traffic with many-many export import route target with three vpns.
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]    rd=@{RDS}[${index}]    exportrt=${CREATE_RT}    importrt=${CREATE_RT}
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_L3VPN}
    \    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[${index}]
    \    ...    @{DCGW_RD}[${index}]    @{LOOPBACK_IPS}[${index}]
    ${networks} =    BuiltIn.Create List    @{NETWORKS}[0]    @{NETWORKS}[1]
    VpnOperations.Associate L3VPNs To Networks    ${VPN_INSTANCE_IDS}    ${networks}
    ${fib_values} =    BuiltIn.Create List    @{NET_1_VM_IPS}    @{NET_2_VM_IPS}    @{SUBNET_CIDRS}[0]    @{SUBNET_CIDRS}[1]
    BuiltIn.Wait Until Keyword Succeeds    30s    10s    Utils.Check For Elements At URI    ${FIB_ENTRY_URL}    ${fib_values}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_1_VM_IPS}
    VpnOperations.Verify Flows Are Present For L3VPN    ${OS_CMP1_IP}    ${NET_2_VM_IPS}

*** Keywords ***
Suite Setup
    [Documentation]    Basic setup.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}    @{NET_3_VMS}

Create Setup
    [Documentation]    Create basic topology
    Create Neutron Networks
    Create Neutron Subnets
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP[0]}
    Security Group Rule with Remote SG    ${SECURITY_GROUP[1]}
    Create Neutron Ports
    Create Nova VMs
    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[0]    name=@{VPN_NAMES}[0]    rd=@{RDS}[0]    exportrt=@{RDS}[0]    importrt=@{RDS}[0]
    VpnOperations.Verify L3VPN On ODL    @{VPN_INSTANCE_IDS}[0]
    : FOR    ${network}    IN    @{NETWORKS}
    \    ${network_id} =    OpenStackOperations.Get Net Id    ${network}
    \    VpnOperations.Associate L3VPN To Network    networkid=${network_id}    vpnid=@{VPN_INSTANCE_IDS}[0]
    Create BGP Config On ODL
    Create BGP Config On DCGW
    Create External Tunnel Endpoint

Create Neutron Networks
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron Subnets
    [Documentation]    Create required number of subnets for previously created networks
    ${num_of_networks} =    BuiltIn.Get Length    ${NETWORKS}
    : FOR    ${index}    IN RANGE    0    ${num_of_networks}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNET_CIDRS}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    OpenStackOperations.Create Port    @{NETWORKS}[${index}]    @{PORTS_HOST1}[${index}]    sg=@{SECURITY_GROUP}[0]
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_PORTS_PER_HOST}
    \    OpenStackOperations.Create Port    @{NETWORKS}[${index}]    @{PORTS_HOST2}[${index}]    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS_HOST1}[3]    @{SECURITY_GROUP}[1]
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS_HOST1}[4]    @{SECURITY_GROUP}[1]
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS_HOST2}[3]    @{SECURITY_GROUP}[1]
    ${PORTS} =    BuiltIn.Create List    @{PORTS_HOST1}    @{PORTS_HOST2}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}

Create Nova VMs
    [Documentation]    Create Vm instances on compute nodes
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_HOST}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST1}[${index}]    @{VMS_HOST1}[${index}]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[0]
    : FOR    ${index}    IN RANGE    0    ${NUM_OF_VMS_PER_HOST}
    \    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST2}[${index}]    @{VMS_HOST2}[${index}]    ${OS_CMP2_HOSTNAME}    sg=@{SECURITY_GROUP}[0]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST1}[3]    @{VMS_HOST1}[3]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[1]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST1}[4]    @{VMS_HOST1}[4]    ${OS_CMP1_HOSTNAME}    sg=@{SECURITY_GROUP}[1]
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS_HOST2}[3]    @{VMS_HOST2}[3]    ${OS_CMP2_HOSTNAME}    sg=@{SECURITY_GROUP}[1]
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_VM_IPS}    ${NET_3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_DHCP_IP}    None

Create External Tunnel Endpoint
    [Documentation]    Create and verify external tunnel endpoint between ODL and GWIP
    BgpOperations.Create External Tunnel Endpoint Configuration    destIp=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get External Tunnel Endpoint Configuration    ${DCGW_SYSTEM_IP}
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On ODL
    [Documentation]    Configure BGP Config on ODL
    KarafKeywords.Issue Command On Karaf Console    ${BGP_CONFIG_SERVER_CMD}
    BgpOperations.Create BGP Configuration On ODL    localas=${AS_ID}    routerid=${ODL_SYSTEM_IP}
    BgpOperations.AddNeighbor To BGP Configuration On ODL    remoteas=${AS_ID}    neighborAddr=${DCGW_SYSTEM_IP}
    ${output} =    BgpOperations.Get BGP Configuration On ODL    session
    BuiltIn.Should Contain    ${output}    ${DCGW_SYSTEM_IP}

Create BGP Config On DCGW
    [Documentation]    Configure BGP on DCGW
    BgpOperations.Configure BGP And Add Neighbor On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}    @{VPN_NAMES}[0]    @{DCGW_RD}[0]
    ...    @{LOOPBACK_IPS}[0]
    ${output} =    BgpOperations.Execute Show Command On Quagga    ${DCGW_SYSTEM_IP}    ${RUN_CONFIG}
    BuiltIn.Should Contain    ${output}    ${ODL_SYSTEM_IP}
    ${output} =    BuiltIn.Wait Until Keyword Succeeds    180s    10s    BgpOperations.Verify BGP Neighbor Status On Quagga    ${DCGW_SYSTEM_IP}    ${ODL_SYSTEM_IP}

Create Multiple L3VPN
    [Arguments]    ${network}    ${num_of_l3vpns}
    [Documentation]    Creates multiple L3VPNs and then verify the same
    : FOR    ${index}    IN RANGE    0    ${num_of_l3vpns}
    \    BuiltIn.Wait Until Keyword Succeeds    40s    10s    VpnOperations.VPN Create L3VPN    vpnid=@{VPN_INSTANCE_IDS}[${index}]    name=@{VPN_NAMES}[${index}]
    \    ...    rd=@{RDS}[${index}]    exportrt=@{RDS}[${index}]    importrt=@{RDS}[${index}]
    \    VpnOperations.Verify L3VPN On ODL    @{VPN_INSTANCE_IDS}[${index}]

Security Group Rule with Remote SG
    [Arguments]    ${sec_grp}
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Neutron Security Group Create    ${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-group-id=${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=egress    port_range_max=65535    port_range_min=1    protocol=tcp    remote-group-id=${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=ingress    protocol=icmp    remote-group-id=${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=egress    protocol=icmp    remote-group-id=${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=ingress    port_range_max=65535    port_range_min=1    protocol=udp    remote_group_id=${sec_grp}
    OpenStackOperations.Neutron Security Group Rule Create    ${sec_grp}    direction=egress    port_range_max=65535    port_range_min=1    protocol=udp    remote-group-id=${sec_grp}

Post Test Cleanup
    [Arguments]    @{vpn_ids}
    [Documentation]    Test Case Cleanup.
    VpnOperations.Delete Multiple L3VPNs    @{vpn_ids}
    BgpOperations.Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
