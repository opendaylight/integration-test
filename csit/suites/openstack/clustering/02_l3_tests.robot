*** Settings ***
Documentation     Test suite to check connectivity in L3 using routers.
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
@{NET_1_VM_INSTANCES}    MyFirstInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2
@{NET_1_VM_IPS}    50.0.0.3
@{NET_2_VM_IPS}    60.0.0.3
@{GATEWAY_IPS}    50.0.0.1    60.0.0.1
@{DHCP_IPS}    50.0.0.2    60.0.0.2
@{controllers}    ${CONTROLLER}    ${CONTROLLER1}

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    : FOR    ${NetworkElement}    IN    @{NETWORKS_NAME}
    \    Create Network    ${NetworkElement}    devstack_path=/opt/stack/devstack

Create Subnets For network_1
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_1    subnet_1    50.0.0.0/24

Create Subnets For network_2
    [Documentation]    Create Sub Nets for the Networks with neutron request.
    Create SubNet    network_2    subnet_2    60.0.0.0/24

Take Down ODL1
    [Documentation]   Kill the karaf in First Controller
    Stop One Or More Controllers    ${CONTROLLER}
    Wait Until Keyword Succeeds    300s    3s    Controller Down Check    ${CONTROLLER}

Create Vm Instances For network_1
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_1
    Create Vm Instances    ${net_id}    ${NET_1_VM_INSTANCES}

Bring Up ODL1
    [Documentation]  Bring up ODL1 again
    Start One Or More Controllers       ${CONTROLLER}
    Wait For Controller Sync    300s    ${CONTROLLER}

Take Down ODL2
    [Documentation]   Kill the karaf in Second Controller
    Stop One Or More Controllers    ${CONTROLLER1}
    Wait Until Keyword Succeeds    300s    3s    Controller Down Check    ${CONTROLLER1}

Create Vm Instances For network_2
    [Documentation]    Create Four Vm instances using flavor and image names for a network.
    ${net_id}=    Get Net Id    network_2
    Set Suite Variable    ${net_id}
    Create Vm Instances    ${net_id}    ${NET_2_VM_INSTANCES}

Show Details of Created Vm Instance In network_1
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    ${output}=   Write Commands Until Prompt     nova show ${VmElement}
    \    Log    ${output}

Bring Up ODL2
    [Documentation]  Bring up ODL2 again
    Start One Or More Controllers       ${CONTROLLER1}
    Wait For Controller Sync    300s    ${CONTROLLER1}

Show Details of Created Vm Instance In network_2
    [Documentation]    View Details of the created vm instances using nova show.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    ${output}=   Write Commands Until Prompt     nova show ${VmElement}
    \    Log    ${output}

Take Down ODL3
    [Documentation]   Kill the karaf in Third Controller
    Stop One Or More Controllers    ${CONTROLLER2}
    Wait Until Keyword Succeeds    300s    3s    Controller Down Check    ${CONTROLLER2}

Create Routers
    [Documentation]    Create Router and Add Interface to the subnets.
    Create Router    router_1

Bring Up ODL3
    [Documentation]  Bring up ODL3 again
    Start One Or More Controllers       ${CONTROLLER2}
    Wait For Controller Sync    300s    ${CONTROLLER2}

Ping Vm Instance In network_2 From network_1
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    ${net_id}=    Get Net Id    network_1
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    60.0.0.3
    Should Contain    ${output}    64 bytes

Ping Vm Instance In network_1 From network_2
    [Documentation]    Check reachability of vm instances by pinging to them after creating routers.
    ${net_id}=    Get Net Id    network_2
    ${output}    Ping Vm From DHCP Namespace    ${net_id}    50.0.0.3
    Should Contain    ${output}    64 bytes

Take Down ODL1 and ODL2
    [Documentation]   Kill the karaf in First and Second Controller
    ${controllers}=    Create List    ${CONTROLLER}    ${CONTROLLER1}
    Set Suite Variable    ${controllers}    
    Log    ${controllers}
    : FOR    ${index}    IN    @{controllers}
    \    Stop One Or More Controllers    ${index}
    \    Wait Until Keyword Succeeds    300s    3s    Controller Down Check    ${index}

Add Key-Pair For Vm Instance
    [Documentation]    Creates key pair to ssh to the vm instance.
    ${output}=   Write Commands Until Prompt    nova keypair-add test > test2.pem
    Log    ${output}
    ${output}=   Write Commands Until Prompt    chmod 600 test2.pem
    Log    ${output}

List The Availalbe Key Pair List
    [Documentation]    Check the existing key pairs available.
    ${output}=   Write Commands Until Prompt    nova keypair-list
    Log    ${output}

Login to Vm Instances In network_1 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_1
    Ssh Vm Instance    ${net_id}    50.0.0.3    test2.pem

Ping Vm Instance From Instance In network_1
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    60.0.0.3
    Should Contain    ${output}    64 bytes

Ping Dhcp Server In network_2 From Instance In network_1
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    60.0.0.2
    Should Contain    ${output}    64 bytes

Close Vm Instance In network_1
    [Documentation]    Close the connection with Vm Instance in a network.
    Close Vm Instance

Bring Up ODL1 and ODL2
    [Documentation]  Bring up ODL1 and ODL2 again
    Log    ${controllers}
    : FOR    ${index}    IN    @{controllers}
    \    Start One Or More Controllers       ${index}
    \    Wait For Controller Sync    300s    ${index}

Take Down ODL2 and ODL3
    [Documentation]   Kill the karaf in First and Second Controller
    ${controllers}=    Create List    ${CONTROLLER1}    ${CONTROLLER2}
    Log    ${controllers}
    Set Suite Variable    ${controllers}
    : FOR    ${index}    IN    @{controllers}
    \    Stop One Or More Controllers    ${index}
    \    Wait Until Keyword Succeeds    300s    3s    Controller Down Check    ${index}

Login to Vm Instances In network_2 Using Ssh
    [Documentation]    Logging to the vm instance using generated key pair.
    ${net_id}=    Get Net Id    network_2
    Ssh Vm Instance    ${net_id}    60.0.0.3    test2.pem

Ping Vm Instance From Instance In network_2
    [Documentation]    Check reachability of vm instances by pinging.
    ${output}=    Ping From Instance    50.0.0.3
    Should Contain    ${output}    64 bytes

Ping Dhcp Server In network_1 From Instance In network_2
    [Documentation]    ping the dhcp server from instance.
    ${output}=    Ping From Instance    50.0.0.2
    Should Contain    ${output}    64 bytes

Close Vm Instance In network_2
    [Documentation]    Close the connection with Vm Instance in a network.
    Close Vm Instance

Bring Up ODL2 and ODL3
    [Documentation]  Bring up ODL2 and ODL3 again
    Log    ${controllers}
    : FOR    ${index}    IN    @{controllers}
    \    Start One Or More Controllers       ${index}
    \    Wait For Controller Sync    300s    ${index}

Delete Vm Instances In network_1
    [Documentation]    Delete Vm instances using instance names in network_1.
    : FOR    ${VmElement}    IN    @{NET_1_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Vm Instances In network_2
    [Documentation]    Delete Vm instances using instance names in network_2.
    : FOR    ${VmElement}    IN    @{NET_2_VM_INSTANCES}
    \    Delete Vm Instance    ${VmElement}

Delete Router Interfaces
    [Documentation]    Remove Interface to the subnets.
    Remove Interface    router_1

Delete Routers
    [Documentation]    Delete Router and Interface to the subnets.
    Delete Router    router_1

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
