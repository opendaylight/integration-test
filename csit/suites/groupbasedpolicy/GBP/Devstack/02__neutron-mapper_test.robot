*** Settings ***
Documentation     Testing of Group Based Policy Neutron-Mapper
Suite Setup       Give Credentials and Create Session
Suite Teardown    Clean Suite
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/RestconfUtils.robot
Resource          Variables.robot

*** Variables ***
${NETWORK_NAME}    net123
${SUBNET_NAME}    subnet123
${CLIENT_SG}    client_sg
${SERVER_SG}    server_sg
${TENANTS_CONF_PATH}    restconf/config/policy:tenants
${TENANT_ID}
${SUBNET_ID}
${FLOOD_DOMAIN_ID}
${BRIDGE_DOMAIN_ID}
${L3_CONTEXT_ID}
${CLIENT_ENDPOINT_GROUP_ID}
${SERVER_ENDPOINT_GROUP_ID}
${GROUP_RULE_ID}

*** Test Cases ***
Test neutron net-create and verify
    # TODO physical_network & segmentation-id
    ${l2_fd_id}     Write Commands Until Prompt    neutron net-create ${NETWORK_NAME} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${l2_fd_id}
    ${l2_fd_path}   Get L2 Flood Domain Path        ${TENANT_ID}     ${l2_fd_id}
    ${l2_fd}        Get Data From URI    session    ${l2_fd_path}    headers=${headers}
    Check Name      ${l2_fd}      ${NETWORK_NAME}
    ${l2_bd_id}     Get Parent    ${l2_fd}
    ${l2_bd_path}   Get L2 Bridge Domain Path       ${TENANT_ID}      ${l2_bd_id}
    ${l2_bd}        Get Data From URI    session    ${l2_bd_path}     headers=${headers}
    Check Name      ${l2_bd}      ${NETWORK_NAME}
    ${l3_ctx_id}    Get Parent    ${l2_bd}
    ${l3_ctx_path}  Get L3 Context Path             ${TENANT_ID}      ${l3_ctx_id}
    ${l3_ctx}       Get Data From URI    session    ${l3_ctx_path}    headers=${headers}
    Check Name      ${l3_ctx}     ${NETWORK_NAME}
    Set Global Variable    ${FLOOD_DOMAIN_ID}    ${l2_fd_id}
    Set Global Variable    ${BRIDGE_DOMAIN_ID}   ${l2_bd_id}
    Set Global Variable    ${L3_CONTEXT_ID}      ${l3_ctx_id}

Test neutron subnet-create and verify
    ${subnet_id}     Write Commands Until Prompt
    ...    neutron subnet-create ${NETWORK_NAME} 10.0.0.0/24 --name ${SUBNET_NAME} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${subnet_id}
    ${subnet_path}   Get Subnet Path        ${TENANT_ID}     ${subnet_id}
    ${subnet}        Get Data From URI    session    ${subnet_path}    headers=${headers}
    Check Name       ${subnet}      ${SUBNET_NAME}
    ${l2_fd_id}      Get Parent    ${subnet}
    Should Be Equal as Strings    ${l2_fd_id}    ${FLOOD_DOMAIN_ID}
    Set Global Variable    ${SUBNET_ID}   ${subnet_id}

Test neutron security-group-create
    ${client_group_id}     Write Commands Until Prompt
    ...  neutron security-group-create ${CLIENT_SG} | grep -v _id | grep -w id | awk '{print $4}'
     Should Not Be Empty    ${client_group_id}
    ${server_group_id}     Write Commands Until Prompt
    ...  neutron security-group-create ${SERVER_SG} | grep -v _id | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${server_group_id}
    Set Global Variable    ${CLIENT_SG_ID}   ${client_group_id}
    Set Global Variable    ${SERVER_SG_ID}   ${server_group_id}


Test neutron security-group-rule-create
    ${remote_ip_prefix}    Set Variable    20.0.0.0/24
    ${group_rule_id}     Write Commands Until Prompt
    ...    neutron security-group-rule-create ${CLIENT_SG} --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 80 --port-range-max 90 --remote-ip-prefix ${remote_ip_prefix} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${group_rule_id}
    Set Global Variable    ${GROUP_RULE_ID}   ${group_rule_id}

Test neutron port-create and verify
    ${port_ip}    Set Variable    10.0.0.5
    ${mac_address}    Write Commands Until Prompt
    # TODO break into lines
    ...    neutron port-create ${NETWORK_NAME} --fixed-ip subnet_id=${SUBNET_NAME},ip_address=${port_ip} --security-group client_sg --name port123 | grep -w mac_address | awk '{print $4}'
    Should Not Be Empty    ${mac_address}
    ${mac_address}       Convert To Uppercase   ${mac_address}
    ${endpoint_path}     Get Endpoint Path      ${BRIDGE_DOMAIN_ID}    ${mac_address}
    ${endpoint-l3_path}  Get EndpointL3 Path    ${L3_CONTEXT_ID}    ${port_ip}
    ${endpoint}          Get Data From URI      session    ${endpoint_path}     headers=${headers}
    ${endpoint-l3}       Get Data From URI      session    ${endpoint-l3_path}  headers=${headers}
    Should Contain       ${endpoint}    "ip-address":"${port_ip}"
    Should Contain       ${endpoint}    "l3-context":"${L3_CONTEXT_ID}"
    Should Contain       ${endpoint}    "network-containment":"${SUBNET_ID}"
    Should Contain       ${endpoint}    ofoverlay:port-name
    Should Contain       ${endpoint}    "tenant":"${TENANT_ID}"
    Should Contain       ${endpoint}    ${CLIENT_SG_ID}
    Should Contain       ${endpoint}    ccc5e444-573c-11e5-885d-feff819cdc9f
    Should Contain    ${endpoint-l3}    "mac-address":"${mac_address}"
    Should Contain    ${endpoint-l3}    "l2-context":"${BRIDGE_DOMAIN_ID}"
    Should Contain    ${endpoint-l3}    "network-containment":"${SUBNET_ID}"
    Should Contain    ${endpoint-l3}    ofoverlay:port-name
    Should Contain    ${endpoint-l3}    "tenant":"${TENANT_ID}"
    Should Contain    ${endpoint-l3}    ${CLIENT_SG_ID}
    Should Contain    ${endpoint-l3}    ccc5e444-573c-11e5-885d-feff819cdc9f

Verify Contract
    ${contract_path}   Get Contract Path    ${TENANT_ID}    ${GROUP_RULE_ID}
    ${contract}        Get Data From URI    session    ${contract_path}    headers=${headers}
    Should Not Be Empty    ${contract}
    ${contract_json}    To Json    ${contract}
    ${eic}   Set Variable  ${contract_json['contract'][0]['clause'][0]['consumer-matchers']['endpoint-identification-constraints']}
    ${prefix_constraint}    Set Variable    ${eic['l3-endpoint-identification-constraints']['prefix-constraint'][0]}
    Should Be Equal As Strings    ${prefix_constraint['ip-prefix']}    20.0.0.0/24
    ${action_ref}    Set Variable
    ...    ${contract_json['contract'][0]['subject'][0]['rule'][0]['action-ref'][0]}
    Should Be Equal As Strings    ${action_ref['name']}    Allow
    ${classif_inst_name}    BuiltIn.Convert To String
    ...    ${contract_json['contract'][0]['subject'][0]['rule'][0]['classifier-ref'][0]['instance-name']}
    ${classif_inst_path}    Get Classifier Instance Path    ${TENANT_ID}    ${classif_inst_name}
    ${classif_inst}        Get Data From URI    session    ${classif_inst_path}    headers=${headers}
    ${classif_inst_json}    To Json    ${classif_inst}
    ${parameter_values}        Set Variable
    ...    ${classif_inst_json['classifier-instance'][0]['parameter-value']}
    Set Global Variable  ${verify_index}    _
    : FOR    ${par_value}    IN    @{parameter_values}
    \    Run Keyword If    "${par_value['name']}" == "destport_range"    Check CI Range Values    ${par_value['range-value']}    80    90
    ...    ELSE IF    "${par_value['name']}" == "proto"      Should Be Equal As Numbers    ${par_value['int-value']}    6
    ...    ELSE IF    "${par_value['name']}" == "ethertype"  Should Be Equal As Numbers    ${par_value['int-value']}    2048
    ...    ELSE    Fail

Verify Endpoint Group
    ${epg_path}   Get Endpoint Group Path    ${TENANT_ID}    ${CLIENT_SG_ID}
    ${endpoint_group}        Get Data From URI    session    ${epg_path}    headers=${headers}
    Should Not Be Empty    ${endpoint_group}
    ${endpoint_group_json}    To Json    ${endpoint_group}
    ${provider_named_selectors}   Set Variable  ${endpoint_group_json['endpoint-group'][0]['provider-named-selector']}
    Set Global Variable  ${selector_found}    FALSE
    : FOR    ${selector}    IN    @{provider_named_selectors}
    \    Run Keyword If    "${selector['contract'][0]}" == "${GROUP_RULE_ID}"  Set Global Variable  ${selector_found}    TRUE
    Should Be Equal As Strings    ${selector_found}    TRUE

*** Keywords ***
Give Credentials and Create Session
    [Arguments]    ${ip}=${DEVSTACK_IP}    ${usr}=${DEVSTACK_USER}    ${pwd}=${DEVSTACK_PWD}
    ...    ${prompt}=${DEVSTACK_PROMPT}    ${timeout}=${PROMPT_TIMEOUT}
    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    Utils.Flexible SSH Login    ${usr}    ${pwd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    # TODO replace
    ${output}     Write Commands Until Prompt    cd /home/vagrant/devstack && source openrc admin admin
    #${output}     Write Commands Until Prompt    cd /opt/stack/new/devstack && source openrc admin admin
    Should Be Empty    ${output}
    ${output}=    Write Commands Until Prompt
    ...    output=$(keystone tenant-list | grep -v _admin | grep admin | awk '{print $2}') && echo $output
    Should Not Be Empty    ${output}
    ${output}=    To Uuid  ${output}
    Should Match Regexp    ${output}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Set Global Variable    ${TENANT_ID}    ${output}
    #TODO replace
    Create Session    session    http://192.168.50.1:8181    auth=${AUTH}    headers=${headers}
   # Create Session    session    http://${DEVSTACK_SYSTEM_IP}:${8181}    auth=${AUTH}    headers=${headers}

Write Commands Until Prompt
    [Arguments]    ${cmd}    ${timeout}=${default_devstack_prompt_timeout}
    [Documentation]    quick wrapper for Write and Read Until Prompt Keywords to make test cases more readable
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    ${output}=    SSHLibrary.Execute Command    cd /home/vagrant/devstack && source openrc admin admin && ${cmd}
    ...    return_stdout=True    return_stderr=False    return_rc=False
    [Return]    ${output}

To Uuid
    [Arguments]    ${init_string}
    Should Match Regexp    ${init_string}    [0-9a-f]{8}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{4}[0-9a-f]{12}
     ${first}     Get Substring    ${init_string}    0    8
     ${second}    Get Substring    ${init_string}    8    12
     ${third}     Get Substring    ${init_string}    12   16
     ${fourth}    Get Substring    ${init_string}    16   20
     ${fifth}     Get Substring    ${init_string}    20   32
    [Return]    ${first}-${second}-${third}-${fourth}-${fifth}

Check Name
    [Arguments]    ${data}    ${name}
    Should Not Be Empty    ${data}
    Should Match Regexp    ${data}    \"name\":\"[a-zA-Z]([a-zA-Z0-9\-_.])*\"

Check CI Range Values
    [Arguments]    ${range_value_json}    ${min}    ${max}
    Should Be Equal As Numbers  ${min}    ${range_value_json['min']}
    Should Be Equal As Numbers  ${max}    ${range_value_json['max']}

Get Parent
    [Arguments]    ${data}
    Should Not Be Empty    ${data}
    ${parent_line}    Should Match Regexp    ${data}    \"parent\":\"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\"
    Should Not Be Empty    ${parent_line}
    ${parent_uuid}    Should Match Regexp    ${parent_line}    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
    Should Not Be Empty    ${parent_uuid}
    [Return]    ${parent_uuid}

Clean Suite
    Write Commands Until Prompt    neutron port-delete port123
    Write Commands Until Prompt    neutron security-group-delete client_sg
    Write Commands Until Prompt    neutron security-group-delete server_sg
    Write Commands Until Prompt    neutron net-delete net123
    Delete All Sessions