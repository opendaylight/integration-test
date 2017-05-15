*** Settings ***
Documentation     Test suite for Inventory Scalability
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
@{Stack_Login}    stack    stack
${Devstack_Path}    /opt/stack/devstack
${netvirt_config_dir}    ${CURDIR}/../../../variables/netvirt
@{Ports}          tor1_port1    tor1_port2    tor2_port1    tor2_port2

*** Keywords ***
Start Suite
    [Documentation]    This is responsible for the devstack login on both the OVS.
    log    executing start suite
    ${conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_1}
    ${conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}    ${DEVSTACK_DEPLOY_PATH}
    Set Global Variable    ${conn_id_2}
    ${root_conn_id_1}    devstack login    ${TOOLS_SYSTEM_1_IP}    root    admin123    ${DEVSTACK_DEPLOY_PATH}    \#
    Set Global Variable    ${root_conn_id_1}
    ${root_conn_id_2}    devstack login    ${TOOLS_SYSTEM_2_IP}    root    admin123    ${DEVSTACK_DEPLOY_PATH}    \#
    Set Global Variable    ${root_conn_id_2}

dev_stack login
    [Arguments]    ${ip}    ${username}    ${password}    ${devstack_path}    ${stack_prompt}=$
    [Documentation]    Logs in to the dev stack for both OVS.
    ...    Returns connection Id.
    ${dev_stack_conn_id}    Open Connection    ${ip}
    set suite variable    ${dev_stack_conn_id}
    Login    ${username}    ${password}
    ${cd}    Write Commands Until Expected Prompt    cd ${devstack_path}    ${stack_prompt}    30
    ${openrc}    Write Commands Until Expected Prompt    source openrc admin admin    ${stack_prompt}    30
    ${pwd}    Write Commands Until Expected Prompt    pwd    ${stack_prompt}    30
    log    ${pwd}
    [Return]    ${dev_stack_conn_id}

check establishment
    [Arguments]    ${conn_id}    ${port}
    [Documentation]    Establishes the connection.
    Switch Connection    ${conn_id}
    ${check_establishment}    Execute Command    netstat -anp | grep ${port}
    Should contain    ${check_establishment}    ESTABLISHED
    [Return]    ${check_establishment}

Stop Suite
    [Documentation]    This keyword closes all the connections at the end of the suite execution.
    Close All Connections
