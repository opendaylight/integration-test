*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Start Suite
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     BuiltIn.Run Keywords    OpenStackOperations.Get Test Teardown Debugs
Test Template     DevstackUtils.Run Tempest Tests
Library           OperatingSystem
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Keywords ***
Start Suite
    DevstackUtils.Log In To Tempest Executor And Setup Test Environment
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set TRACE org.opendaylight.genius

*** Test Cases ***
tempest.api.network
    ${TEST_NAME}    debug=False    timeout=1200s
