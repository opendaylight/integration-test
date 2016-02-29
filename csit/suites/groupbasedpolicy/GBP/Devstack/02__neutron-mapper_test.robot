*** Settings ***
Documentation     Testing of Group Based Policy Neutron-Mapper
Suite Setup       Give Credentials and Create Session
Suite Teardown    Clean Suite
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           String
Resource          Variables.robot
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/RestconfUtils.robot


*** Variables ***
${NETWORK_NAME}       net123
${SUBNET_NAME}        subnet123
${CLIENT_SG}          client_sg
${SERVER_SG}          server_sg
${TENANTS_CONF_PATH}  restconf/config/policy:tenants
${CLIENT_PORT_IP}     10.0.0.5
${SERVER_PORT_IP}     10.0.0.6
${REMOTE_IP_PREFIX}   20.0.0.0/24
${TENANT_ID}
${SUBNET_ID}
${FLOOD_DOMAIN_ID}
${BRIDGE_DOMAIN_ID}
${L3_CONTEXT_ID}
${GROUP_RULE_ID}
${CLIENT_MAC_ADDR}
${SERVER_MAC_ADDR}

*** Test Cases ***
Test neutron net-create and verify
    [Documentation]    Creates neutron network and verifies generated data.
    # TODO physical_network & segmentation-id
    ${l2_fd_id}     Wrap Command and Execute    neutron net-create ${NETWORK_NAME} | grep -w id | awk '{print $4}'
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
    [Documentation]  Creates neutron subnet and verifies generated data.
    ${subnet_id}     Wrap Command and Execute
    ...    neutron subnet-create ${NETWORK_NAME} 10.0.0.0/24 --name ${SUBNET_NAME} | grep -w id | awk '{print $4}'
    Should Not Be Empty                 ${subnet_id}
    ${subnet_path}   Get Subnet Path    ${TENANT_ID}   ${subnet_id}
    ${subnet}        Get Data From URI  session        ${subnet_path}    headers=${headers}
    Check Name       ${subnet}    ${SUBNET_NAME}
    ${l2_fd_id}      Get Parent   ${subnet}
    Should Be Equal as Strings    ${l2_fd_id}          ${FLOOD_DOMAIN_ID}
    Set Global Variable           ${SUBNET_ID}         ${subnet_id}

Test neutron security-group-create
    [Documentation]        Creates neutron security groups.
    ${client_group_id}     Wrap Command and Execute
    ...  neutron security-group-create ${CLIENT_SG} | grep -v _id | grep -w id | awk '{print $4}'
    ${server_group_id}     Wrap Command and Execute
    ...  neutron security-group-create ${SERVER_SG} | grep -v _id | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${client_group_id}
    Should Not Be Empty    ${server_group_id}
    Set Global Variable    ${CLIENT_SG_ID}   ${client_group_id}
    Set Global Variable    ${SERVER_SG_ID}   ${server_group_id}

Test neutron security-group-rule-create
    [Documentation]        Creates neutron security groups rules.
    ${remote_ip_prefix}    Set Variable    ${REMOTE_IP_PREFIX}
    ${group_rule_id}       Wrap Command and Execute
    ...    neutron security-group-rule-create ${CLIENT_SG} --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 80 --port-range-max 90 --remote-ip-prefix ${remote_ip_prefix} | grep -w id | awk '{print $4}'
    Should Not Be Empty    ${group_rule_id}
    Set Global Variable    ${GROUP_RULE_ID}   ${group_rule_id}

Test neutron port-create and verify
    [Documentation]   Creates neutron ports and verifies generated data.
    ${server_mac_address}    Wrap Command and Execute
    ...    neutron port-create ${NETWORK_NAME} --fixed-ip subnet_id=${SUBNET_NAME},ip_address=${SERVER_PORT_IP} --security-group ${SERVER_SG} --name port456 | grep -w mac_address | awk '{print $4}'
    ${client_mac_address}    Wrap Command and Execute
    ...    neutron port-create ${NETWORK_NAME} --fixed-ip subnet_id=${SUBNET_NAME},ip_address=${CLIENT_PORT_IP} --security-group ${CLIENT_SG} --name port123 | grep -w mac_address | awk '{print $4}'
    Should Not Be Empty    ${server_mac_address}
    Should Not Be Empty    ${client_mac_address}
    ${server_mac_address}  Convert To Uppercase   ${server_mac_address}
    ${client_mac_address}  Convert To Uppercase   ${client_mac_address}
    Set Global Variable    ${CLIENT_MAC_ADDR}     ${client_mac_address}
    Set Global Variable    ${SERVER_MAC_ADDR}     ${server_mac_address}
    @{mac_addresses}  Set Variable  ${server_mac_address}  ${client_mac_address}
    : FOR    ${mac_addr}    IN    @{mac_addresses}
    \    ${endpoint_path}     Get Endpoint Path      ${BRIDGE_DOMAIN_ID}    ${mac_addr}
    \    ${port_ip}    Set Variable If    "${mac_addr}" == "${client_mac_address}"  ${CLIENT_PORT_IP}  ${SERVER_PORT_IP}
    \    ${endpoint-l3_path}  Get EndpointL3 Path    ${L3_CONTEXT_ID}    ${port_ip}
    \    ${endpoint}          Get Data From URI      session    ${endpoint_path}     headers=${headers}
    \    ${endpoint-l3}       Get Data From URI      session    ${endpoint-l3_path}  headers=${headers}
    \    Check Endpoint     ${endpoint}
    \    Check Endpoint-L3  ${endpoint-l3}

Verify Contract
    [Documentation]         Verifies data generated by security group and security group rules.
    ...    Notifications for groups and rules come together with port notifications in stable/kilo.
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
    [Documentation]
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
    [Documentation]    Quick wrapper for Execute Command to make test cases more readable.
    [Arguments]    ${ip}=${DEVSTACK_IP}    ${usr}=${DEVSTACK_USER}    ${pwd}=${DEVSTACK_PWD}
    ...    ${prompt}=${DEVSTACK_PROMPT}    ${timeout}=${PROMPT_TIMEOUT}
    SSHLibrary.Open Connection    ${ip}    prompt=${prompt}
    Utils.Flexible SSH Login    ${usr}    ${pwd}
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    # TODO replace
    Wrap Command and Execute    cd /home/vagrant/devstack && source openrc admin admin
    Wrap Command and Execute    cd /opt/stack/new/devstack && source openrc admin admin
    ${output}=    Wrap Command and Execute
    ...    output=$(keystone tenant-list | grep -v _admin | grep admin | awk '{print $2}') && echo $output
    ${output}=    To Uuid  ${output}
    Should Match Regexp    ${output}    ${UUID_PATTERN}
    Set Global Variable    ${TENANT_ID}    ${output}
    #TODO replace
    Create Session    session    http://192.168.50.1:8181    auth=${AUTH}    headers=${headers}
   # Create Session    session    http://${DEVSTACK_SYSTEM_IP}:${8181}    auth=${AUTH}    headers=${headers}

Wrap Command and Execute
    [Arguments]    ${cmd}    ${timeout}=${PROMPT_TIMEOUT}
    [Documentation]    Quick wrapper for Execute Command to make test cases more readable.
    SSHLibrary.Set Client Configuration    timeout=${timeout}
    ${output}=    SSHLibrary.Execute Command    cd /home/vagrant/devstack && source openrc admin admin && ${cmd}
    ...    return_stdout=True    return_stderr=False    return_rc=False
    [Return]    ${output}

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

Check Name
    [Arguments]    ${data}    ${name}
    Should Not Be Empty    ${data}
    Should Match Regexp    ${data}    \"name\":\"${NAME_PATTERN}\"

Check CI Range Values
    [Documentation]  Veriefies min and max values of range-value for classifier-instance Input range arg have to be JSON.
    [Arguments]    ${range_value_json}    ${min}    ${max}
    Should Be Equal As Numbers  ${min}    ${range_value_json['min']}
    Should Be Equal As Numbers  ${max}    ${range_value_json['max']}

Get Parent
    [Documentation]  Returns 'parent' value of object. Can be applied to Subnet, L2-Flood-Domain or L2-Bridge-Domain.
    [Arguments]    ${data}
    Should Not Be Empty    ${data}
    ${parent_line}    Should Match Regexp    ${data}         \"parent\":\"${UUID_PATTERN}\"
    ${parent_uuid}    Should Match Regexp    ${parent_line}  ${UUID_PATTERN}
    [Return]    ${parent_uuid}

Check Endpoint
    [Documentation]  Verifies parameters of registerd endpoint.
    [Arguments]    ${endpoint}
    Check Env Variables
    Should Not Be Empty     ${endpoint}
    Should Contain          ${endpoint}    ofoverlay:port-name
    ${mac_address}          Get Mac Address of Endpoint            ${endpoint}
    @{l3-addresses}         Get L3-Addresses of Endpoint           ${endpoint}
    @{endpoint_groups}      Get Groups of Endpoint                 ${endpoint}
    ${network-containment}  Get Network Containment of Endpoint    ${endpoint}
    ${tenant}               Get Tenant of Endpoint                 ${endpoint}
    ${epg}   Set Variable If   "${mac_address}" == "${CLIENT_MAC_ADDR}"  ${CLIENT_SG_ID}  ${SERVER_SG_ID}
    ${ip}    Set Variable If   "${mac_address}" == "${CLIENT_MAC_ADDR}"  ${CLIENT_PORT_IP}  ${SERVER_PORT_IP}
    Should Be Equal As Strings  ${network-containment}  ${SUBNET_ID}
    Should Be Equal As Strings  ${tenant}               ${TENANT_ID}
    Check Groups                ${epg}                  @{endpoint_groups}
    : FOR    ${l3}  IN    @{l3-addresses}
    \    Continue For Loop If    "${l3['l3-context']}" == "${L3_CONTEXT_ID}"
    \    Continue For Loop If    "${l3['ip-address']}" == "${ip}"
    \    Fail

Check Endpoint-L3
    [Documentation]  Verifies parameters of registerd endpoint-l3.
    [Arguments]    ${endpoint-l3}
    Check Env Variables
    Should Not Be Empty     ${endpoint-l3}
    Should Contain          ${endpoint-l3}    ofoverlay:port-name
    ${l2-context}           Get L2 Context of Endpoint-L3           ${endpoint-l3}
    ${mac_address}          Get Mac Address of Endpoint-L3          ${endpoint-l3}
    ${network-containment}  Get Network Containment of Endpoint-L3  ${endpoint-l3}
    ${tenant}               Get Tenant of Endpoint-L3               ${endpoint-l3}
    @{endpoint_groups}      Get Groups of Endpoint-L3               ${endpoint-l3}
    ${epg}    Set Variable If   "${mac_address}" == "${CLIENT_MAC_ADDR}"  ${CLIENT_SG_ID}  ${SERVER_SG_ID}
    Should Be Equal As Strings  ${l2-context}           ${BRIDGE_DOMAIN_ID}
    Should Be Equal As Strings  ${network-containment}  ${SUBNET_ID}
    Should Be Equal As Strings  ${tenant}               ${TENANT_ID}
    Check Groups                ${epg}                  @{endpoint_groups}

Check Env Variables
    [Documentation]  Verifies presence of env variables.
    Should Not Be Empty     ${CLIENT_MAC_ADDR}
    Should Not Be Empty     ${CLIENT_SG_ID}
    Should Not Be Empty     ${SERVER_SG_ID}
    Should Not Be Empty     ${CLIENT_PORT_IP}
    Should Not Be Empty     ${SERVER_PORT_IP}

Check Groups
    [Documentation]  Verifies presence of endpoint group to which endpoint belongs and presence of network_client group
    ...              among given endpoint groups.
    [Arguments]    ${epg_to_look_for}    @{endpoint_groups}
    Should Not Be Empty   ${epg_to_look_for}
    Should Not Be Empty   ${endpoint_groups}
    : FOR    ${epg}    IN    @{endpoint_groups}
    \    Continue For Loop If    "${epg}" == "${epg_to_look_for}"
    \    Continue For Loop If    "${epg}" == "${NETWORK_CLIENT_GROUP}"
    \    Fail

Clean Suite
    [Documentation]  Clears Openstack. This is also helpful when debugging tests locally.
    @{commands}  Set Variable  neutron port-delete port123  neutron port-delete port456
    ...  neutron security-group-delete client_sg    neutron security-group-delete server_sg
    ...  neutron net-delete net123
    : FOR    ${cmd}    IN    @{commands}
    \    ${output}    Wrap Command and Execute    ${cmd}
    \    Should Contain    ${output}    Deleted
    Delete All Sessions