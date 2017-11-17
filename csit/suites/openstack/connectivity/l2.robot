*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
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
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
${SECURITY_GROUP}    l2_sg
@{NETWORKS_NAME}    l2_net_1    l2_net_2
@{SUBNETS_NAME}    l2_sub_1    l2_sub_2
@{NET_1_VM_INSTANCES}    l2_net_1_vm_1    l2_net_1_vm_2    l2_net_1_vm_3
@{NET_2_VM_INSTANCES}    l2_net_2_vm_1    l2_net_2_vm_2    l2_net_2_vm_3
@{SUBNETS_RANGE}    21.0.0.0/24    22.0.0.0/24
${NET_1_VLAN_ID}    1121

*** Test Cases ***
Create VLAN Network net_1
    [Documentation]    Create Network with neutron request.
    # in the case that the controller under test is using legacy netvirt features, vlan segmentation is not supported,
    # and we cannot create a vlan network. If those features are installed we will instead stick with vxlan.
    : FOR    ${feature_name}    IN    @{legacy_feature_list}
    \    ${feature_check_status} =    BuiltIn.Run Keyword And Return Status    KarafKeywords.Verify Feature Is Installed    ${feature_name}
    \    Exit For Loop If    '${feature_check_status}' == 'True'
    BuiltIn.Run Keyword If    '${feature_check_status}' == 'True'    OpenStackOperations.Create Network    @{NETWORKS_NAME}[0]
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

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[0]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS_NAME}[1]    ${NET_1_VM_INSTANCES}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_VM_IPS}    ${NET_1_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VM_INSTANCES}
    @{NET_2_VM_IPS}    ${NET2_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VM_INSTANCES}
    BuiltIn.Set Suite Variable    @{NET_1_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET2_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Ping Vm Instance1 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In net_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[2]

Ping Vm Instance1 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In net_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the vm instance and test some operations
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]    ${NET_1_VM_IPS}

Connectivity Tests From Vm Instance2 In net_1
    [Documentation]    Login to the vm instance and test operations
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[1]    ${NET_1_VM_IPS}

Connectivity Tests From Vm Instance3 In net_1
    [Documentation]    Login to the vm instance and test operations
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[2]    ${NET_1_VM_IPS}

Connectivity Tests From Vm Instance1 In net_2
    [Documentation]    Login to the vm instance and test operations
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[0]    ${NET_2_VM_IPS}

Connectivity Tests From Vm Instance2 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[1]    ${NET_2_VM_IPS}

Connectivity Tests From Vm Instance3 In net_2
    [Documentation]    Login to the vm instance using generated key pair.
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS_NAME}[1]    @{NET_2_VM_IPS}[2]    ${NET_2_VM_IPS}

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    OpenStackOperations.Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    OpenStackOperations.Ping From DHCP Should Not Succeed    @{NETWORKS_NAME}[0]    @{NET_1_VM_IPS}[0]

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in net_1.
    : FOR    ${vm}    IN    @{NET_1_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in net_2.
    : FOR    ${vm}    IN    @{NET_2_VM_INSTANCES}
    \    OpenStackOperations.Delete Vm Instance    ${vm}
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VM_INSTANCES}    @{NET_2_VM_INSTANCES}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Delete Sub Network In net_1
    [Documentation]    Delete Sub Net for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS_NAME}[0]

Delete Sub Network In net_2
    [Documentation]    Delete Sub Net for the Networks with neutron request.
    OpenStackOperations.Delete SubNet    @{SUBNETS_NAME}[1]

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${networks}    IN    @{NETWORKS_NAME}
    \    OpenStackOperations.Delete Network    ${networks}

Delete Security Group
    [Documentation]    Delete security group with neutron request
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    ${feature_check_status}=    Run Keyword And Return Status    Verify Feature Is Installed    odl-vtn-manager-neutron
    BuiltIn.Run Keyword If    '${feature_check_status}' != 'True'    DataModels.Verify Flows Are Cleaned Up On All OpenStack Nodes
