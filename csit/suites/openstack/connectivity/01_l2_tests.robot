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
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1    MyThirdInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2    MyThirdInstance_2
@{NET_1_VM_IPS}    30.0.0.3    30.0.0.4    30.0.0.5
@{NET_2_VM_IPS}    40.0.0.3    40.0.0.4    40.0.0.5
@{VM_IPS_NOT_DELETED}    30.0.0.4    30.0.0.5
@{GATEWAY_IPS}    30.0.0.1    40.0.0.1
@{DHCP_IPS}       30.0.0.2    40.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
@{ETHER_TYPE}    IPv4    IPv6

*** Test Cases ***
Delete Default Security Group Rules
    [Documentation]    Delete the existing default security group rules before creating networks.
    ${devstack_conn_id}=       Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-rule-list
    Log    ${output}
    Delete Default Ingress SG Rule    ${ETHER_TYPE}
    ${devstack_conn_id}=       Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    neutron security-group-rule-list
    Log    ${output}
    Close Connection

Create Custom Security Groups
    Create Custom Security Group    sg1

Add Rule To The Custom Security Group
    Add Custom Rule    sg1

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_1    l2_subnet_1    @{SUBNETS_RANGE}[0]

Add Custom Rule For l2_network_1
    [Documentation]    Add custom rule to the created network l2_network_1.
    ${net1_mac_addr}=    Get Mac Address    @{DHCP_IPS}[0]
    Set Suite Variable    ${net1_mac_addr}
    #Add Rule To DHCP    ${net1_mac_addr}

Create Subnets For l2_network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_2    l2_subnet_2    @{SUBNETS_RANGE}[1]
