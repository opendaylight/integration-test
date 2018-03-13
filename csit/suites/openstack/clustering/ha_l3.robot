*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       OpenStackOperations.OpenStack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           Collections
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${SECURITY_GROUP}    cl3_sg
@{NETWORKS}       cl3_net_1    cl3_net_2
@{SUBNETS}        cl3_sub_1    cl3_sub_2
@{ROUTERS}        cl3_router_1    cl3_router_2    cl3_router_3
@{NET_1_VMS}      cl3_net_1_vm_1    cl3_net_1_vm_2    cl3_net_1_vm_3
@{NET_2_VMS}      cl3_net_2_vm_1    cl3_net_2_vm_2    cl3_net_2_vm_3
@{SUBNET_CIDRS}    36.0.0.0/24    37.0.0.0/24
@{GATEWAY_IPS}    36.0.0.1    37.0.0.1
@{ODL_1_AND_2_DOWN}    ${1}    ${2}
@{ODL_2_AND_3_DOWN}    ${2}    ${3}

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterManagement.ClusterManagement Setup

Take Down Leader Of Default Shard
    [Documentation]    Kill the karaf on ODL cluster leader
    ${cluster_leader}    ${followers} =    ClusterManagement.Get Leader And Followers For Shard    shard_type=config
    BuiltIn.Set Suite Variable    ${cluster_leader}
    ClusterManagement.Kill Single Member    ${cluster_leader}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS}
    \    OpenStackOperations.Create Network    ${NetworkElement}

Create Subnets For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]

Create Subnets For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]

Bring Up Leader Of Default Shard
    [Documentation]    Bring up on cluster leader
    ClusterManagement.Start Single Member    ${cluster_leader}

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ClusterManagement.Kill Single Member    1

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1

Take Down ODL2
    [Documentation]    Kill the karaf in Second Controller
    ClusterManagement.Kill Single Member    2

Create Vm Instances For net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_L3_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_L3_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_L3_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_L3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterManagement.Start Single Member    2

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    3

Create Router router_2
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    @{ROUTERS}[1]
    [Teardown]    Report_Failure_Due_To_Bug    6117

Create Router router_3
    [Documentation]    Create Router and Add Interface to the subnets.
    OpenStackOperations.Create Router    @{ROUTERS}[2]

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    @{ROUTERS}[2]    ${interface}

Verify Created Routers
    [Documentation]    Check created routers using northbound rest calls
    ${data}    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    Should Contain    ${data}    @{ROUTERS}[2]

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3

Ping Vm Instance1 In net_2 From net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[0]

Ping Vm Instance2 In net_2 From net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[1]

Ping Vm Instance3 In net_2 From net_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[2]

Ping Vm Instance1 In net_1 From net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[0]

Ping Vm Instance2 In net_1 From net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[1]

Ping Vm Instance3 In net_1 From net_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[2]

Take Down ODL1 and ODL2
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${ODL_1_AND_2_DOWN}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[0]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance2 In net_1
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[1]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance3 In net_1
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[2]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again
    ClusterManagement.Start Members From List Or All    ${ODL_1_AND_2_DOWN}

Take Down ODL2 and ODL3
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${ODL_2_AND_3_DOWN}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance1 In net_2
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[0]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance2 In net_2
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[1]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Connectivity Tests From Vm Instance3 In net_2
    [Documentation]    ssh to the VM instance and test operations.
    ${dst_list} =    BuiltIn.Create List    @{NET_2_L3_VM_IPS}    @{NET_1_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[2]    ${dst_list}
    [Teardown]    OpenStackOperations.Get OvsDebugInfo

Bring Up ODL2 and ODL3
    [Documentation]    Bring up ODL2 and ODL3 again.
    ClusterManagement.Start Members From List Or All    ${ODL_2_AND_3_DOWN}

Take Down All Instances
    [Documentation]    Stop karaf on all controllers
    ClusterManagement.Kill Members From List Or All

Bring Up All Instances
    [Documentation]    Bring up all controllers
    ClusterManagement.Start Members From List Or All

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in net_1.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in net_2.
    : FOR    ${vm}    IN    @{NET_2_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    @{ROUTERS}[2]    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    @{ROUTERS}[1]
    OpenStackOperations.Delete Router    @{ROUTERS}[2]

Verify Deleted Routers
    [Documentation]    Check deleted routers using northbound rest calls
    ${data} =    Utils.Get Data From URI    1    ${NEUTRON_ROUTERS_API}
    BuiltIn.Log    ${data}
    BuiltIn.Should Not Contain    ${data}    @{ROUTERS}[2]

Delete Sub Network In net_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS}[0]

Delete Sub Network In net_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS}[1]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}

Delete Security Group
    [Documentation]    Delete security groups with neutron request
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    DataModels.Verify Flows Are Cleaned Up On All OpenStack Nodes
