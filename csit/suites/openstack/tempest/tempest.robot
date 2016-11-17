*** Settings ***
Documentation     Test suite for running tempest tests. It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Setup Test Environment
Suite Teardown    Clean Up After Running Tempest
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${exclusion_regex}    'metering|test_l3_agent_scheduler.L3AgentSchedulerTestJSON|test_extensions.ExtensionsTestJSON.test_list_show_extensions|test_routers_dvr.RoutersTestDVR.test_centralized_router_update_to_dvr'
${tempest_config_file}    ./tempest.conf
${external_physical_network}    physnet1
${external_net_name}    external-net
${external_subnet_name}    external-subnet
${external_gateway}    10.10.10.250
${external_subnet}    10.10.10.0/24

*** Test Cases ***
tempest.api.network
    Run Tempest Tests    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_minimum_basic
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}

tempest.scenario.test_network_advanced_server_ops.TestNetworkAdvancedServerOps.test_server_connectivity_pause_unpause
    Run Tempest Tests    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_connectivity_between_vms_on_different_networks
    Run Tempest Tests    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_network_basic_ops.TestNetworkBasicOps.test_network_basic_ops
    Run Tempest Tests    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

*** Keywords ***
Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Initialize SetupUtils, open SSH connection to a devstack system and source the openstack
    ...    credentials needed to run the tempest tests
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    # source_pwd is expected to exist in the below Create Network, Create Subnet keywords.    Might be a bug.
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    # Tempest network.api tests need an existing external network in order to create
    # routers against.    Creating that here.
    Create Network    ${external_net_name} --router:external --provider:network_type=flat --provider:physical_network=${external_physical_network}
    Create Subnet    ${external_net_name}    ${external_subnet_name}    ${external_subnet}    --gateway ${external_gateway}
    List Networks
    ${control_node_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Flexible SSH Login    ${OS_USER}
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    ${net_id}=    Get Net Id    ${external_net_name}    ${control_node_conn_id}
    Generate Tempest Conf File    ${net_id}

Generate Tempest Conf File
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file ./tempest.conf. That file needs to be auto
    ...    generated first, then updated with the current openstack info, including the specific external
    ...    network id. There was trouble with permissions in upstream CI, so everything is done with sudo
    ...    and even the tempest.conf is changed to 777 permissions.
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    cd /opt/stack/tempest
    Write Commands Until Prompt    sudo -E oslo-config-generator --config-file $(find . -name config-generator.tempest.conf) --output-file ${tempest_config_file}
    # TODO: the below set of configs may not all be neccessary, so we could try to trim out what's not needed.
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    service_available    neutron    true
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    catalog_type    identity
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    uri    http://localhost:5000/v2.0
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    uri_v3    http://localhost:8774/v3
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    auth_version    v2
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    v2_admin_endpoint_type    adminURL
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    username    $OS_USERNAME
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    admin_role    admin
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    identity    password    $OS_PASSWORD
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    auth    admin_username    $OS_USERNAME
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    auth    admin_project_name    $OS_TENANT_NAME
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    auth    admin_password    $OS_PASSWORD
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    network    public_network_id    ${external_network_id}
    Add Config To File On Existing SSH Connection    ${tempest_config_file}    DEFAULT    verbose    true
    Write Commands Until Prompt    sudo cat ./tempest.conf
    Write Commands Until Prompt    sudo chmod 777 ./tempest.conf

Add Config To File On Existing SSH Connection
    [Arguments]    ${config_file}    ${config_section}    ${config_key}    ${config_value}
    [Documentation]    uses crudini to populate oslo cofg file.
    # this keyword is only one line so seems like extra overhead, but this may be a good candidate to move
    # to a library at some point, when/if other suites need to use it, so wanted to make it generic.
    Write Commands Until Prompt    sudo -E crudini --set ${config_file} ${config_section} ${config_key} ${config_value}

Clean Up After Running Tempest
    [Documentation]    Clean up any extra leftovers that were created to allow tempest tests to run.
    Delete SubNet    ${external_subnet_name}
    Delete Network    ${external_net_name}
    List Networks
    Close All Connections

