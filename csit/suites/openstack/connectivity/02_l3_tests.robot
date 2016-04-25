*** Settings ***
Documentation    Test suite to check connectivity in L3 using routers.
Suite Setup    Devstack Suite Setup Tests
Suite Teardown      Close All Connections
Library    SSHLibrary
Library    OperatingSystem
Library    RequestsLibrary
Resource    ../../../libraries/Utils.robot
Resource    ../../../libraries/OpenStackOperations.robot
Resource    ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    subnet_1    subnet_2
@{NET_1_VM_INSTANCES}    l3_instance_net_1_1   l3_instance_net_1_2
@{NET_2_VM_INSTANCES}    l3_instance_net_2_1   l3_instance_net_2_2
@{NET_1_VM_IPS}    50.0.0.3    50.0.0.4
@{NET_2_VM_IPS}    60.0.0.3    60.0.0.4
@{GATEWAY_IPS}    50.0.0.1    60.0.0.1
@{DHCP_IPS}       50.0.0.2    60.0.0.2
@{SUBNETS_RANGE}    50.0.0.0/24    60.0.0.0/24

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]    devstack_path=/opt/stack/devstack

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_2    subnet_2    @{SUBNETS_RANGE}[1]     devstack_path=/opt/stack/devstack

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}      devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_2
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}      devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Create Routers
    [Documentation]    Create Router
    Create Router    router_1      devstack_path=/opt/stack/devstack

Add Interfaces To Router
    [Documentation]    Add Interfaces
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Add Router Interface    router_1    ${interface}      devstack_path=/opt/stack/devstack

Ping Vm Instance In network_2 From network_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    ${net_id}=    Get Net Id    network_1
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    @{NET_2_VM_IPS}[0]     devstack_path=/opt/stack/devstack
    Should Contain    ${output}    64 bytes

Ping Vm Instance In network_1 From network_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    ${net_id}=    Get Net Id    network_2
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    @{NET_1_VM_IPS}[0]     devstack_path=/opt/stack/devstack
    Should Contain    ${output}    64 bytes

Connectivity Tests From Vm Instances In network_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_1
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[0]     @{NET_1_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance      ${net_id}    @{NET_1_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3     list_of_external_dst_ips=${other_dst_ip_list}     devstack_path=/opt/stack/devstack

Connectivity Tests From Vm Instances In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_2
    ${dst_ip_list}=    Create List    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    ${other_dst_ip_list}=    Create List    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]
    Log    ${other_dst_ip_list}
    Test Operations From Vm Instance      ${net_id}    @{NET_2_VM_IPS}[0]    ${dst_ip_list}    l2_or_l3=l3     list_of_external_dst_ips=${other_dst_ip_list}     devstack_path=/opt/stack/devstack

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}      devstack_path=/opt/stack/devstack

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}       devstack_path=/opt/stack/devstack

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    : FOR    ${interface}    IN    @{SUBNETS_NAME}
    \    Remove Interface    router_1    ${interface}     devstack_path=/opt/stack/devstack

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    router_1      devstack_path=/opt/stack/devstack

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_1      devstack_path=/opt/stack/devstack

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_2     devstack_path=/opt/stack/devstack

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}       devstack_path=/opt/stack/devstack
