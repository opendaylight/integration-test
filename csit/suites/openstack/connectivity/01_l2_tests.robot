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
@{NET_1_VM_IPS}
@{NET_2_VM_IPS}
@{VM_IPS_NOT_DELETED}    30.0.0.4    30.0.0.5
@{GATEWAY_IPS}    30.0.0.1    40.0.0.1
@{DHCP_IPS}       30.0.0.2    40.0.0.2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For l2_network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_1    l2_subnet_1    @{SUBNETS_RANGE}[0]

Create Subnets For l2_network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    l2_network_2    l2_subnet_2    @{SUBNETS_RANGE}[1]

Create Vm Instances List For Network l2_network_1
    [Documentation]    Reads number of limited vm instances and returns a list with all vm instances names.
    ${NET_1_VM_INSTANCES}    Create List
    ${LIMIT_TEST_VM_INSTANCES_PER_NW}=    Convert to Integer    ${LIMIT_TEST_VM_INSTANCES_PER_NW}
    : FOR    ${i}    IN RANGE    ${LIMIT_TEST_VM_INSTANCES_PER_NW}
    \    Append To List    ${NET_1_VM_INSTANCES}    l2_instance_net_1_${i+1}
    Set Suite Variable    ${NET_1_VM_INSTANCES}
    Log    ${NET_1_VM_INSTANCES}

Create Vm Instances For l2_network_1
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}
    ${NET_1_VM_IPS}=    Get Vm Instance Ip    ${NET_1_VM_INSTANCES}    ${NET_1_VM_IPS}
    Log    ${NET_1_VM_IPS}
    Set Suite Variable    ${NET_1_VM_IPS}
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Create Vm Instances List For Network l2_network_2
    [Documentation]    Reads number of limited vm instances and returns a list with all vm instances names.
    ${NET_2_VM_INSTANCES}    Create List
    ${LIMIT_TEST_VM_INSTANCES_PER_NW}=    Convert to Integer    ${LIMIT_TEST_VM_INSTANCES_PER_NW}
    : FOR    ${i}    IN RANGE    ${LIMIT_TEST_VM_INSTANCES_PER_NW}
    \    Append To List    ${NET_2_VM_INSTANCES}    l2_instance_net_2_${i+1}
    Set Suite Variable    ${NET_2_VM_INSTANCES}
    Log    ${NET_2_VM_INSTANCES}

Create Vm Instances For l2_network_2
    [Documentation]    Create Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_2    ${NET_2_VM_INSTANCES}
    ${NET_2_VM_IPS}=    Get Vm Instance Ip    ${NET_2_VM_INSTANCES}    ${NET_2_VM_IPS}
    Log    ${NET_2_VM_IPS}
    Set Suite Variable    ${NET_2_VM_IPS}
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Ping Vm Instances In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_1    ${NET_1_VM_IPS}

Ping Vm Instances In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Ping Vm From DHCP Namespace    l2_network_2    ${NET_2_VM_IPS}

Connectivity Tests From Vm Instances In l2_network_1
    [Documentation]    Logging to the vm instances in l2_network_1
    : FOR    ${vm_instance}    IN    @{NET_1_VM_INSTANCES}
    \    Connectivity Tests From A Vm Instance    l2_network_1    ${vm_instance}    @{NET_1_VM_IPS}    @{DHCP_IPS}[0]

Connectivity Tests From Vm Instance1 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}

Connectivity Tests From Vm Instance2 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}

Connectivity Tests From Vm Instance3 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    @{NET_1_VM_INSTANCES}[0]

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]

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
