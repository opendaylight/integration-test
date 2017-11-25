*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SECURITY_GROUP}    sg-connectivity
@{NETWORKS_NAME}    l3_net
@{SUBNETS_NAME}    l3_subnet
@{VM_INSTANCES_FLOATING}    VmInstanceFloating1    VmInstanceFloating2
@{VM_INSTANCES_SNAT}    VmInstanceSnat3    VmInstanceSnat4
@{SUBNETS_RANGE}    90.0.0.0/24
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${external_gateway}    10.10.10.250
${external_pnf}    10.10.10.253
${external_subnet}    10.10.10.0/24
${external_subnet_allocation_pool}    start=10.10.10.2,end=10.10.10.249
${external_internet_addr}    10.9.9.9
${external_net_name}    external-net
${external_subnet_name}    external-subnet

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three controllers
    ClusterManagement.ClusterManagement Setup

Create External Network And Subnet
    Create Network    ${external_net_name}    --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    Update Network    ${external_net_name}    --external
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    router1

Add Router Gateway To Router
    [Documentation]    Add Router Gateway
    OpenStackOperations.Add Router Gateway    router1    ${external_net_name}

Create Private Network
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnet For Private Network
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES_FLOATING}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${VM_INSTANCES_SNAT}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{FLOATING_VM_IPS}    ${FLOATING_DHCP_IP} =    Get VM IPs    @{VM_INSTANCES_FLOATING}
    @{SNAT_VM_IPS}    ${SNAT_DHCP_IP} =    Get VM IPs    @{VM_INSTANCES_SNAT}
    Set Suite Variable    @{FLOATING_VM_IPS}
    Set Suite Variable    @{SNAT_VM_IPS}
    Should Not Contain    ${FLOATING_VM_IPS}    None
    Should Not Contain    ${SNAT_VM_IPS}    None
    Should Not Contain    ${FLOATING_DHCP_IP}    None
    Should Not Contain    ${SNAT_DHCP_IP}    None
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES_FLOATING}    @{VM_INSTANCES_SNAT}
    ...    AND    Get Test Teardown Debugs


Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    router1    ${interface}


Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Contain    ${data}    router1

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS}    OpenStackOperations.Create And Associate Floating IPs    ${external_net_name}    @{VM_INSTANCES_FLOATING}
    Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    Run Keywords    Show Debugs    @{VM_INSTANCES_FLOATING}
    ...    AND    Get Test Teardown Debugs

Ping External Gateway From Control Node
    [Documentation]    Check reachability of external gateway by pinging it from the control node.
    OpenStackOperations.Ping Vm From Control Node    ${external_gateway}    additional_args=-I ${external_internet_addr}

Ping Vm Instance1 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[0]    additional_args=-I ${external_internet_addr}

Ping Vm Instance2 Floating IP From Control Node
    [Documentation]    Check reachability of VM instance through floating IP by pinging them.
    OpenStackOperations.Ping Vm From Control Node    @{VM_FLOATING_IPS}[1]    additional_args=-I ${external_internet_addr}

Ping Vm Instance2 Floating IP From Vm Instance1 With Floating IP (Hairpinning)
    [Documentation]    Check reachability of VM instance floating IP from another VM instance with FIP (with ttl=1 to make sure no router hops)
    ${dst_ip}=    Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{FLOATING_VM_IPS}[0]    ${dst_ip}    ttl=1

Ping External Network PNF from Vm Instance 1
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${dst_ip}=    Create List    ${external_pnf}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{FLOATING_VM_IPS}[0]    ${dst_ip}    ttl=1

SNAT - TCP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[0]    ${external_gateway}

SNAT - UDP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[0]    ${external_gateway}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[1]    ${external_gateway}

SNAT - UDP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    Test Netcat Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{SNAT_VM_IPS}[1]    ${external_gateway}    -u

Delete Vm Instances
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_FLOATING}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}
    : FOR    ${VmElement}    IN    @{VM_INSTANCES_SNAT}
    \    OpenStackOperations.Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    router1    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    router1

Verify Deleted Routers
    [Documentation]    Check deleted routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    Log    ${data}
    Should Not Contain    ${data}    router1

Delete Sub Networks
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS_NAME}[0]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${NetworkElement}
    OpenStackOperations.Delete Network    ${external_net_name}

Delete Security Group
    [Documentation]    Delete security groups with neutron request
    Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    Verify Flows Are Cleaned Up On All OpenStack Nodes
