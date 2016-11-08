*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
#Test Teardown     Run Keywords    Show Debugs    ${NET_1_VM_INSTANCES}
#...               AND    Show Debugs    ${NET_2_VM_INSTANCES}
#...               AND    Get OvsDebugInfo
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    subnet_1    subnet_2
@{NET_1_VM_INSTANCES}    l3_instance_net_1_1    l3_instance_net_1_2    l3_instance_net_1_3
@{NET_2_VM_INSTANCES}    l3_instance_net_2_1    l3_instance_net_2_2    l3_instance_net_2_3
@{NET_1_VM_IPS}    50.0.0.3    50.0.0.4    50.0.0.5
@{NET_2_VM_IPS}    60.0.0.3    60.0.0.4    60.0.0.5
@{GATEWAY_IPS}    50.0.0.1    60.0.0.1
@{DHCP_IPS}       50.0.0.2    60.0.0.2
@{SUBNETS_RANGE}    50.0.0.0/24    60.0.0.0/24

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_2    subnet_2    @{SUBNETS_RANGE}[1]

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}    sg=csit

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_2    ${NET_2_VM_INSTANCES}    sg=csit

Create Routers
    [Documentation]    Create Router
    Create Router    router_1

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}

Ping Vm Instance1 In network_2 From network_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_1    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 In network_2 From network_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_1    @{NET_2_VM_IPS}[1]

Ping Vm Instance3 In network_2 From network_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_1    @{NET_2_VM_IPS}[2]

Ping Vm Instance1 In network_1 From network_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_2    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In network_1 From network_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_2    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In network_1 From network_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    network_2    @{NET_1_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance2 In network_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance3 In network_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[2]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance1 In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance2 In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Connectivity Tests From Vm Instance3 In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[0]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[0]    @{NET_1_VM_IPS}[1]    @{NET_1_VM_IPS}[2]
    Log    ${other_dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    network_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}    l2_or_l3=l3    list_of_external_dst_ips=${other_dst_ip_list}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    router_1

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_1

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
