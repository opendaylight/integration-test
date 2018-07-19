*** Settings ***
Documentation     Test suite to validate network address translation(snat/dnat) functionality in openstack integrated environment.
...               All the testcases were written to do flow validation since dc gateway is unavailable in csit environment.
...               This suite assumes proper integration bridges and vxlan tunnels are configured in the environment.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           Collections
Library           RequestsLibrary
Library           SSHLibrary
Library           String
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
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}
    ${output} =    OpenStackOperations.Show Network    @{EXTERNAL_NETWORKS}[0]
    BuiltIn.Should Contain    ${output}    @{EXTERNAL_NETWORKS}[0]

Verify Successful Update Of Router With External_gateway_info, Disable SNAT And Enable SNAT
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --disable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_DISABLED}
    OpenStackOperations.Add Router Gateway    ${ROUTER}    @{EXTERNAL_NETWORKS}[0]    --enable-snat
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Contain    ${output}    ${SNAT_ENABLED}

Verify Successful Deletion Of External Network
    OpenStackOperations.Remove Gateway    ${ROUTER}
    ${output} =    OpenStackOperations.Show Router    ${ROUTER}
    BuiltIn.Should Not Contain    ${output}    ${SNAT_ENABLED}

*** Keywords ***
Start Suite
    [Documentation]    Test Suite for Subnet_Routing_and_Multicast_Deployments.
    VpnOperations.Basic Suite Setup
    Create Setup
    OpenStackOperations.Show Debugs    @{NET_1_VMS}
    OpenStackOperations.Get Suite Debugs

Create Setup
    Create Neutron Networks
    Create Neutron Subnets
    OpenStackOperations.Create SubNet    @{EXTERNAL_NETWORKS}[0]    @{EXTERNAL_SUB_NETWORKS}[0]    @{EXT_SUBNET_CIDRS}[0]
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}
    Create Neutron Ports
    Create Nova VMs
    OpenStackOperations.Create Router    ${ROUTER}
    OpenStackOperations.Add Router Interface    ${ROUTER}    @{SUBNETS}[0]

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
    BuiltIn.Should Not Contain    @{NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
