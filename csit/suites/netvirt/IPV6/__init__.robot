*** Settings ***
Documentation     This test suite covers \ IPV6 addr assignment in SLAAC mode.
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Library           Collections
Library           string
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/OpenStackOperations.robot
Library           re

*** Variables ***
@{stack_login}    stack    stack
${devstack_path}    /home/stack/devstack
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt

*** Keywords ***
Start Suite
    [Documentation]    Logging into OVS1 and OVS2
    ${conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_2}

dev_stack login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}
    [Documentation]    Logging into Devstack
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    $    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    $    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    $    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

check establishment
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Checking connection establishment from ODL controller to OVS
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Stop Suite
    [Documentation]    Closing all open connections
    Close All Connections
