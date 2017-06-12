*** Settings ***
Documentation     Test suite for IPV6 addr assignment and dual stack testing
Suite Setup       PreSuite Setup
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Library           Collections
Library           string
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Resource          ../../../libraries/IPV6_Service.robot
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
@{Stack_Login}    stack    stack
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{Ports}          tor1_port1    tor1_port2    tor2_port1    tor2_port2

*** Keywords ***
PreSuite Setup
    [Documentation]    This is responsible for the devstack login on both the DPN.
    ${conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_2}

Devstack Login
    [Arguments]    ${ip}    ${username}    ${password}    ${DEVSTACK_DEPLOY_PATH}
    [Documentation]    Logs in to the dev stack for both OVS.
    ...    Returns connection Id.
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd \ ${DEVSTACK_DEPLOY_PATH}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

Stop Suite
    [Documentation]    This keyword closes all the connections at the end of the suite execution.
    Close All Connections
