*** Settings ***
Documentation     Test suite to check North-South connectivity in L3 using a router and an external network
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
@{NETWORKS}       l3_ext_net
@{SUBNETS}        l3_ext_sub
${ROUTER}         l3_ext_router
@{FIP_VMS}        fip_vm_1    fip_vm_2
@{SNAT_VMS}       snat_vm_1    snat_vm_2
@{SUBNET_CIDRS}    41.0.0.0/24
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

Create Private Network
    [Documentation]    Create Network with neutron request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${network}

Create Subnet For Private Network
    [Documentation]    Create Sub Net for the Network with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]

Add Ssh Allow Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[0]    ${FIP_VMS}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[0]    ${SNAT_VMS}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{FIP_VM_IPS}    ${FLOATING_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{FIP_VMS}
    @{SNAT_VM_IPS}    ${SNAT_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{SNAT_VMS}
    BuiltIn.Set Suite Variable    @{FIP_VM_IPS}
    BuiltIn.Set Suite Variable    @{SNAT_VM_IPS}
    BuiltIn.Should Not Contain    ${FIP_VM_IPS}    None
    BuiltIn.Should Not Contain    ${SNAT_VM_IPS}    None
    BuiltIn.Should Not Contain    ${FLOATING_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${SNAT_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{FIP_VMS}    @{SNAT_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create External Network And Subnet
    OpenStackOperations.Create Network    ${EXTERNAL_NET_NAME}    --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    OpenStackOperations.Update Network    ${EXTERNAL_NET_NAME}    --external
    OpenStackOperations.Create Subnet    ${EXTERNAL_NET_NAME}    ${EXTERNAL_SUBNET_NAME}    ${EXTERNAL_SUBNET}    --gateway ${EXTERNAL_GATEWAY} --allocation-pool ${EXTERNAL_SUBNET_ALLOCATION_POOL}

Create Router
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    ${ROUTER}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}

Add Router Gateway To Router
    [Documentation]    OpenStackOperations.Add Router Gateway
    OpenStackOperations.Add Router Gateway    ${ROUTER}    ${EXTERNAL_NET_NAME}

Verify Created Router
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    Should Contain    ${data}    ${ROUTER}

Create And Associate Floating IPs for VMs
    [Documentation]    Create and associate a floating IP for the VM
    ${VM_FLOATING_IPS} =    OpenStackOperations.Create And Associate Floating IPs    ${EXTERNAL_NET_NAME}    @{FIP_VMS}
    BuiltIn.Set Suite Variable    ${VM_FLOATING_IPS}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{FIP_VMS}
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
    ${dst_ip}=    BuiltIn.Create List    @{VM_FLOATING_IPS}[1]
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{FIP_VM_IPS}[0]    ${dst_ip}    ttl=1

Ping External Network PNF from Vm Instance 1
    [Documentation]    Check reachability of External Network PNF from VM instance (with ttl=1 to make sure no router hops)
    ${dst_ip}=    BuiltIn.Create List    ${EXTERNAL_PNF}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{FIP_VM_IPS}[0]    ${dst_ip}    ttl=1

SNAT - TCP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance1
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{SNAT_VM_IPS}[0]    ${EXTERNAL_GATEWAY}    -u

SNAT - TCP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test TCP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}

SNAT - UDP connection to External Gateway From SNAT VM Instance2
    [Documentation]    Login to the VM instance and test UDP connection to the controller via SNAT
    OpenStackOperations.Test Netcat Operations From Vm Instance    @{NETWORKS}[0]    @{SNAT_VM_IPS}[1]    ${EXTERNAL_GATEWAY}    -u

Delete Vm Instances
    [Documentation]    Delete Vm instances using instance names.
    : FOR    ${vm}    IN    @{FIP_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    : FOR    ${vm}    IN    @{SNAT_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    ${ROUTER}

Verify Deleted Router
    [Documentation]    Check deleted router using northbound rest call
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    BuiltIn.Should Not Contain    ${data}    ${ROUTER}

Delete Sub Network
    [Documentation]    Delete Sub Net for the Network with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS}[0]

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
