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
    ${tempest_conn_id}=    SSHLibrary.Open Connection    ${OS_CONTROL_NODE_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Write Commands Until Prompt    neutron net-list
    ${net_id}=    Get Net Id    external    ${tempest_conn_id}
    Write Commands Until Prompt    crudini --set /etc/tempest/tempest.conf network public_network_id ${net_id}
    Set Suite Variable    ${tempest_conn_id}
    Utils.Flexible SSH Login    ${OS_USER}
