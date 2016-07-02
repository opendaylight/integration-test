*** Settings ***
Documentation     Test suite for running tempest tests.  It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Setup Test Environment
Suite Teardown    Close All Connections
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${exclusion_regex}    'metering|test_l3_agent_scheduler.L3AgentSchedulerTestJSON|test_extensions.ExtensionsTestJSON.test_list_show_extensions'
${tempest_config_file}    ./tempest.conf

*** Test Cases ***
tempest.api.network
    Run Tempest Tests    ${TEST_NAME}    ${exclusion_regex}    ${tempest_config_file}

tempest.scenario.test_minimum_basic
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}

*** Keywords ***
Log In To Tempest Executor And Setup Test Environment
    [Documentation]    Open SSH connection to a devstack system and source the openstack
    ...                credentials needed to run the tempest tests
    # source_pwd is expected to exist in the below Create Network, Create Subnet keywords.  Might be a bug.
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    # Tempest network.api tests need an existing external network in order to create
    # routers against.  Creating that here.
    Create Network    external --router:external=True
    Create Subnet     external    external-subnet    10.0.0.0/24
    List Networks
    ${net_id}=    Get Net Id    external
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Flexible SSH Login    ${OS_USER}
    Generate Tempest Conf File    ${net_id}


Generate Tempest Conf File
    [Arguments]    ${external_network_id}
    [Documentation]    Tempest will be run with a config file ./tempest.conf.  That file needs to be auto
    ...    generated first, then updated with the current openstack info, including the specific external
    ...    network id.  There was trouble with permissions in upstream CI, so everything is done with sudo
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