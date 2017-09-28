*** Settings ***
Documentation     Test suite for running a single tempest. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       DevstackUtils.Log In To Tempest Executor And Setup Test Environment
Suite Teardown    DevstackUtils.Clean Up After Running Tempest
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keywords    Get Test Teardown Debugs
Library           OperatingSystem
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot

*** Test Cases ***
Run Single Tempest Test
    [Documentation]    Run a single tempest test
    DevstackUtils.Run Tempest Tests With Debug    ${TEMPEST_TEST}    ${blacklist_file}    ${tempest_config_file}    timeout=900s
