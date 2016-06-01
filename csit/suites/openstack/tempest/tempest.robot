*** Settings ***
Documentation     Test suite for running tempest tests.  It is assumed that the test environment
...               is already deployed and ready.
Suite Setup       Log In To Tempest Executor And Source Credentials
Suite Teardown    Close All Connections
Library           SSHLibrary
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${tempest_directory}    ${DEVSTACK_DEPLOY_PATH}/tempest

*** Test Cases ***
tempest.api.network
    Run Tempest Tests    ${TEST_NAME}

tempest.scenario.network
    Run Tempest Tests    ${TEST_NAME}

*** Keywords ***
Log In To Tempest Executor And Source Credentials
    [Documentation]    Open SSH connection to a devstack system and source the openstack
    ...                credentials needed to run the tempest tests
    SSHLibrary.Open Connection    ${DEVSTACK_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}
    Write Commands Until Prompt    source ${tempest_directory}/openrc admin admin
