*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       Devstack Suite Setup Tests
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
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

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
    [Teardown]    Show Debugs    ${NET_1_VM_INSTANCES}

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}
    [Teardown]    Show Debugs    ${NET_2_VM_INSTANCES}

Ping All Vm Instances In network_1
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_1
    : FOR    ${VmIpElement}    IN    @{NET_1_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Ping All Vm Instances In network_2
    [Documentation]    Check reachability of vm instances by pinging to them.
    ${net_id}=    Get Net Id    network_2
    : FOR    ${VmIpElement}    IN    @{NET_2_VM_IPS}
    \    ${output}    Ping Vm From DHCP Namespace    ${net_id}    ${VmIpElement}
    \    Should Contain    ${output}    64 bytes

Get DumpFlows network_2
    [Documentation]    Check the dump-flows.
    Verify Dhcp Ips

Login to Vm Instances In network_1 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_1
    Ssh Vm Instance    ${net_id}    30.0.0.3

Ping Vm Instance From Instance In network_1
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    30.0.0.4
    Should Contain    ${output}    64 bytes

Get DumpFlows Instance In network_1
    [Documentation]    Check the dump-flows.
    Verify Dhcp Ips

Ping Dhcp Server From Instance In network_1
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    30.0.0.2
    Should Contain    ${output}    64 bytes

Get DumpFlows Server From Instance In network_1
    [Documentation]    Check the dump-flows.
    Get DumpFlows And Ovsconfig     ${OS_CONTROL_NODE_IP}

Ping Metadata Server From Instance In network_1
    [Documentation]    ping the metadata server from instance.
    Curl Metadata Server

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
