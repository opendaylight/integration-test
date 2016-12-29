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
Stop Ovs Test1
    [Documentation]    Create Network with neutron request.
        Set Log Level in All ODL Nodes       openflowplugin    TRACE
        Stop And Start Ovs Wrapper
        Set Log Level in All ODL Nodes       openflowplugin    INFO

Stop Ovs Test2
    [Documentation]    Create Network with neutron request.
        Set Log Level in All ODL Nodes       openflowplugin    TRACE
        Stop And Start Ovs Wrapper
        Set Log Level in All ODL Nodes       openflowplugin    INFO
