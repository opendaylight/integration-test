*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests
Suite Teardown    Close All Connections
Test Setup        Log Testcase Start To Controller Karaf
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

Add Ssh Allow Rule
    [Documentation]    Allow all TCP packets for testing
    Create Security Group      csit    "CSIT SSH Allow"
    Create Security Rule     ingress      tcp     1     65535     0.0.0.0/0      csit
    Create Security Rule     egress       tcp     1     65535     0.0.0.0/0      csit

Create Vm Instances For l2_network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_1    ${NET_1_VM_INSTANCES}     sg=csit
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Create Vm Instances For l2_network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    Create Vm Instances    l2_network_2    ${NET_2_VM_INSTANCES}     sg=csit
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}
    Get OvsDebugInfo

Ping Vm Instance1 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_1    @{NET_1_VM_IPS}[0]
    Get OvsDebugInfo

Ping Vm Instance2 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_1    @{NET_1_VM_IPS}[1]
    Get OvsDebugInfo

Ping Vm Instance3 In l2_network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_1    @{NET_1_VM_IPS}[2]
    Get OvsDebugInfo

Ping Vm Instance1 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_2    @{NET_2_VM_IPS}[0]
    Get OvsDebugInfo

Ping Vm Instance2 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_2    @{NET_2_VM_IPS}[1]
    Get OvsDebugInfo

Ping Vm Instance3 In l2_network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    Get OvsDebugInfo
    Ping Vm From DHCP Namespace    l2_network_2    @{NET_2_VM_IPS}[2]
    Get OvsDebugInfo

Connectivity Tests From Vm Instance1 In l2_network_1
    [Documentation]    Logging to the vm instance1
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[1]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_1    @{NET_1_VM_IPS}[0]    ${dst_ip_list}
    Get OvsDebugInfo

Connectivity Tests From Vm Instance2 In l2_network_1
    [Documentation]    Logging to the vm instance2
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_1    @{NET_1_VM_IPS}[1]    ${dst_ip_list}
    Get OvsDebugInfo

Connectivity Tests From Vm Instance3 In l2_network_1
    [Documentation]    Logging to the vm instance2
    ${dst_ip_list}=    Create List    @{NET_1_VM_IPS}[0]    @{DHCP_IPS}[0]    @{NET_1_VM_IPS}[1]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_1    @{NET_1_VM_IPS}[2]    ${dst_ip_list}
    Get OvsDebugInfo

Connectivity Tests From Vm Instance1 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[1]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[0]    ${dst_ip_list}
    Get OvsDebugInfo

Connectivity Tests From Vm Instance2 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[2]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[1]    ${dst_ip_list}
    Get OvsDebugInfo

Connectivity Tests From Vm Instance3 In l2_network_2
    [Documentation]    Logging to the vm instance using generated key pair.
    ${dst_ip_list}=    Create List    @{NET_2_VM_IPS}[0]    @{DHCP_IPS}[1]    @{NET_2_VM_IPS}[1]
    Log    ${dst_ip_list}
    Get OvsDebugInfo
    Test Operations From Vm Instance    l2_network_2    @{NET_2_VM_IPS}[2]    ${dst_ip_list}
    Get OvsDebugInfo

Delete A Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    Get OvsDebugInfo
    ${output}=    Ping From DHCP Should Not Succeed    l2_network_1    @{NET_1_VM_IPS}[0]
    Get OvsDebugInfo

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
    Get OvsDebugInfo
