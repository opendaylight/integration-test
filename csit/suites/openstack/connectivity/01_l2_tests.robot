*** Settings ***
Documentation     Test suite to verify packet flows between vm instances.
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/DataModels.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Variables ***
@{NETWORKS_NAME}    l2_network_1    l2_network_2
@{SUBNETS_NAME}    l2_subnet_1    l2_subnet_2
@{NET_1_VM_INSTANCES}    MyFirstInstance_1    MySecondInstance_1    MyThirdInstance_1
@{NET_2_VM_INSTANCES}    MyFirstInstance_2    MySecondInstance_2    MyThirdInstance_2
@{SUBNETS_RANGE}    30.0.0.0/24    40.0.0.0/24
${network1_vlan_id}    1235

*** Test Cases ***
Create Networks
    [Documentation]    Create Network with neutron request.
    Create Network    net1
    Create Network    net2
    Create Network    net3
    Create Network    net4
    Create Network    net5
    Create Network    net7
    Create Network    net8
    Create Network    net9

Create Subnet 1
    Create SubNet1    net1    subnet1    30.0.0.0/24

Create Subnet 2
    Create SubNet2    net2    subnet2    40.0.0.0/24

Create Subnet 3
    Create SubNet3    net3    subnet3    50.0.0.0/24

Create Subnet 4
    Create SubNet1    net4    subnet4    60.0.0.0/24

Create Subnet 5
    Create SubNet2    net5    subnet5    70.0.0.0/24

Create Subnet 6
    Create SubNet3    net6    subnet6    80.0.0.0/24

Create Subnet 7
    Create SubNet1    net7    subnet7    90.0.0.0/24

Create Subnet 8
    Create SubNet2    net8    subnet8    100.0.0.0/24

Create Subnet 9
    Create SubNet3    net9    subnet9    110.0.0.0/24
