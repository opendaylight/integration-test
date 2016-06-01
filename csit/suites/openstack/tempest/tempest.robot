*** Settings ***
Documentation     Test suite for running tempest tests.  It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Source Credentials
Suite Teardown    Close All Connections
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
tempest.api.network
    Run Tempest Tests    ${TEST_NAME}

tempest.scenario.test_minimum_basic
    [Tags]    exclude
    Run Tempest Tests    ${TEST_NAME}

*** Keywords ***
Log In To Tempest Executor And Source Credentials
    [Documentation]    Open SSH connection to a devstack system and source the openstack
    ...                credentials needed to run the tempest tests
    ${source_pwd}    Set Variable    yes
    Set Suite Variable    ${source_pwd}
    Create Network    external
    List Networks
    ${net_id}=    Get Net Id    external
    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Flexible SSH Login    ${OS_USER}
    Write Commands Until Prompt    sudo yum install -y crudini
    Write Commands Until Prompt    source ${DEVSTACK_DEPLOY_PATH}/openrc admin admin
    Write Commands Until Prompt    sudo -E env
    Write Commands Until Prompt    sudo -E env | grep OS_
    Write Commands Until Prompt    cd /opt/stack/tempest
    Write Commands Until Prompt    sudo -E oslo-config-generator --config-file $(find . -name config-generator.tempest.conf) --output-file ./tempest.conf
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf service_available neutron true
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity catalog_type identity
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity uri http://localhost:5000/v2.0
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity uri_v3 http://localhost:8774/v3
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity auth_version v2
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity v2_admin_endpoint_type adminURL
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity username $OS_USERNAME
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity admin_role admin
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf identity password $OS_PASSWORD
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf auth admin_username $OS_USERNAME
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf auth admin_project_name $OS_TENANT_NAME
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf auth admin_password $OS_PASSWORD
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf network public_network_id ${net_id}
    Write Commands Until Prompt    sudo -E crudini --set ./tempest.conf DEFAULT verbose true
    Write Commands Until Prompt    sudo cat ./tempest.conf
    Write Commands Until Prompt    sudo chmod 777 ./tempest.conf

[auth]
admin_username = admin
admin_project_name = admin
admin_password = ccKsRPjA9FAAyHzWXXNwuUQvZ

[identity -feature-endabled]
api_v2 = true
api_v3 = true



[jamo]
rocks = false
doesnotrocks = false


[network]
public_network_id = 29cb8b78-cf60-4641-ae2a-6600326a45b2
