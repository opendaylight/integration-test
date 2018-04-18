*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Force Tags        skip_if_${ODL_SNAT_MODE}
Library           Collections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    l3_ext_sg
@{NETWORKS}       l3_ext_net_1    l3_ext_net_2
@{SUBNETS}        l3_ext_sub_1    l3_ext_sub_2
@{ROUTERS}        l3_ext_router_1    l3_ext_router_2
@{NET1_FIP_VMS}    l3_ext_net_1_fip_vm_1    l3_ext_net_1_fip_vm_2
@{NET1_SNAT_VMS}    l3_ext_net_1_snat_vm_1    l3_ext_net_1_snat_vm_2
@{NET2_SNAT_VMS}    l3_ext_net_2_snat_vm_3
@{SNAT_VMS}       @{NET1_SNAT_VMS}    @{NET2_SNAT_VMS}
@{SUBNET_CIDRS}    41.0.0.0/24    42.0.0.0/24
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${EXTERNAL_GATEWAY}    10.10.10.250
${EXTERNAL_PNF}    10.10.10.253
${EXTERNAL_SUBNET}    10.10.10.0/24
${EXTERNAL_SUBNET_ALLOCATION_POOL}    start=10.10.10.2,end=10.10.10.249
${EXTERNAL_INTERNET_ADDR}    10.9.9.9

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three controllers
    ClusterManagement.ClusterManagement Setup

Create Private Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}

Create Subnets For Private Networks
    [Documentation]    Create Sub Net for the Network with neutron request.
    : FOR    ${network}    ${subnet}    ${cidr}    IN ZIP    ${NETWORKS}    ${SUBNETS}
    ...    ${SUBNET_CIDRS}
    \    OpenStackOperations.Create SubNet    ${network}    ${subnet}    ${cidr}

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET1_FIP_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET1_FIP_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_SNAT_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_SNAT_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_SNAT_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET1_FIP_VM_IPS}    ${NET1_FIP_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET1_FIP_VMS}
    @{NET1_SNAT_VM_IPS}    ${NET1_SNAT_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET1_SNAT_VMS}
    @{NET2_SNAT_VM_IPS}    ${NET2_SNAT_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET2_SNAT_VMS}
    BuiltIn.Set Suite Variable    @{NET1_FIP_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET1_SNAT_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET2_SNAT_VM_IPS}
    BuiltIn.Should Not Contain    ${NET1_FIP_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_SNAT_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET2_SNAT_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET1_FIP_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET1_SNAT_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_SNAT_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET1_FIP_VMS}    @{SNAT_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create External Network And Subnet
    OpenStackOperations.Create External Network And Subnet

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Create Router    ${router}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${router}    ${interface}    IN ZIP    ${ROUTERS}    ${SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${router}    ${interface}

Add Router Gateway To Router
    [Documentation]    OpenStackOperations.Add Router Gateway
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Add Router Gateway    ${router}    ${EXTERNAL_NET_NAME}

Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    : FOR    ${router}    IN    @{ROUTERS}
    \    Should Contain    ${data}    ${router}

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${EXTERNAL_NET_NAME}    @{NET1_FIP_VMS}
    BuiltIn.Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET1_FIP_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Ping External Gateway From Control Node
    [Documentation]    Check reachability of external gateway by pinging it from the control node.
    OpenStackOperations.Ping Vm From Control Node    ${EXTERNAL_GATEWAY}    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance2 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[1]    additional_args=-I ${EXTERNAL_INTERNET_ADDR}

Ping Vm Instance2 Floating IP From Vm Instance1 With Floating IP (Hairpinning)
    [Documentation]    Check reachability of VM instance floating IP from another VM instance with FIP (with ttl=1 to make sure no router hops)
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1

Ping Vm Instance1 Floating IP From SNAT VM Instance1
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance1 Floating IP From SNAT VM Instance2
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[0]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance2 Floating IP From SNAT VM Instance1
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping Vm Instance2 Floating IP From SNAT VM Instance2
    [Documentation]    Check reachability of VM instance floating IP from another VM without Floating IP
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ttl=1    ping_should_succeed=${expect_ping_to_work}

Ping External Network PNF from Vm Instance 1
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_FIP_VM_IPS}[0]    ${dst_ip}    ttl=1

SNAT - TCP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance3
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance3
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[1]    @{NET2_SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}    -u

Ping External Network PNF from SNAT VM Instance1
    [Documentation]    Check reachability of External Network PNF from SNAT VM Instance1
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[0]    ${dst_ip}    ping_should_succeed=${expect_ping_to_work}

Ping External Network PNF from SNAT VM Instance2
    [Documentation]    Check reachability of External Network PNF from SNAT VM Instance2
    ${expect_ping_to_work} =    Set Variable If    "skip_if_controller" in @{TEST_TAGS}    False    True
    ${dst_ip} =    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET1_SNAT_VM_IPS}[1]    ${dst_ip}    ping_should_succeed=${expect_ping_to_work}

Delete Vm Instances
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${vm}    IN    @{NET1_FIP_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${vm}    IN    @{SNAT_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${router}    ${interface}    IN ZIP    ${ROUTERS}    ${SUBNETS}
    \    OpenStackOperations.Remove Interface    ${router}    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    : FOR    ${router}    IN    @{ROUTERS}
    \    OpenStackOperations.Delete Router    ${router}

Verify Deleted Router
    [Documentation]    Check deleted router using northbound rest call
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    : FOR    ${router}    IN    @{ROUTERS}
    \    BuiltIn.Should Not Contain    ${data}    ${ROUTER}

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}
    OpenStackOperations.Delete Network    ${EXTERNAL_NET_NAME}

Delete Security Group
    [Documentation]    Delete security groups with neutron request
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    DataModels.Verify Flows Are Cleaned Up On All OpenStack Nodes
