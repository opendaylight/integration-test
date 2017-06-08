*** Settings ***
Documentation     Test suite to validate network address translation(snat/dnat) functionality in openstack integrated environment.
...               All the testcases were written to do flow validation since dc gateway is unavailable in csit environment.
...               This suite assumes proper integration bridges and vxlan tunnels are configured in the environment.
Suite Setup       Suite Setup
Suite Teardown    Stop Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Tcpdump.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/VpnOperations.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    nat_sg
${NETWORK_TYPE}    gre
${SNAT_ENABLED}    "enable_snat": true
${SNAT_DISABLED}    "enable_snat": false
${ROUTER}         nat_router
${AS_ID}          100
${DCGW_SYSTEM_IP}    ${TOOLS_SYSTEM_1_IP}
${LOOPBACK_IP}    5.5.5.2
${DCGW_RD}        100:1
${VPN_NAME}       vpn_1
${VPN_INSTANCE_ID}    4ae8cd92-48ca-49b5-94e1-b2921a261442
${ExtIP}          100.100.100.24
@{NETWORKS}       nat_net_1    nat_net_2
@{EXTERNAL_NETWORKS}    nat_ext_11    nat_ext_22
@{EXTERNAL_SUB_NETWORKS}    nat_ext_sub_net_1    nat_ext_sub_net_2
@{SUBNETS}        nat_sub_net_1    nat_sub_net_2
@{SUBNET_CIDRS}    10.1.1.0/24    20.1.1.0/24
@{EXT_SUBNET_CIDRS}    100.100.100.0/24    200.200.200.0/24
@{PORTS}          nat_port_1    nat_port_2    nat_port_3    nat_port_4
@{NET_1_VMS}      nat_net_1_vm_1    nat_net_1_vm_2    nat_net_1_vm_3    nat_net_1_vm_4

*** Test Cases ***
Verify Successful Creation Of External Network With Router External Set To TRUE
    [Documentation]    Create external network,enable snat on router and validate the same.
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}
    ${output} =    OpenStackOperations.Show Network    @{EXTERNAL_NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    @{EXTERNAL_NETWORKS}[0]

Verify Successful Update Of Router With External_gateway_info, Disable SNAT And Enable SNAT
    [Documentation]    Disable snat, enable snat and validate the same.
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --disable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_DISABLED}
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}

Verify Successful Deletion Of External Network
    [Documentation]    Delete the external network and validate the same.
    OpenStackOperations.Remove Gateway    ${ROUTER}
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Not Contain    ${output}    ${SNAT_ENABLED}

Verify Floating Ip Provision And Reachability From External Network Via Neutron Router Through L3vpn
    [Documentation]    Check floating IP should be present in dump flows after creating the floating IP and associating it to external network
    ...    which is associated to L3VPN
    VpnOperations.VPN Create L3VPN    vpnid=${VPN_INSTANCE_ID}    name=${VPN_NAME}    rd=["${DCGW_RD}"]    exportrt=["${DCGW_RD}"]    importrt=["${DCGW_RD}"]
    ${ext_net_id} =    OpenStackOperations.Get Net Id    @{EXTERNAL_NETWORKS}[0]
    VpnOperations.Associate L3VPN To Network    networkid=${ext_net_id}    vpnid=${VPN_INSTANCE_ID}
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    ${subnetid} =    OpenStackOperations.Get Subnet Id    @{EXTERNAL_SUB_NETWORKS}[0]
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --fixed-ip subnet=${subnetid},ip-address=${ExtIP}
    ${float} =    OpenStackOperations.Create And Associate Floating IPs    @{EXTERNAL_NETWORKS}[0]    @{NET_1_VMS}[0]
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP1_CONN_ID}
    BuiltIn.Should Contain    ${output}    ${ExtIP}

Verify Floating Ip De-provision And Reachability From External Network Via Neutron Router Through L3vpn
    [Documentation]    Check floating IP should not be present in dump flows after deleting the floating IP
    ...    and removing the external gateway from router which is associated to L3VPN
    OpenStackOperations.Get ControlNode Connection
    ${output} =    OpenStackOperations.OpenStack CLI    openstack floating ip list |awk '{print$2}'
    ${floating_id} =    BuiltIn.Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    OpenStackOperations.Delete Floating IP    ${floating_id}
    OpenStackOperations.Remove Gateway    ${ROUTER}
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP1_CONN_ID}
    BuiltIn.Should Not Contain    ${output}    ${ExtIP}

Verify Floating Ip Re-provision And Reachability From External Network Via Neutron Router Through L3vpn
    [Documentation]    Check floating IP should be present in dump flows after creating the floating IP again wnd associating it to external network
    ...    which is associated to L3VPN
    ${subnetid} =    OpenStackOperations.Get Subnet Id    @{EXTERNAL_SUB_NETWORKS}[0]
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --fixed-ip subnet=${subnetid},ip-address=${ExtIP}
    ${float} =    OpenStackOperations.Create And Associate Floating IPs    @{EXTERNAL_NETWORKS}[0]    @{NET_1_VMS}[0]
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP1_CONN_ID}
    BuiltIn.Should Contain    ${output}    ${ExtIP}

Verify Multiple Floating Ip Provision And Reachability From External Network Via Neutron Router Through L3vpn
    [Documentation]    Check Multiple floating IPs should be present in dump flows after creating multiple floating IPs and associating it to external network
    ...    which is associated to L3VPN
    ${subnetid} =    OpenStackOperations.Get Subnet Id    @{EXTERNAL_SUB_NETWORKS}[0]
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --fixed-ip subnet=${subnetid},ip-address=${ExtIP}
    ${FloatIp1} =    OpenStackOperations.Create And Associate Floating IPs    @{EXTERNAL_NETWORKS}[0]    @{NET_1_VMS}[1]
    ${FloatIp2} =    OpenStackOperations.Create And Associate Floating IPs    @{EXTERNAL_NETWORKS}[0]    @{NET_1_VMS}[2]
    ${FloatIp3} =    OpenStackOperations.Create And Associate Floating IPs    @{EXTERNAL_NETWORKS}[0]    @{NET_1_VMS}[3]
    ${output} =    OVSDB.Get Flow Entries On Node    ${OS_CMP2_CONN_ID}
    BuiltIn.Should Match Regexp    ${output}    ${ExtIP}
    BuiltIn.Should Match Regexp    ${output}    .*${FloatIp1}.*
    BuiltIn.Should Match Regexp    ${output}    .*${FloatIp2}.*
    BuiltIn.Should Match Regexp    ${output}    .*${FloatIp3}.*

*** Keywords ***
Suite Setup
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments.
    VpnOperations.Basic Suite Setup
    BgpOperations.Start Quagga Processes On ODL    ${ODL_SYSTEM_IP}
    BgpOperations.Start Quagga Processes On DCGW    ${DCGW_SYSTEM_IP}
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Create Setup
    Create Neutron Networks
    Create Neutron Subnets
    OpenStackOperations.Create SubNet    @{EXTERNAL_NETWORKS}[0]    @{EXTERNAL_SUB_NETWORKS}[0]    @{EXT_SUBNET_CIDRS}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    : FOR    ${port}    IN    @{PORTS}
    \    BuiltIn.Run Keyword And Ignore Error    Show Port    ${port['ID']}
    Create Nova VMs
    BgpOperations.Setup BGP Peering On ODL    ${ODL_SYSTEM_IP}    ${AS_ID}    ${DCGW_SYSTEM_IP}
    BgpOperations.Setup BGP Peering On DCGW    ${DCGW_SYSTEM_IP}    ${AS_ID}    ${ODL_SYSTEM_IP}    ${VPN_NAME}    ${DCGW_RD}    ${LOOPBACK_IP}
    OpenStackOperations.Create Router    ${ROUTER}
    OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[0]
    OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[1]

Create Neutron Networks
    [Documentation]    Create required number of networks
    : FOR    ${NET}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${NET}
    OpenStackOperations.Create Network    @{EXTERNAL_NETWORKS}[0]    --external --provider-network-type ${NETWORK_TYPE}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${NETWORK_URL}    ${NETWORKS}

Create Neutron Subnets
    [Documentation]    Create required number of subnets for previously created networks
    ${num_of_networks} =    BuiltIn.Get Length    ${NETWORKS}
    : FOR    ${index}    IN RANGE    0    ${num_of_networks}
    \    OpenStackOperations.Create SubNet    @{NETWORKS}[${index}]    @{SUBNETS}[${index}]    @{SUBNET_CIDRS}[${index}]
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${SUBNETWORK_URL}    ${SUBNETS}

Create Neutron Ports
    [Documentation]    Create required number of ports under previously created subnets
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[0]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[0]    @{PORTS}[1]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[2]    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Port    @{NETWORKS}[1]    @{PORTS}[3]    sg=${SECURITY_GROUP}
    BuiltIn.Wait Until Keyword Succeeds    3s    1s    Utils.Check For Elements At URI    ${CONFIG_API}/neutron:neutron/ports/    ${PORTS}

Create Nova VMs
    [Documentation]    Create Vm instances on compute nodes
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[1]    @{NET_1_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[2]    @{NET_1_VMS}[2]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance With Port On Compute Node    @{PORTS}[3]    @{NET_1_VMS}[3]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None

Stop Suite
    [Documentation]    Test teardown for snat suite.
    BgpOperations.Delete BGP Configuration On ODL    session
    BgpOperations.Delete BGP Config On Quagga    ${DCGW_SYSTEM_IP}    ${AS_ID}
    BgpOperations.Stop BGP Processes On Node    ${ODL_SYSTEM_IP}
    BgpOperations.Stop BGP Processes On Node    ${DCGW_SYSTEM_IP}
    OpenStackOperations.OpenStack Suite Teardown
