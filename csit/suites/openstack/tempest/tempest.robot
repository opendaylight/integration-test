*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Setup Test Environment
Suite Teardown    Clean Up After Running Tempest
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get OvsDebugInfo
Test Template     DevstackUtils.Run Tempest Tests
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${exclusion_regex}    'metering|test_l3_agent_scheduler.L3AgentSchedulerTestJSON|test_extensions.ExtensionsTestJSON.test_list_show_extensions|test_routers_dvr.RoutersTestDVR.test_centralized_router_update_to_dvr'
${tempest_config_file}    /opt/stack/tempest/etc/tempest.conf
${external_physical_network}    physnet1
${external_net_name}    external-net
${external_subnet_name}    external-subnet
${external_gateway}    10.10.10.250
${external_subnet}    10.10.10.0/24

*** Test Cases ***
tempest.api.network
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_connectivity_between_vms_on_different_networks
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_hotplug_nic
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_mtu_sized_frames
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_network_basic_ops
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_port_security_macspoofing_port
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_preserve_preexisting_port
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_router_rescheduling
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_subnet_details
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_aggregates_basic_ops.TestAggregatesBasicOps.test_aggregate_basic_ops
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_pause_unpause
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_stop_start
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_reboot
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_rebuild
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_suspend_resume
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_server_basic_ops.TestServerBasicOps.test_server_basic_ops
    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

*** Keywords ***
Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    # source_pwd is expected to exist in the below Create Network, Create Subnet keywords.    Might be a bug.
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    # Tempest tests need an existing external network in order to create routers.
    Create Network    ${external_net_name} --router:external --provider:network_type=flat --provider:physical_network=${external_physical_network}
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway}
    List Networks
    ${control_node_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Flexible SSH Login    ${OS_USER}
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
