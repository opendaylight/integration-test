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
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}    timeout=900s

tempest.scenario.test_aggregates_basic_ops.TestAggregatesBasicOps.test_aggregate_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_pause_unpause
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_reboot
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_stop_start
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_suspend_resume
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_connectivity_between_vms_on_different_networks
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_hotplug_nic
    [Tags]    skip_if_stable/mitaka
    # Failing due to default security rules behavior missing in Mitaka
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_mtu_sized_frames
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_network_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_port_security_macspoofing_port
    [Tags]    skip_if_transparent    skip_if_stable/mitaka
    # Failing due to default security rules behavior missing in Mitaka, and also in all transparent runs
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_preserve_preexisting_port
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_router_rescheduling
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_subnet_details
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dhcp6_stateless_from_os
    [Tags]    skip_if_transparent    skip_if_learn
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_dhcp6_stateless_from_os
    [Tags]    skip_if_transparent    skip_if_learn
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_slaac_from_os
    [Tags]    skip_if_transparent    skip_if_learn
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_slaac_from_os
    [Tags]    skip_if_transparent    skip_if_learn
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps
    [Tags]    skip_if_transparent    skip_if_learn
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}    timeout=900s

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}
