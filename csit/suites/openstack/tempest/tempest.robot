*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Setup Test Environment
Suite Teardown    Clean Up After Running Tempest
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

*** Variables ***
${blacklist_file}    /tmp/blacklist.txt
@{stable/mitaka_exclusion_regexes}    test_routers_negative.RoutersNegativeIpV6Test.test_router_set_gateway_used_ip_returns_409    test_routers_negative.RoutersNegativeTest.test_router_set_gateway_used_ip_returns_409
@{stable/newton_exclusion_regexes}    ${EMPTY}
@{stable/ocata_exclusion_regexes}    ${EMPTY}
${tempest_config_file}    /opt/stack/tempest/etc/tempest.conf
${external_physical_network}    physnet1
${external_net_name}    external-net
${external_subnet_name}    external-subnet
# Parameter values below are based on releng/builder - changing them requires updates in releng/builder as well
${external_gateway}    10.10.10.250
${external_subnet_allocation_pool}    start=10.10.10.2,end=10.10.10.249
${external_subnet}    10.10.10.0/24

*** Test Cases ***
tempest.api.network
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}    timeout=900s

tempest.scenario.test_security_groups_basic_ops.TestSecurityGroupsBasicOps
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}    timeout=900s

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

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_preserve_preexisting_port
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_router_rescheduling
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_subnet_details
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_aggregates_basic_ops.TestAggregatesBasicOps.test_aggregate_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_pause_unpause
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_stop_start
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_reboot
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_suspend_resume
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_port_security_macspoofing_port
    [Tags]    skip_if_transparent    skip_if_stable/mitaka
    # Failing due to default security rules behavior missing in Mitaka, and also in all transparent runs
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_dhcp6_stateless_from_os
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dualnet_slaac_from_os
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_dhcp6_stateless_from_os
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

tempest.scenario.test_network_v6.TestGettingAddress.test_slaac_from_os
    ${TEST_NAME}    ${blacklist_file}    ${tempest_config_file}

*** Keywords ***
Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests. The (sometimes empty) tempest blacklist file will be created
    ...    and pushed to the tempest executor.
    Create Blacklist File
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    # source_pwd is expected to exist in the below Create Network, Create Subnet keywords.    Might be a bug.
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    # Tempest tests need an existing external network in order to create routers.
    Create Network    ${external_net_name}    --external --default --provider-network-type flat --provider-physical-network ${PUBLIC_PHYSICAL_NETWORK}
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway} --allocation-pool ${external_subnet_allocation_pool}
    List Networks
    ${control_node_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    SSHKeywords.Flexible SSH Login    ${OS_USER}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    sudo rm -rf /opt/stack/tempest/.testrepository
    ${net_id}=    Get Net Id    ${external_net_name}    ${control_node_conn_id}
    Tempest Conf Add External Network    ${net_id}

Tempest Conf Add External Network
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file - this function will add the
    ...    given external network ID to the configuration file.
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    network    public_network_id    ${external_network_id}
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    debug    False
    Modify Config In File On Existing SSH Connection    ${tempest_config_file}    set    DEFAULT    log_level    INFO
    Write Commands Until Prompt    sudo cat ${tempest_config_file}
    Write Commands Until Prompt    sudo chmod 777 ${tempest_config_file}

Modify Config In File On Existing SSH Connection
    [Arguments]    ${config_file}    ${modifier}    ${config_section}    ${config_key}    ${config_value}=${EMPTY}
    [Documentation]    uses crudini to populate oslo cofg file.
    # this keyword is only one line so seems like extra overhead, but this may be a good candidate to move
    # to a library at some point, when/if other suites need to use it, so wanted to make it generic.
    Write Commands Until Prompt    sudo -E crudini --${modifier} ${config_file} ${config_section} ${config_key} ${config_value}

Clean Up After Running Tempest
    [Documentation]    Clean up any extra leftovers that were created to allow tempest tests to run.
    Delete Network    ${external_net_name}
    List Networks
    Close All Connections

Create Blacklist File
    [Documentation]    For each exclusion regex in the required @{${OPENSTACK_BRANCH}_exclusion_regexes} list a new
    ...    line will be created in the required ${blacklist_file} location. This file is pushed to the OS_CONTROL_NODE
    ...    which is assumed to be the tempest executor.
    OperatingSystem.Create File    ${blacklist_file}
    : FOR    ${exclusion}    IN    @{${OPENSTACK_BRANCH}_exclusion_regexes}
    \    OperatingSystem.Append To File    ${blacklist_file}    ${exclusion}\n
    Log File    ${blacklist_file}
    SSHKeywords.Copy File To Remote System    ${OS_CONTROL_NODE_IP}    ${blacklist_file}    ${blacklist_file}
