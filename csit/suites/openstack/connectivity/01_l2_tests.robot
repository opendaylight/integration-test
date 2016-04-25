*** Settings ***
Documentation    Test suite to verify packet flows between vm instances.
Suite Setup    Devstack Suite Setup Tests
Library    SSHLibrary
Library    OperatingSystem
Library    RequestsLibrary
Resource    ../../../libraries/Utils.robot
Resource    ../../../libraries/OpenStackOperations.robot
Resource    ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    network_1    network_2
@{SUBNETS_NAME}    subnet_1    subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2
@{NET_1_VM_IPS}    30.0.0.3    30.0.0.4
@{NET_2_VM_IPS}    40.0.0.3    40.0.0.4
@{VM_IPS_NOT_DELETED}    30.0.0.4
@{GATEWAY_IPS}    30.0.0.1    40.0.0.1
@{DHCP_IPS}       30.0.0.2    40.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]     devstack_path=/opt/stack/devstack

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_2    subnet_2    @{SUBNETS_RANGE}[1]      devstack_path=/opt/stack/devstack

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}      devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}     devstack_path=/opt/stack/devstack
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Ping All Vm Instances In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_1
    : FOR    ${VmIpElement}    IN    @{NET_1_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}     devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

Ping All Vm Instances In network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_2
    : FOR    ${VmIpElement}    IN    @{NET_2_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}     devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

Connectivity Tests From Vm Instances In network_1
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance      ${net_id}    @{NET_1_VM_IPS}[0]    ${dst_ip_list}      devstack_path=/opt/stack/devstack

Connectivity Tests From Vm Instances In network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_2
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance      ${net_id}    @{NET_2_VM_IPS}[0]    ${dst_ip_list}      devstack_path=/opt/stack/devstack

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1     devstack_path=/opt/stack/devstack

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_1
    : FOR    ${VmIpElement}    IN    @{VM_IPS_NOT_DELETED}
    \    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}      devstack_path=/opt/stack/devstack
    \    Should Contain    ${output}    64 bytes

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    @{NET_1_VM_IPS}[0]
    Should Contain    ${output}    Destination Host Unreachable

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}       devstack_path=/opt/stack/devstack

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}      devstack_path=/opt/stack/devstack

Delete Sub Networks In network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_1     devstack_path=/opt/stack/devstack

Delete Sub Networks In network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    subnet_2    devstack_path=/opt/stack/devstack

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}     devstack_path=/opt/stack/devstack
