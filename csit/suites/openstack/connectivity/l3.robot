*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
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
${SECURITY_GROUP}    l3_sg
@{NETWORKS}       l3_net_1    l3_net_2    l3_net_3    l3_net_4    l3_net_5
@{SUBNETS_1}      l3_sub_1    l3_sub_2    l3_sub_3
@{SUBNETS_2}      l3_sub_4    l3_sub_5
@{ROUTER}         l3_router1    l3_router2
@{NET_1_VMS}      l3_net_1_vm_1    l3_net_1_vm_2    l3_net_1_vm_3
@{NET_2_VMS}      l3_net_2_vm_1    l3_net_2_vm_2    l3_net_2_vm_3
@{NET_3_VMS}      l3_net_3_vm_1    l3_net_3_vm_2    l3_net_3_vm_3
@{NET_4_VMS}      l3_net_4_vm_1
@{NET_5_VMS}      l3_net_5_vm_1
@{SUBNET_CIDRS}    31.0.0.0/24    32.0.0.0/24    33.0.0.0/24    34.0.0.0/24    35.0.0.0/24
@{NET_VLAN_ID}    1131    1132    1133

*** Test Cases ***
Create VLAN Network net_1
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[0]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment @{NET_VLAN_ID}[0]

Create Subnet For net_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[0]    @{SUBNETS_1}[0]    @{SUBNET_CIDRS}[0]

Create VXLAN Network net_2
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[1]

Create Subnet For net_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[1]    @{SUBNETS_1}[1]    @{SUBNET_CIDRS}[1]

Create VXLAN Network net_3
    [Documentation]    Create Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[2]

Create Subnet For net_3
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[2]    @{SUBNETS_1}[2]    @{SUBNET_CIDRS}[2]

Create VLAN Network net_4
    [Documentation]    Create VLAN Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[3]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment @{NET_VLAN_ID}[1]

Create Subnet For net_4
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[3]    @{SUBNETS_2}[0]    @{SUBNET_CIDRS}[3]

Create VLAN Network net_5
    [Documentation]    Create VLAN Network with neutron request.
    OpenStackOperations.Create Network    @{NETWORKS}[4]    --provider-network-type vlan --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK} --provider-segment @{NET_VLAN_ID}[2]

Create Subnet For net_5
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    OpenStackOperations.Create SubNet    @{NETWORKS}[4]    @{SUBNETS_2}[1]    @{SUBNET_CIDRS}[4]

Add Ssh Allow All Rule
    [Documentation]    Allow all TCP/UDP/ICMP packets for this suite
    OpenStackOperations.Create Allow All SecurityGroup    ${SECURITY_GROUP}

Create Vm Instances For net_1
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[0]    @{NET_1_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Create Vm Instances For net_2
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[1]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[1]    @{NET_2_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Create Vm Instances For net_3
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[2]    @{NET_3_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[2]    @{NET_3_VMS}[1]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[2]    @{NET_3_VMS}[2]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Check Vm Instances Have Ip Address
    @{NET_1_L3_VM_IPS}    ${NET_1_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_1_VMS}
    @{NET_2_L3_VM_IPS}    ${NET_2_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_2_VMS}
    @{NET_3_L3_VM_IPS}    ${NET_3_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_3_VMS}
    BuiltIn.Set Suite Variable    @{NET_1_L3_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_2_L3_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_3_L3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_1_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_1_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_2_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_3_L3_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_1_VMS}    @{NET_2_VMS}    @{NET_3_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Create Router1
    [Documentation]    Create Router
    OpenStackOperations.Create Router    @{ROUTER}[0]

Add Interfaces To Router1
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_1}
    \    OpenStackOperations.Add Router Interface    @{ROUTER}[0]    ${interface}

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

Create Vm Instances For net_4
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[3]    @{NET_4_VMS}[0]    ${OS_CMP1_HOSTNAME}    sg=${SECURITY_GROUP}

Create Vm Instances For net_5
    [Documentation]    Create VM instances using flavor and image names for a network.
    OpenStackOperations.Create Vm Instance On Compute Node    @{NETWORKS}[4]    @{NET_5_VMS}[0]    ${OS_CMP2_HOSTNAME}    sg=${SECURITY_GROUP}

Create Router2
    [Documentation]    Create Router
    OpenStackOperations.Create Router    @{ROUTER}[1]

Add net_4 Interfaces To Router2
    [Documentation]    Add Interfaces
    OpenStackOperations.Add Router Interface    @{ROUTER}[1]    @{SUBNETS_2}[0]

Check Vm Instances on net_4 and net_5 Have Ip Address
    @{NET_4_L3_VM_IPS}    ${NET_4_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_4_VMS}
    @{NET_5_L3_VM_IPS}    ${NET_5_L3_DHCP_IP} =    OpenStackOperations.Get VM IPs    @{NET_5_VMS}
    BuiltIn.Set Suite Variable    @{NET_4_L3_VM_IPS}
    BuiltIn.Set Suite Variable    @{NET_5_L3_VM_IPS}
    BuiltIn.Should Not Contain    ${NET_4_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_5_L3_VM_IPS}    None
    BuiltIn.Should Not Contain    ${NET_4_L3_DHCP_IP}    None
    BuiltIn.Should Not Contain    ${NET_5_L3_DHCP_IP}    None
    [Teardown]    BuiltIn.Run Keywords    OpenStackOperations.Show Debugs    @{NET_4_VMS}    @{NET_5_VMS}
    ...    AND    OpenStackOperations.Get Test Teardown Debugs

Add net_5 Interfaces To Router2
    [Documentation]    Add Interfaces
    OpenStackOperations.Add Router Interface    @{ROUTER}[1]    @{SUBNETS_2}[1]

Ping Vm Instance5 In net_5 From net_4 (vlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[3]    @{NET_5_L3_VM_IPS}[0]

Ping Vm Instance5 In net_4 From net_5 (vlan to vlan)
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    OpenStackOperations.Ping Vm From DHCP Namespace    @{NETWORKS}[4]    @{NET_4_L3_VM_IPS}[0]

Connectivity Tests From Vm Instance4 In net_5
    [Documentation]    Check reachability of vm instance on a different network with one vlan vm in source and destination.
    ${dst_list} =    BuiltIn.Create List    @{NET_4_L3_VM_IPS}
    OpenStackOperations.Test Operations From Vm Instance    @{NETWORKS}[4]    @{NET_5_L3_VM_IPS}[0]    ${dst_list}
