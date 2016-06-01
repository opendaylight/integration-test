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
    Write Commands Until Prompt    sudo mkdir /etc/tempest
    Write Commands Until Prompt    cd /opt/stack/tempest
    Write Commands Until Prompt    sudo oslo-config-generator --config-file etc/config-generator.tempest.conf --output-file /etc/tempest/tempest.conf
    Write Commands Until Prompt    sudo chmod -R 777 /etc/tempest
    Write Commands Until Prompt    sudo ls -altr /etc/tempest
    Write Commands Until Prompt    sudo crudini --set /etc/tempest/tempest.conf network public_network_id ${net_id}
    Write Commands Until Prompt    sudo crudini --set /etc/tempest/tempest.conf DEFAULT verbose true
    Write Commands Until Prompt    sudo cat /etc/tempest/tempest.conf

