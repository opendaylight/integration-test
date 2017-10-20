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
    [Template]    NONE
    # with the migration to using "python -m testtools.run" we have to discover the api.network tests for some
    # reason. Because we are using ${tempest_dir} as a variable, that will not expand if it's given in the actual
    # test case name. So instead we have to disable the [Template] and call it directly in the body of the
    # test case. However, this is not a problem for the scenario tests.
    DevstackUtils.Run Tempest Tests    discover ${tempest_dir}/tempest/api/network    ${blacklist_file}    ${tempest_config_file}    timeout=900s

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_hotplug_nic
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}
