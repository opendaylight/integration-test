*** Settings ***
Documentation     Testing of Group Based Policy Neutron-Mapper
Suite Setup       Devstack Suite Setup
Suite Teardown    Clean Suite
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          Variables.robot
Resource          ../../../../variables/gbp/Constants.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/RestconfUtils.robot
Resource          ../../../../libraries/GBP/AssertionUtils.robot
Resource          ../../../../libraries/DevstackUtils.robot
Resource          ../../../../libraries/OpenStackOperations.robot

*** Variables ***
${NETWORK_NAME}    net123
${SUBNET_NAME}    subnet123
${CLIENT_SG}      client_sg
${SERVER_SG}      server_sg
${TENANTS_CONF_PATH}    restconf/config/policy:tenants
${CLIENT_PORT_IP}    10.0.0.5
${SERVER_PORT_IP}    10.0.0.6
${CLIENT_PORT_NAME}    client
${SERVER_PORT_NAME}    server
${REMOTE_IP_PREFIX}    10.0.0.0/24
${SUBNET_IP_PREFIX}    10.0.0.0/24
${ROUTER_NAME}    router123
${TENANT_ID}      ${EMPTY}
${SUBNET_ID}      ${EMPTY}
${FLOOD_DOMAIN_ID}    ${EMPTY}
${BRIDGE_DOMAIN_ID}    ${EMPTY}
${L3_CONTEXT_ID}    ${EMPTY}
${GROUP_RULE_ID}    ${EMPTY}
${CLIENT_MAC_ADDR}    ${EMPTY}
${SERVER_MAC_ADDR}    ${EMPTY}
${CLIENT_SG_ID}    ${EMPTY}
${SERVER_SG_ID}    ${EMPTY}
${ROUTER_ID}      ${EMPTY}

*** Test Cases ***
Test Resolve Tenant ID
    [Documentation]    Test reading tenant id from default security group
    ${tenant_id}    Get Tenant ID From Security Group
    ${tenant_id}=    To Uuid    ${tenant_id}
    Should Match Regexp    ${tenant_id}    ${UUID_PATTERN}
    Set Global Variable    ${TENANT_ID}    ${tenant_id}

Test Create Network
    [Documentation]    Create sec group and verify data generated in GBP
    ${uuid}    Create Network    net123    verbose=FALSE
    ${l2_fd_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    ${l2_fd_path}    Get L2 Flood Domain Path    ${TENANT_ID}    ${l2_fd_id}
    ${l2_fd}    Get Data From URI    session    ${l2_fd_path}    headers=${headers}
    ${l2_bd_id}    Assert L2-Flood-Domain    ${l2_fd}    ${NETWORK_NAME}
    ${l2_bd_path}    Get L2 Bridge Domain Path    ${TENANT_ID}    ${l2_bd_id}
    ${l2_bd}    Get Data From URI    session    ${l2_bd_path}    headers=${headers}
    ${l3_ctx_id}    Assert L2-Bridge-Domain    ${l2_bd}    ${NETWORK_NAME}
    ${l3_ctx_path}    Get L3 Context Path    ${TENANT_ID}    ${l3_ctx_id}
    ${l3_ctx}    Get Data From URI    session    ${l3_ctx_path}    headers=${headers}
    Assert L3-Context    ${l3_ctx}    ${NETWORK_NAME}
    Set Global Variable    ${FLOOD_DOMAIN_ID}    ${l2_fd_id}
    Set Global Variable    ${BRIDGE_DOMAIN_ID}    ${l2_bd_id}
    Set Global Variable    ${L3_CONTEXT_ID}    ${l3_ctx_id}

*** Keywords ***
Create Neutron Entity And Return ID
    [Arguments]    ${cmd}    ${pattern}=${UUID_PATTERN}
    [Documentation]    Designed for creating neutron entities and returing their IDs.
    ${output}    Write Commands Until Prompt    ${cmd} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${output}
    ${id}    Should Match Regexp    ${output}    ${pattern}
    [Return]    ${id}

To Uuid
    [Arguments]    ${init_string}
    [Documentation]    Insert dashes if missing to generate proper UUID string.
    Should Match Regexp    ${init_string}    ${UUID_NO_DASHES}
    ${first}    Get Substring    ${init_string}    0    8
    ${second}    Get Substring    ${init_string}    8    12
    ${third}    Get Substring    ${init_string}    12    16
    ${fourth}    Get Substring    ${init_string}    16    20
    ${fifth}    Get Substring    ${init_string}    20    32
    [Return]    ${first}-${second}-${third}-${fourth}-${fifth}

Clean Suite
    [Documentation]    Clears Openstack. This is also helpful when debugging tests locally.
    ${output}    Write Commands Until Prompt    neutron net-delete net123
    Should Match Regexp    ${output}    Deleted|Removed
    Delete All Sessions
