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
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2
@{NET_1_VM_IPS}    30.0.0.3    30.0.0.4
@{NET_2_VM_IPS}    30.0.0.5    30.0.0.6
@{GATEWAY_IPS}    30.0.0.1
@{DHCP_IPS}       30.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24
@{SECURITY_GROUPS}    SG1    SG2
@{sg_list}

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    @{SUBNETS_RANGE}[0]

Create New Security Groups SG1
    [Documentation]    Create security group for neutron service
    Create First Security Group    SG1

Delete Default Ingress Security Group Rule
    [Documentation]    Delete ingress rule for default security group
    Delete Default Ingress SG Rule

Create Vm Instances For Default Ingress SG in network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Ping Vm Instance1 For Default Ingress SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[0]

Ping Vm Instance2 For Default Ingress SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_1_VM_IPS}[1]

Delete Default Egress Security Group Rule
    [Documentation]    Delete egress rule for default security group
    Delete Default Egress SG Rule

Create Vm Instances For Default Egress SG in network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    network_1    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Ping Vm Instance1 For Default Egress SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_2_VM_IPS}[0]

Ping Vm Instance2 For Default Egress SG In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    network_1    @{NET_2_VM_IPS}[1]






