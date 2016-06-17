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
@{TABLE_LIST}    table=0    table=20    table=30    table=40    table=50    table=60    table=70    table=80    table=90    table=100    table=110
@{NETWORK_FLOWS}    table=0    table=20    table=110
@{VM_FLOWS}    table=0    table=20    table=40    table=90    table=110

*** Test Cases ***
Check Initial Dump Flows
    [Documentation]    Verify the existence of tables from table 0 to table 110 in the dump flow.
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int
    Log    ${output}
    : FOR    ${table}    IN    @{TABLE_LIST}
    \    Should Contain    ${output}    ${table}

Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_1    l2_subnet_1    @{SUBNETS_RANGE}[0]

Verify Created Network l2_network_1
    [Documentation]    Gateway is enabled here, so the consecutive ip will be assigned for the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int    30s
    Log    ${output}
    Should Contain    ${output}    @{DHCP_IPS}[0]
    ${mac_addr}=    Get Mac Address    @{DHCP_IPS}[0]
    : FOR    ${table}    IN    @{NETWORK_FLOWS}
    \    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep ${table}    30s
    \    Log    ${output}
    \    Should Contain    ${output}    ${mac_addr}

Create Subnets For l2_network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_2    l2_subnet_2    @{SUBNETS_RANGE}[1]

Verify Created Network l2_network_2
    [Documentation]    Gateway is enabled here, so the consecutive ip will be assigned for the network.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int    30s
    Log    ${output}
    Should Contain    ${output}    @{DHCP_IPS}[1]
    ${mac_addr}=    Get Mac Address    @{DHCP_IPS}[1]
    : FOR    ${table}    IN    @{NETWORK_FLOWS}
    \    ${output}=    Write Commands Until Prompt    sudo ovs-ofctl -O OpenFlow13 dump-flows br-int | grep ${table}    30s
    \    Log    ${output}
    \    Should Contain    ${output}    ${mac_addr}

Create Vm Instances For l2_network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Verify Created Vm Instance In l2_network_2
    [Documentation]    Verify the created vm instance entry in the dump flow.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${ip}    IN    @{NET_1_VM_IPS}
    \    ${mac_addr}=    Get Mac Address    ${ip}
    \    Verify VM With Dump Flows    ${mac_addr}    @{VM_FLOWS}

Create Vm Instances For l2_network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_2    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Verify Created Vm Instance In l2_network_2
    [Documentation]    Verify the created vm instance entry in the dump flow.
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    : FOR    ${ip}    IN    @{NET_2_VM_IPS}
    \    ${mac_addr}=    Get Mac Address    ${ip}
    \    Verify VM With Dump Flows    ${mac_addr}    @{VM_FLOWS}

Delete Vm Instances In l2_network_1
    [Documentation]    Delete Vm instances using instance names in l2_network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In l2_network_2
    [Documentation]    Delete Vm instances using instance names in l2_network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Sub Networks In l2_network_1
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_1

Delete Sub Networks In l2_network_2
    [Documentation]    Delete Sub Nets for the Networks with neutron request.
    Delete SubNet    l2_subnet_2

Delete Networks
    [Documentation]    Delete Networks with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Delete Network    ${NetworkElement}
