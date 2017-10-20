*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       DevstackUtils.Log In To Tempest Executor And Setup Test Environment
Suite Teardown    DevstackUtils.Clean Up After Running Tempest
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Run Keywords    Get Test Teardown Debugs
Test Template     DevstackUtils.Run Tempest Tests
Library           OperatingSystem
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Variables         ../../../variables/Variables.py
Resource          ../../../variables/netvirt/Variables.robot

*** Test Cases ***
tempest.api.network
    ${TEST_NAME}    debug=False     timeout=600s

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_hotplug_nic
    ${TEST_NAME}    debug=True

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    debug=True
