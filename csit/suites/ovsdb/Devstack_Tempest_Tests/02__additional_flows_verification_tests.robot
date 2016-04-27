*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/DevstackUtils.robot

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

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    30.0.0.0/24

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_2    subnet_2    40.0.0.0/24

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}
    View Vm Console    ${NET_1_VM_INSTANCES}

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}
    View Vm Console    ${NET_2_VM_INSTANCES}

List Networks With Namespaces
    ${output}=    Write Commands Until Prompt    sudo ip netns list
    Log    ${output}

Show Details of Created Vm Instance In network_1
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    \    Log    ${output}

Ping All Vm Instances In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_1
    : FOR    ${VmIpElement}    IN    @{NET_1_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Show Details of Created Vm Instance In network_2
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    ${output}=    Write Commands Until Prompt    nova show ${VmElement}
    \    Log    ${output}

Ping All Vm Instances In network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_2
    : FOR    ${VmIpElement}    IN    @{NET_2_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Add Key-Pair For Vm Instance
    [Documentation]    Creates key pair to ssh to the vm instance.
    ${output}=    Write Commands Until Prompt    nova keypair-add test > test.pem
    Log    ${output}
    ${output}=    Write Commands Until Prompt    chmod 600 test.pem
    Log    ${output}

List The Availalbe Key Pair List
    [Documentation]    Check the existing key pairs available.
    ${output}=    Write Commands Until Prompt    nova keypair-list
    Log    ${output}

Login to Vm Instances In network_1 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_1
    Ssh Vm Instance    ${net_id}    30.0.0.3

Ping Vm Instance From Instance In network_1
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    30.0.0.4
    Should Contain    ${output}    64 bytes

Ping Dhcp Server From Instance In network_1
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    30.0.0.2
    Should Contain    ${output}    64 bytes

Ping Metadata Server From Instance In network_1
    [Documentation]    ping the metadata server from instance.
    Curl Metadata Server

Close Vm Instance In network_1
    [Documentation]    Close the connection with Vm Instance in a network.
    Close Vm Instance

Login to Vm Instances In network_2 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_2
    Ssh Vm Instance    ${net_id}    40.0.0.3

Ping Vm Instance From Instance In network_2
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    40.0.0.4
    Should Contain    ${output}    64 bytes

Ping Dhcp Server From Instance In network_2
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    40.0.0.2
    Should Contain    ${output}    64 bytes

Ping Metadata Server From Instance In network_2
    [Documentation]    ping the metadata server from instance.
    Curl Metadata Server

Close Vm Instance In network_2
    [Documentation]    Close the connection with Vm Instance in a network.
    Close Vm Instance

Delete Vm Instance
    [Documentation]    Delete Vm instances using instance names.
    Delete Vm Instance    MyFirstInstance_1

Ping All Vm Instances
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_1
    : FOR    ${VmIpElement}    IN    @{VM_IPS_NOT_DELETED}
    \    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

No Ping For Deleted Vm
    [Documentation]    Check non reachability of deleted vm instances by pinging to them.
    ${output}=    Ping Vm From DHCP Namespace    ${net_id}    30.0.0.3
    Should Contain    ${output}    Destination Host Unreachable

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

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
