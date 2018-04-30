*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
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
${SECURITY_GROUP}    cl2_sg
@{NETWORKS}       cl2_net_1    cl2_net_2
@{SUBNETS}        cl2_sub_1    cl2_sub_2
@{NET_1_VMS}      cl2_net_1_vm_1    cl2_net_1_vm_2    cl2_net_1_vm_3
@{NET_2_VMS}      cl2_net_2_vm_1    cl2_net_2_vm_2    cl2_net_2_vm_3
@{SUBNET_CIDRS}    26.0.0.0/24    27.0.0.0/24
@{CLUSTER_DOWN_LIST}    ${1}    ${2}

*** Test Cases ***
Create All Controller Sessions
    [Documentation]    Create sessions for all three contorllers.
    ClusterManagement.ClusterManagement Setup

Create Network net_1
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[0]

Create Subnet For net_1
    [Documentation]    Create Sub Net for the Network with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]

Create Network net_2
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[1]

Create Subnet For net_2
    [Documentation]    Create Sub Net for the Network with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Bridge Manually and Verify Before Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify Before Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Take Down ODL1
    [Documentation]    Kill the karaf in First Controller
    ${new_cluster_list} =    ClusterManagement.Kill Single Member    1
    BuiltIn.Set Suite Variable    ${new_cluster_list}
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    2    3

Create Bridge Manually and Verify After Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Add Tap Device Manually and Verify After Fail
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Delete the Bridge Manually and Verify After Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}    ${new_cluster_list}

Bring Up ODL1
    [Documentation]    Bring up ODL1 again
    ClusterManagement.Start Single Member    1
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    2    3

Create Bridge Manually and Verify After Recover
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Add Tap Device Manually and Verify After Recover
    [Documentation]    Add tap devices to the bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Tap Device To The Manual Bridge And Verify    ${OS_CONTROL_NODE_IP}

Delete the Bridge Manually and Verify After Recover
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${OS_CONTROL_NODE_IP}

Take Down ODL2
    [Documentation]    Kill the karaf in Second Controller
    ClusterManagement.Kill Single Member    2
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    3

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_VM_IPS}    ${NET_2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Bring Up ODL2
    [Documentation]    Bring up ODL2 again
    ClusterManagement.Start Single Member    2
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    2    3

Ping Vm Instance1 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_1_VM_IPS}[2]

Ping Vm Instance1 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_2_VM_IPS}[2]

Take Down ODL3
    [Documentation]    Kill the karaf in Third Controller
    ClusterManagement.Kill Single Member    3
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    2

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]    ${NET_1_VM_IPS}

Connectivity Tests From Vm Instance2 In net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[1]    ${NET_1_VM_IPS}

Connectivity Tests From Vm Instance3 In net_1
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_VM_IPS}[2]    ${NET_1_VM_IPS}

Bring Up ODL3
    [Documentation]    Bring up ODL3 again
    ClusterManagement.Start Single Member    3
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    2    3

Take Down ODL1 and ODL2
    [Documentation]    Kill the karaf in First and Second Controller
    ClusterManagement.Kill Members From List Or All    ${CLUSTER_DOWN_LIST}
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    3

Connectivity Tests From Vm Instance1 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[0]    ${NET_2_VM_IPS}

Connectivity Tests From Vm Instance2 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[1]    ${NET_2_VM_IPS}

Connectivity Tests From Vm Instance3 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_VM_IPS}[2]    ${NET_2_VM_IPS}

Bring Up ODL1 and ODL2
    [Documentation]    Bring up ODL1 and ODL2 again.
    ClusterManagement.Start Members From List Or All    ${CLUSTER_DOWN_LIST}
    Wait Until Keyword Succeeds    60s    5s    ClusterManagement.Check Diagstatus On Cluster    1    2    3

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names. Also remove the VM from the
    ...    list so that later cleanup will not try to delete it.
    OpenStackOperations.Delete Vm Instance    @{NET_1_VMS}[0]
    Remove From List    ${NET_1_VMS}    0

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output} =    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS}[0]    @{NET_1_VM_IPS}[0]

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${vm}    IN    @{NET_2_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Sub Networks In net_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS}[0]

Delete Sub Networks In net_2
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
