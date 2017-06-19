*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Tempest.Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
Test Template     Tempest.Run Tempest Tests
Library           OperatingSystem
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/Tempest.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/netvirt/Variables.robot

*** Test Cases ***
tempest.api.network
    ${TEST_NAME}    debug=False    timeout=1200s

tempest.scenario.test_aggregates_basic_ops.TestAggregatesBasicOps.test_aggregate_basic_ops
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_pause_unpause
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_reboot
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_stop_start
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_suspend_resume
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_connectivity_between_vms_on_different_networks
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_hotplug_nic
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_mtu_sized_frames
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_network_basic_ops
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_port_security_macspoofing_port
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_preserve_preexisting_port
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_router_rescheduling
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_subnet_details
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_dhcp6_stateless_from_os
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_dhcp6_stateless_from_os
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_multi_prefix_dhcpv6_stateless
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_multi_prefix_slaac
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_slaac_from_os
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_multi_prefix_slaac
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_multi_prefix_dhcpv6_stateless
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_slaac_from_os
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_boot_into_disabled_port_security_network_without_secgroup
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_cross_tenant_traffic
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_in_tenant_traffic
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_multiple_security_groups
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_port_security_disable_security_group
    ${TEST_NAME}    debug=True

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps.test_port_update_new_security_group
    ${TEST_NAME}    debug=True

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    debug=True

tempest.scenario.test_network_v6.TestGettingAddress.test_slaac_from_os
    ${TEST_NAME}    debug=True
