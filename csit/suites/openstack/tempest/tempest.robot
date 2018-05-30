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
tempest.api.network.admin.test_agent_management.AgentManagementTestJSON.test_list_agent
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_agent_management.AgentManagementTestJSON.test_list_agents_non_admin
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_agent_management.AgentManagementTestJSON.test_show_agent
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_agent_management.AgentManagementTestJSON.test_update_agent_description
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_agent_management.AgentManagementTestJSON.test_update_agent_status
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_create_router_setting_project_id
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers_dvr.RoutersTestDVR.test_centralized_router_creation
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsTestJSON.test_create_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers_dvr.RoutersTestDVR.test_distributed_router_creation
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_network_extension.ExternalNetworksTestJSON.test_create_external_network
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_create_router_with_default_snat_value
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_networks_negative.ExternalNetworksAdminNegativeTestJSON.test_create_port_with_precreated_floatingip_as_fixed_ip
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsTestJSON.test_list_ports_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_dhcp_agent_scheduler.DHCPAgentSchedulersTestJSON.test_add_remove_network_from_dhcp_agent
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_dhcp_agent_scheduler.DHCPAgentSchedulersTestJSON.test_list_dhcp_agent_hosting_network
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_dhcp_agent_scheduler.DHCPAgentSchedulersTestJSON.test_list_networks_hosted_by_one_dhcp
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsTestJSON.test_show_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsTestJSON.test_update_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_all_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_network_extension.ExternalNetworksTestJSON.test_delete_external_networks_with_floating_ip
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_network_extension.ExternalNetworksTestJSON.test_list_external_networks
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_create_router_with_snat_explicit
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_floating_ips_admin_actions.FloatingIPAdminTestJSON.test_create_list_show_floating_ip_with_tenant_id_by_admin
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers_negative.RoutersAdminNegativeTest.test_router_set_gateway_used_ip_returns_409
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_network_extension.ExternalNetworksTestJSON.test_show_external_networks_attribute
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_default_gw
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips_negative.FloatingIPNegativeTestJSON.test_associate_floatingip_port_ext_net_unreachable
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips_negative.FloatingIPNegativeTestJSON.test_create_floatingip_in_private_network
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_external_network_extension.ExternalNetworksTestJSON.test_update_external_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsTest.test_bulk_create_delete_network
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_update_router_reset_gateway_without_snat
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_negative_quotas.QuotasNegativeTest.test_network_quota_exceeding
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips_negative.FloatingIPNegativeTestJSON.test_create_floatingip_with_port_ext_net_unreachable
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_dhcp_enabled
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_floating_ips_admin_actions.FloatingIPAdminTestJSON.test_list_floating_ips_from_admin_and_nonadmin
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_quotas.QuotasTest.test_quotas
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_gw
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_update_router_set_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsTest.test_bulk_create_delete_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_gw_and_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairIpV6TestJSON.test_create_list_port_with_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_update_router_set_gateway_with_snat_explicit
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_with_host_routes_and_dns_nameservers
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairIpV6TestJSON.test_update_port_with_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsTest.test_bulk_create_delete_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers_negative.RoutersAdminNegativeIpV6Test.test_router_set_gateway_used_ip_returns_409
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_delete_subnet_without_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_update_router_set_gateway_without_snat
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_list_subnet_with_no_gw64_one_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairIpV6TestJSON.test_update_port_with_cidr_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcp_stateful
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersIpV6AdminTest.test_update_router_unset_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_update_delete_network_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairIpV6TestJSON.test_update_port_with_multiple_ip_mac_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_extra_dhcp_options.ExtraDHCPOptionsIpV6TestJSON.test_create_list_port_with_extra_dhcp_options
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6TestAttrs.test_create_delete_slaac_subnet_with_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_create_update_network_description
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsIpV6TestJSON.test_create_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.test_extra_dhcp_options.ExtraDHCPOptionsIpV6TestJSON.test_update_show_port_with_extra_dhcp_options
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsIpV6TestJSON.test_list_ports_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsIpV6TestJSON.test_show_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_delete_network_with_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6TestAttrs.test_create_delete_stateless_subnet_with_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_external_network_visibility
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_list_networks
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_list_networks_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_list_subnets
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_list_subnets_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_show_network
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_ports.PortsAdminExtendedAttrsIpV6TestJSON.test_update_port_binding_ext_attr
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_show_network_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_show_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_show_subnet_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_create_port_on_non_existent_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_delete_non_existent_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_delete_non_existent_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_delete_non_existent_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_show_non_existent_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_show_non_existent_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_show_non_existent_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_bulk_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_update_non_existent_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_update_non_existent_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks_negative.NetworksNegativeTestJSON.test_update_non_existent_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6TestAttrs.test_create_delete_subnet_with_v6_attributes_slaac
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_create_router_setting_project_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairTestJSON.test_create_list_port_with_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcp_stateful_fixedips
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_port_in_allowed_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6TestAttrs.test_create_delete_subnet_with_v6_attributes_stateful
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairTestJSON.test_update_port_with_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_add_multiple_router_interfaces
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6Test.test_update_subnet_gw_dns_host_routes_dhcp
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_create_router_with_default_snat_value
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairTestJSON.test_update_port_with_cidr_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksIpV6TestAttrs.test_create_delete_subnet_with_v6_attributes_stateless
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcp_stateful_fixedips_duplicate
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcp_stateful_fixedips_outrange
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_create_router_with_snat_explicit
    ${TEST_NAME}    debug=True

tempest.api.network.test_allowed_address_pair.AllowedAddressPairTestJSON.test_update_port_with_multiple_ip_mac_address_pair
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_port_with_no_securitygroups
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_add_remove_router_interface_with_port_id
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_update_router_reset_gateway_without_snat
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_show_delete_port_user_defined_mac
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.DvrRoutersNegativeTest.test_router_create_tenant_distributed_returns_forbidden
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_update_delete_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_extensions.ExtensionsTestJSON.test_list_show_extensions
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_list_update_show_delete_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_update_router_set_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_security_group_rule_with_additional_args
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_add_remove_router_interface_with_subnet_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_security_group_rule_with_icmp_type_code
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_security_group_rule_with_protocol_integer_value
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_update_router_set_gateway_with_snat_explicit
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_create_show_list_update_delete_router
    ${TEST_NAME}    debug=True

tempest.api.network.test_extra_dhcp_options.ExtraDHCPOptionsTestJSON.test_create_list_port_with_extra_dhcp_options
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcp_stateful_router
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_security_group_rule_with_remote_group_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_extra_dhcp_options.ExtraDHCPOptionsTestJSON.test_update_show_port_with_extra_dhcp_options
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_bulk_port
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_update_router_set_gateway_without_snat
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_security_group_rule_with_remote_ip_prefix
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_create_update_port_with_second_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_list_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_create_show_delete_security_group_rule
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_list_ports_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupIPv6Test.test_list_security_groups
    ${TEST_NAME}    debug=True

tempest.api.network.admin.test_routers.RoutersAdminTest.test_update_router_unset_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_additional_default_security_group_fails
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_port_in_allowed_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_duplicate_security_group_rule_fails
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_router_interface_port_update_with_fixed_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_bad_ethertype
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_bad_protocol
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_bad_remote_ip_prefix
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsIpV6Test.test_bulk_create_delete_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_invalid_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_port_list_filter_by_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_non_existent_remote_groupid
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_port_with_no_securitygroups
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_with_remote_ip_and_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_show_delete_port_user_defined_mac
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsIpV6Test.test_bulk_create_delete_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_rule_wrong_ip_prefix_version
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_create_security_group_update_name_default
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_delete_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_show_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupIPv6Test.test_show_non_existent_security_group_rule
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips.FloatingIPTestJSON.test_create_floating_ip_specifying_a_fixed_ip_address
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_update_delete_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips.FloatingIPTestJSON.test_create_list_show_update_delete_floating_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.BulkNetworkOpsIpV6Test.test_bulk_create_delete_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_port_list_filter_by_router_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_show_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_show_port_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips.FloatingIPTestJSON.test_create_update_floatingip_with_port_multiple_ip_address
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_64_subnets
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_create_update_port_with_second_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_list_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_list_ports_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_invalid_options
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_update_port_with_security_group_and_extra_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_update_delete_extra_route
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips.FloatingIPTestJSON.test_floating_ip_delete_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersTest.test_update_router_admin_state
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_port_list_filter_by_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_add_router_interfaces_on_overlapping_subnets_returns_400
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_delete_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_router_add_gateway_invalid_network_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_router_add_gateway_net_not_external_returns_400
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_stateless_eui64
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_router_remove_interface_in_use_returns_409
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_show_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeIpV6Test.test_update_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_floating_ips.FloatingIPTestJSON.test_floating_ip_update_different_router
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsTestJSON.test_update_port_with_two_security_groups_and_extra_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_port_list_filter_by_router_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_show_port
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_show_port_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_stateless_no_ra
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_stateless_no_ra_no_dhcp
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_update_port_with_security_group_and_extra_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_add_router_interfaces_on_overlapping_subnets_returns_400
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_delete_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_router_add_gateway_invalid_network_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_additional_default_security_group_fails
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_router_add_gateway_net_not_external_returns_400
    ${TEST_NAME}    debug=True

tempest.api.network.test_ports.PortsIpV6TestJSON.test_update_port_with_two_security_groups_and_extra_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_duplicate_security_group_rule_fails
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_bad_ethertype
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_bad_protocol
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_bad_remote_ip_prefix
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_invalid_ports
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_router_remove_interface_in_use_returns_409
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_show_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers_negative.RoutersNegativeTest.test_update_non_existent_router_returns_404
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_non_existent_remote_groupid
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_rule_with_remote_ip_and_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_create_security_group_update_name_default
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_delete_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_show_non_existent_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups_negative.NegativeSecGroupTest.test_show_non_existent_security_group_rule
    ${TEST_NAME}    debug=True

tempest.api.network.test_versions.NetworksApiDiscovery.test_api_version_resources
    ${TEST_NAME}    debug=True

tempest.api.network.test_service_providers.ServiceProvidersTest.test_service_providers_list
    ${TEST_NAME}    debug=True

tempest.api.network.test_subnetpools_extensions.SubnetPoolsTestJSON.test_create_list_show_update_delete_subnetpools
    ${TEST_NAME}    debug=True

tempest.api.network.test_dhcp_ipv6.NetworksTestDHCPv6.test_dhcpv6_two_subnets
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_add_multiple_router_interfaces
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_add_remove_router_interface_with_port_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_all_attributes
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_add_remove_router_interface_with_subnet_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_with_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_create_show_list_update_delete_router
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_with_dhcp_enabled
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_with_gw
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_router_interface_port_update_with_fixed_ip
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_with_gw_and_allocation_pools
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_with_host_routes_and_dns_nameservers
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_delete_subnet_without_gateway
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_update_delete_network_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_create_update_network_description
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_delete_network_with_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_external_network_visibility
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_list_networks
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_list_networks_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_list_subnets
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_list_subnets_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_show_network
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_show_network_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_show_subnet
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_show_subnet_fields
    ${TEST_NAME}    debug=True

tempest.api.network.test_networks.NetworksTest.test_update_subnet_gw_dns_host_routes_dhcp
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_update_delete_extra_route
    ${TEST_NAME}    debug=True

tempest.api.network.test_routers.RoutersIpV6Test.test_update_router_admin_state
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_list_update_show_delete_security_group
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_security_group_rule_with_additional_args
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_security_group_rule_with_icmp_type_code
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_security_group_rule_with_protocol_integer_value
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_security_group_rule_with_remote_group_id
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_security_group_rule_with_remote_ip_prefix
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_create_show_delete_security_group_rule
    ${TEST_NAME}    debug=True

tempest.api.network.test_security_groups.SecGroupTest.test_list_security_groups
    ${TEST_NAME}    debug=True

tempest.api.network.test_tags.TagsTest.test_create_list_show_update_delete_tags
    ${TEST_NAME}    debug=True

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

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_slaac_from_os
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
