*** Settings ***
Documentation     Testing of Group Based Policy Neutron-Mapper
Suite Setup       Devstack Suite Setup Tests
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
${NETWORK_NAME}       net123
${SUBNET_NAME}        subnet123
${CLIENT_SG}          client_sg
${SERVER_SG}          server_sg
${TENANTS_CONF_PATH}  restconf/config/policy:tenants
${CLIENT_PORT_IP}     10.0.0.5
${SERVER_PORT_IP}     10.0.0.6
${CLIENT_PORT_NAME}     client
${SERVER_PORT_NAME}     server
${REMOTE_IP_PREFIX}   10.0.0.0/24
${SUBNET_IP_PREFIX}   10.0.0.0/24
${ROUTER_NAME}        router123
${TENANT_ID}
${SUBNET_ID}
${FLOOD_DOMAIN_ID}
${BRIDGE_DOMAIN_ID}
${L3_CONTEXT_ID}
${GROUP_RULE_ID}
${CLIENT_MAC_ADDR}
${SERVER_MAC_ADDR}
${CLIENT_SG_ID}
${SERVER_SG_ID}
${ROUTER_ID}

*** Test Cases ***
Test Create Network
    ${tenant_id}    Get Tenant ID
    ${tenant_id}=    To Uuid  ${tenant_id}
    Should Match Regexp    ${tenant_id}    ${UUID_PATTERN}
    Set Global Variable    ${TENANT_ID}    ${tenant_id}
    ${uuid}    Create Network    net123    verbose=FALSE
    ${l2_fd_id}     Should Match Regexp  ${uuid}  ${UUID_PATTERN}
    ${l2_fd_path}   Get L2 Flood Domain Path        ${TENANT_ID}     ${l2_fd_id}
    ${l2_fd}        Get Data From URI    session    ${l2_fd_path}    headers=${headers}
    ${l2_bd_id}     Assert L2-Flood-Domain    ${l2_fd}    ${NETWORK_NAME}
    ${l2_bd_path}   Get L2 Bridge Domain Path       ${TENANT_ID}      ${l2_bd_id}
    ${l2_bd}        Get Data From URI    session    ${l2_bd_path}     headers=${headers}
    ${l3_ctx_id}    Assert L2-Bridge-Domain    ${l2_bd}    ${NETWORK_NAME}
    ${l3_ctx_path}  Get L3 Context Path             ${TENANT_ID}      ${l3_ctx_id}
    ${l3_ctx}       Get Data From URI    session    ${l3_ctx_path}    headers=${headers}
                    Assert L3-Context    ${l3_ctx}    ${NETWORK_NAME}
    Set Global Variable    ${FLOOD_DOMAIN_ID}    ${l2_fd_id}
    Set Global Variable    ${BRIDGE_DOMAIN_ID}   ${l2_bd_id}
    Set Global Variable    ${L3_CONTEXT_ID}      ${l3_ctx_id}

*** Keywords ***
Start Suite
    [Documentation]    Quick wrapper for Execute Command to make test cases more readable.
    [Arguments]    ${ip}=${DEVSTACK_IP}    ${usr}=${DEVSTACK_USER}    ${password}=${DEVSTACK_PWD}
    ...    ${prompt}=${DEVSTACK_PROMPT}    ${timeout}=${PROMPT_TIMEOUT}
    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    Utils.Flexible SSH Login     ${usr}    ${password}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    ${output}=    Write Commands Until Prompt    cd ${DEVSTACK_DIR} && cat localrc
    Log    ${output}
    ${output}=    Write Commands Until Prompt    source openrc admin admin
    Log    ${output}
    ${output}=    Write Commands Until Prompt
    ...    neutron security-group-show default | grep "| tenant_id" | awk '{print $4}'
    ${tenant_id}     Should Match Regexp  ${output}  ${UUID_NO_DASHES}
    ${tenant_id}=    To Uuid  ${tenant_id}
    Should Match Regexp    ${tenant_id}    ${UUID_PATTERN}
    Set Global Variable    ${TENANT_ID}    ${tenant_id}
    Create Session    session    http://${ODL_IP}:8181    auth=${AUTH}    headers=${headers}

Create Neutron Entity And Return ID
    [Documentation]    Designed for creating neutron entities and returing their IDs.
    [Arguments]    ${cmd}    ${pattern}=${UUID_PATTERN}
    ${output}    Write Commands Until Prompt  ${cmd} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${output}
    ${id}     Should Match Regexp    ${output}    ${pattern}
    [Return]    ${id}

To Uuid
    [Documentation]  Insert dashes if missing to generate proper UUID string.
    [Arguments]    ${init_string}
    Should Match Regexp    ${init_string}    ${UUID_NO_DASHES}
     ${first}     Get Substring    ${init_string}    0    8
     ${second}    Get Substring    ${init_string}    8    12
     ${third}     Get Substring    ${init_string}    12   16
     ${fourth}    Get Substring    ${init_string}    16   20
     ${fifth}     Get Substring    ${init_string}    20   32
    [Return]    ${first}-${second}-${third}-${fourth}-${fifth}

Create neutron port
    [Documentation]   Creates neutron port by issuing neutron port-create command.
    [Arguments]    ${ip}    ${port_name}    ${sg_name}    ${subnet_name}=${SUBNET_NAME}
    ${output}   Write Commands Until Prompt
    ...    neutron port-create ${NETWORK_NAME} --fixed-ip subnet_id=${subnet_name},ip_address=${ip} --security-group ${sg_name} --name ${port_name} | grep -w mac_address | awk '{print $4}'
    Should Not Be Empty    ${output}
    ${mac_address}     Should Match Regexp   ${output}    ${MAC_ADDRESS_PATTERN}
    ${mac_address}     Convert To Uppercase  ${mac_address}
    [Return]  ${mac_address}

Verify neutron port
    [Documentation]   Verifies ODL data generated by neutron port-create command.
    [Arguments]    ${mac_address}    ${ip_address}    ${endpoint_group_id}
    ${endpoint_path}     Get Endpoint Path      ${BRIDGE_DOMAIN_ID}    ${mac_address}
    ${endpoint-l3_path}  Get EndpointL3 Path    ${ROUTER_ID}    ${ip_address}
    ${endpoint}          Get Data From URI      session    ${endpoint_path}     headers=${headers}
    ${endpoint-l3}       Get Data From URI      session    ${endpoint-l3_path}  headers=${headers}
    Check Endpoint  ${endpoint}  ${ip_address}  ${endpoint_group_id}  ${ROUTER_ID}  ${SUBNET_ID}  ${TENANT_ID}
    Check Endpoint-L3  ${endpoint-l3}  ${mac_address}  ${endpoint_group_id}  ${BRIDGE_DOMAIN_ID}  ${SUBNET_ID}  ${TENANT_ID}

Verify Contract
    [Documentation]         Verifies data generated by security group and security group rules.
    ...    Notifications for groups and rules come together with port notifications in stable/kilo.
    [Arguments]             ${rule_id}    ${ip_prefix}    ${tenant}
    ${contract_path}        Get Contract Path    ${TENANT_ID}    ${GROUP_RULE_ID}
    ${contract}             Get Data From URI    session    ${contract_path}    headers=${headers}
    Should Not Be Empty    ${contract}
    ${prefix_constraint}    Get Prefix Constraint of Single Rule Contract    ${contract}
    Should Be Equal As Strings    ${prefix_constraint['ip-prefix']}    ${REMOTE_IP_PREFIX}
    ${action_ref}           Get Action of Single Rule Contract    ${contract}
    Should Be Equal As Strings    ${action_ref['name']}    Allow
    ${classif_inst_name}    Get Action Instance Name of Single Rule Contract    ${contract}
    ${classif_inst_path}    Get Classifier Instance Path    ${TENANT_ID}    ${classif_inst_name}
    ${classif_inst}         Get Data From URI    session    ${classif_inst_path}    headers=${headers}
    ${classif_inst_json}    To Json    ${classif_inst}
    ${parameter_values}     Set Variable
    ...    ${classif_inst_json['classifier-instance'][0]['parameter-value']}
    Set Global Variable  ${verify_index}    _
    : FOR    ${par_value}    IN    @{parameter_values}
    \    Run Keyword If    "${par_value['name']}" == "destport_range"    Check CI Range Values    ${par_value['range-value']}    80    90
    ...    ELSE IF    "${par_value['name']}" == "proto"      Should Be Equal As Numbers    ${par_value['int-value']}    6
    ...    ELSE IF    "${par_value['name']}" == "ethertype"  Should Be Equal As Numbers    ${par_value['int-value']}    2048
    ...    ELSE    Fail

Verify Endpoint Group
    [Documentation]    Verifies data generated by security group and security group rules.
    [Arguments]             ${client_}    ${ip_prefix}    ${tenant}
    Check Endpoint Group Name and Selector    ${CLIENT_SG_ID}    ${CLIENT_SG}
    ...   ${TENANT_ID}    ${GROUP_RULE_ID}    consumer-named-selector

Verify Server Endpoint Group
    [Documentation]    Verifies data generated by security group and security group rules.
    [Arguments]             ${rule_id}    ${ip_prefix}    ${tenant}
    Check Endpoint Group Name and Selector    ${SERVER_SG_ID}    ${SERVER_SG}
    ...   ${TENANT_ID}    ${GROUP_RULE_ID}    provider-named-selector

Clean Suite
    [Documentation]  Clears Openstack. This is also helpful when debugging tests locally.
    ${output}   Write Commands Until Prompt     neutron net-delete net123
    Should Match Regexp    ${output}    Deleted|Removed
    Delete All Sessions
