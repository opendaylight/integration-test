*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
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
${SECURITY_GROUP}    l3_sg
@{NETWORKS_NAME}    l3_net_1    l3_net_2    l3_net_3
@{SUBNETS_NAME}    l3_sub_1    l3_sub_2    l3_sub_3
${ROUTER_NAME}    l3_router
@{NET_1_VM_INSTANCES}    l3_net_1_vm_1    l3_net_1_vm_2    l3_net_1_vm_3
@{NET_2_VM_INSTANCES}    l3_net_2_vm_1    l3_net_2_vm_2    l3_net_2_vm_3
@{NET_3_VM_INSTANCES}    l3_net_3_vm_1    l3_net_3_vm_2    l3_net_3_vm_3
@{SUBNETS_RANGE}    31.0.0.0/24    32.0.0.0/24    33.0.0.0/24
${NET_1_VLAN_ID}    1131

*** Test Cases ***
Create VLAN Network net_1
    [Documentation]    Create Network with neutron request.
    # in the case that the controller under test is using legacy netvirt features, vlan segmentation is not supported,
    # and we cannot create a vlan network. If those features are installed we will instead stick with vxlan.
    : FOR    ${feature_name}    IN    @{legacy_feature_list}
    \    ${feature_check_status} =    BuiltIn.Run Keyword And Return Status    KarafKeywords.Verify Feature Is Installed    ${feature_name}
    \    Exit For Loop If    '${feature_check_status}' == 'True'
    Run Keyword If    '${feature_check_status}' == 'True'    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]
    ...    ELSE    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment ${NET_1_VLAN_ID}

Create Subnet For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[0]    @{SUBNETS_NAME}[0]    @{SUBNETS_RANGE}[0]

Create VXLAN Network net_2
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[1]

Create Subnet For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[1]    @{SUBNETS_NAME}[1]    @{SUBNETS_RANGE}[1]

Create VXLAN Network net_3
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS_NAME}[2]

Create Subnet For net_3
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS_NAME}[2]    @{SUBNETS_NAME}[2]    @{SUBNETS_RANGE}[2]

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_2_VM_INSTANCES}    sg=${SECURITY_GROUP}

Create Vm Instances For net_3
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[2]    ${NET_3_VM_INSTANCES}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_L3_VM_IPS}    ${NET_1_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET_2_L3_VM_IPS}    ${NET_2_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    @{NET_3_L3_VM_IPS}    ${NET_3_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VM_INSTANCES}
    BuiltIn.Set Suite Variable    ${NET_1_L3_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_2_L3_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_3_L3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}    @{NET_3_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Routers
    [Documentation]    Create Router
    OpenStackOperations.Create Router    ${ROUTER_NAME}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Add Router Interface    ${ROUTER_NAME}    ${interface}

Ping Vm Instance1 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_2_L3_VM_IPS}[0]

Ping Vm Instance2 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_2_L3_VM_IPS}[1]

Ping Vm Instance3 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_2_L3_VM_IPS}[2]

Ping Vm Instance1 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_1_L3_VM_IPS}[0]

Ping Vm Instance2 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_1_L3_VM_IPS}[1]

Ping Vm Instance3 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_1_L3_VM_IPS}[2]

Ping Vm Instance1 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_3_L3_VM_IPS}[0]

Ping Vm Instance2 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_3_L3_VM_IPS}[1]

Ping Vm Instance3 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_3_L3_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the VM instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In net_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In net_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_L3_VM_IPS}[2]    ${dst_list}

Connectivity Tests From Vm Instance1 In net_2
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_L3_VM_IPS}[2]    ${dst_list}

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in net_1.
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in net_2.
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_3
    [Documentation]    Delete Vm instances using instance names in net_3.
    : FOR    ${vm}    IN    @{NET_3_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    OpenStackOperations.Remove Interface    ${ROUTER_NAME}    ${interface}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    ${ROUTER_NAME}

Delete Sub Network In net_1
    [Documentation]    Delete Sub Net for the Network with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_1

Delete Sub Network In net_2
    [Documentation]    Delete Sub Net for the Network with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_2

Delete Sub Network In net_3
    [Documentation]    Delete Sub Net for the Network with neutron request.
    OpenStackOperations.Delete SubNet    l3_sub_3

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${network}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${network}

Delete Security Group
    [Documentation]    Delete security group with neutron request
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    DataModels.Verify Flows Are Cleaned Up On All OpenStack Nodes
