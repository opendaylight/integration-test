*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
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
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Tcpdump.robot

*** Variables ***
${SECURITY_GROUP}    l3_sg
@{NETWORKS}       l3_net_1    l3_net_2    l3_net_3
@{SUBNETS}        l3_sub_1    l3_sub_2    l3_sub_3
${ROUTER}         l3_router
@{NET_1_VMS}      l3_net_1_vm_1    l3_net_1_vm_2    l3_net_1_vm_3
@{NET_2_VMS}      l3_net_2_vm_1    l3_net_2_vm_2    l3_net_2_vm_3
@{NET_3_VMS}      l3_net_3_vm_1    l3_net_3_vm_2    l3_net_3_vm_3
@{SUBNET_CIDRS}    31.0.0.0/24    32.0.0.0/24    33.0.0.0/24
${NET_1_VLAN_ID}    1131

*** Test Cases ***
Create VLAN Network net_1
    [Documentation]    Create Network with neutron request.
    # in the case that the controller under test is using legacy netvirt features, vlan segmentation is not supported,
    # and we cannot create a vlan network. If those features are installed we will instead stick with vxlan.
    ${feature_check_status} =    OpenStackOperations.Is Feature Installed    ${legacy_feature_list}
    Run Keyword If    '${feature_check_status}' == 'True'    OpenStackOperations.Create Network    @{NETWORKS}[0]
    ...    ELSE    OpenStackOperations.Create Network    @{NETWORKS}[0]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment ${NET_1_VLAN_ID}

Create Subnet For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS}[0]    @{SUBNET_CIDRS}[0]

Create VXLAN Network net_2
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[1]

Create Subnet For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS}[1]    @{SUBNET_CIDRS}[1]

Create VXLAN Network net_3
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[2]

Create Subnet For net_3
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[2]    @{SUBNETS}[2]    @{SUBNET_CIDRS}[2]

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[0]    ${NET_1_VMS}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[1]    ${NET_2_VMS}    sg=${SECURITY_GROUP}

Create Vm Instances For net_3
    [Documentation]    Create Vm instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instances    @{NETWORKS}[2]    ${NET_3_VMS}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_L3_VM_IPS}    ${NET_1_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_L3_VM_IPS}    ${NET_2_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_L3_VM_IPS}    ${NET_3_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    BuiltIn.Set Suite Variable    ${NET_1_L3_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_2_L3_VM_IPS}
    BuiltIn.Set Suite Variable    ${NET_3_L3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}    @{NET_3_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Routers
    [Documentation]    Create Router
    OpenStackOperations.Create Router    ${ROUTER}

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Add Router Interface    ${ROUTER}    ${interface}

Ping Vm Instance1 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[0]

Ping Vm Instance2 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[1]

Ping Vm Instance3 In net_2 From net_1 (vxlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[0]    @{NET_2_L3_VM_IPS}[2]

Ping Vm Instance1 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[0]

Ping Vm Instance2 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[1]

Ping Vm Instance3 In net_1 From net_2 (vlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_1_L3_VM_IPS}[2]

Ping Vm Instance1 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_3_L3_VM_IPS}[0]

Ping Vm Instance2 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_3_L3_VM_IPS}[1]

Ping Vm Instance3 In net_3 From net_2 (vxlan to vxlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[1]    @{NET_3_L3_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In net_1
    [Documentation]    Login to the VM instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In net_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In net_1
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[0]    @{NET_1_L3_VM_IPS}[2]    ${dst_list}

Connectivity Tests From Vm Instance1 In net_2
    [Documentation]    Login to the vm instance and test operations
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[0]    ${dst_list}

Connectivity Tests From Vm Instance2 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[1]    ${dst_list}

Connectivity Tests From Vm Instance3 In net_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_list} =    BuiltIn.Create List    @{NET_1_L3_VM_IPS}    @{NET_2_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[1]    @{NET_2_L3_VM_IPS}[2]    ${dst_list}

Delete Vm Instances In net_1
    [Documentation]    Delete Vm instances using instance names in net_1.
    : FOR    ${vm}    IN    @{NET_1_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_2
    [Documentation]    Delete Vm instances using instance names in net_2.
    : FOR    ${vm}    IN    @{NET_2_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Vm Instances In net_3
    [Documentation]    Delete Vm instances using instance names in net_3.
    : FOR    ${vm}    IN    @{NET_3_VMS}
    \    OpenStackOperations.Delete Vm Instance    ${vm}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS}
    \    OpenStackOperations.Remove Interface    ${ROUTER}    ${interface}

Delete Router
    [Documentation]    Delete Router and Interface to the subnets.
    OpenStackOperations.Delete Router    ${ROUTER}

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
    : FOR    ${network}    IN    @{NETWORKS}
    \    OpenStackOperations.Delete Network    ${network}

Delete Security Group
    [Documentation]    Delete security group with neutron request
    OpenStackOperations.Delete SecurityGroup    ${SECURITY_GROUP}

Verify Flows Cleanup
    [Documentation]    Verify that flows have been cleaned up properly after removing all neutron configurations
    DataModels.Verify Flows Are Cleaned Up On All OpenStack Nodes

*** Keywords ***
Start Suite
    OpenStackOperations.OpenStack Suite Setup
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set TRACE org.opendaylight.openflowplugin
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set TRACE org.opendaylight.genius.interfacemanager.servicebindings
    @{ips} =    BuiltIn.Create List    ${OS_CONTROL_NODE_IP}    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    ${suite_} =    BuiltIn.Evaluate    """${SUITE_NAME}""".replace(" ","_").replace("/","_").replace(".","_")
    ${tag} =    BuiltIn.Catenate    SEPARATOR=__    tcpdump    ${suite_}
    @{conn_ids} =    Tcpdump.Start Packet Capture on Nodes    tag=${tag}    filter=port 6653    ips=${ips}
    BuiltIn.Set Suite Variable    @{conn_ids}

Stop Suite
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.openflowplugin
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set INFO org.opendaylight.genius.interfacemanager.servicebindings
    Tcpdump.Stop Packet Capture on Nodes    ${conn_ids}
    OpenStackOperations.OpenStack Suite Teardown
