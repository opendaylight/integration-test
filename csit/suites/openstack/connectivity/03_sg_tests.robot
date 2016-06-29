*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

*** Variables ***
@{NETWORKS_NAME}    network_1
@{SUBNETS_NAME}    subnet_1
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1
@{NET_1_VM_IPS}    30.0.0.3    30.0.0.4
@{GATEWAY_IPS}    30.0.0.1
@{DHCP_IPS}       30.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24
@{SECURITY_GROUPS}    SG1    SG2

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Ping Vm Instance1 In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[1]

Ping Vm Instance3 In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[2]

Connectivity Tests From Vm Instance1 In network_1
    [Documentation]    Logging to the vm instance1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}

Create New Security Groups SG1
    [Documentation]    Create security group for neutron service
    Create First Security Group    SG1

Delete Default Ingress Security Group Rule
    [Documentation]    Delete ingress rule for default security group
    Delete Default Ingress SG Rule
    
Delete Default Egress Security Group Rule
    [Documentation]    Delete egress rule for default security group
    Delete Default Egress SG Rule


