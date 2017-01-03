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
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Change Quotas
    Update Quota To Create More Nets

Create Networks and Subnets 1
    [Documentation]    Create 100 Nets and Subnets
    : FOR    ${INDEX}    IN RANGE     1     100
    \    Create Network    NET_${INDEX}
    \    Create SubNet    NET_${INDEX}    l2_subnet_${INDEX}     ${INDEX}.0.0.0/24
    \    Create Network    NET_${INDEX}_${INDEX}
    \    Create SubNet    NET_${INDEX}    l2_subnet_${INDEX}     ${INDEX}.${INDEX}.0.0/24
    \    Create Network    NET_${INDEX}_${INDEX}_${INDEX}
    \    Create SubNet    NET_${INDEX}    l2_subnet_${INDEX}     ${INDEX}.${INDEX}.${INDEX}.0/24
    \    Sleep     5s

Delete Networks
    [Documentation]    Delete All Networks
    : FOR    ${INDEX}    IN RANGE     1     100
    \    Delete Network     NET_${INDEX} 
    \    Delete Network     NET_${INDEX}_${INDEX}
    \    Delete Network     NET_${INDEX}_${INDEX}_${INDEX}
    \    Sleep     5s

Just Sleep
    Sleep     300s
