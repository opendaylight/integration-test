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
    Set Global Variable    ${FLOOD_DOMAIN_ID}    ${l2_fd_id}

Test Verify Created Network
    [Documentation]    Verifies created forwarding domains. Every assert on domain
    ...    e.g, Assert L2-Flood-Domain returns it's parent. This is how we can assert the
    ...    entire hierarchy of generated domains : l2-fd -> l2-bd -> l3-ctx
    ${l2_fd_path}    Get L2 Flood Domain Path    ${TENANT_ID}    ${FLOOD_DOMAIN_ID}
    ${l2_fd}    Get Data From URI    session    ${l2_fd_path}    headers=${headers}
    ${l2_bd_id}    Assert L2-Flood-Domain    ${l2_fd}    ${NETWORK_NAME}
    ${l2_bd_path}    Get L2 Bridge Domain Path    ${TENANT_ID}    ${l2_bd_id}
    ${l2_bd}    Get Data From URI    session    ${l2_bd_path}    headers=${headers}
    ${l3_ctx_id}    Assert L2-Bridge-Domain    ${l2_bd}    ${NETWORK_NAME}
    ${l3_ctx_path}    Get L3 Context Path    ${TENANT_ID}    ${l3_ctx_id}
    ${l3_ctx}    Get Data From URI    session    ${l3_ctx_path}    headers=${headers}
    Assert L3-Context    ${l3_ctx}    ${NETWORK_NAME}
    Set Global Variable    ${BRIDGE_DOMAIN_ID}    ${l2_bd_id}
    Set Global Variable    ${L3_CONTEXT_ID}    ${l3_ctx_id}

Test Create Subnet
    [Documentation]    Creates neutron subnet and verifies generated data
    ${uuid}    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_IP_PREFIX}    verbose=FALSE
    ${subnet_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${SUBNET_ID}    ${subnet_id}

Test Verify Created Subnet
    [Documentation]    Verifies generated data for subnet in GBP
    ${subnet_path}    Get Subnet Path    ${TENANT_ID}    ${SUBNET_ID}
    ${subnet}    Get Data From URI    session    ${subnet_path}    headers=${headers}
    ${l2_fd_id}    Assert Subnet    ${subnet}    ${NETWORK_NAME}    ${SUBNET_IP_PREFIX}
    # parent of subnet should be pointing at flood domain
    Should Be Equal as Strings    ${l2_fd_id}    ${FLOOD_DOMAIN_ID}

Test Create Security Groups
    [Documentation]    Creates neutron security groups
    ${uuid}    Create Neutron Security Group    ${CLIENT_SG}    verbose=FALSE
    ${security_group_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${CLIENT_SG_ID}    ${security_group_id}
    ${uuid}    Create Neutron Security Group    ${SERVER_SG}    verbose=FALSE
    ${security_group_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${SERVER_SG_ID}    ${security_group_id}

Test Create Security Group Rule With Remote Ip Prefix
    [Documentation]    Create neutron security group rule with --remote-ip-prefix
    ${remote_ip_prefix}    Set Variable    ${REMOTE_IP_PREFIX}
    ${uuid}    Create Security Group Rule    ${SERVER_SG}    --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 80 --port-range-max 90 --remote-ip-prefix ${remote_ip_prefix}    verbose=FALSE
    ${group_rule_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${GROUP_RULE_ID}    ${group_rule_id}

Verify Create Security Group Rule With Remote Ip Prefix
    [Documentation]    Verifies contract generated for security group rule with ip prefix
    ${contract_path}    Get Contract Path    ${TENANT_ID}    ${GROUP_RULE_ID}
    ${contract}    Get Data From URI    session    ${contract_path}    headers=${headers}
    Should Not Be Empty    ${contract}
    Verify Single Remote Ip Prefix In Contract    ${contract}    ${REMOTE_IP_PREFIX}
    Verify Allow Action in Single Rule Contract    ${contract}
    ${classif_inst_json}    Get Classifier Instance    ${TENANT_ID}    ${contract}
    ${parameter_values}    Set Variable    ${classif_inst_json['classifier-instance'][0]['parameter-value']}
    : FOR    ${par_value}    IN    @{parameter_values}
    \    Run Keyword If    "${par_value['name']}" == "destport_range"    Check CI Range Values    ${par_value['range-value']}    80    90
    \    ...    ELSE IF    "${par_value['name']}" == "proto"    Should Be Equal As Numbers    ${par_value['int-value']}    6
    \    ...    ELSE IF    "${par_value['name']}" == "ethertype"    Should Be Equal As Numbers    ${par_value['int-value']}    2048
    \    ...    ELSE    Fail
    # TODO check endpoint group selectors

Test Create Security Group Rule With Remote Group ID
    [Documentation]    Create neutron security group rule with --remote-group-id
    ${remote_ip_prefix}    Set Variable    ${REMOTE_IP_PREFIX}
    ${uuid}    Create Security Group Rule    ${SERVER_SG}    --direction ingress --ethertype IPv4 --protocol udp --port-range-min 8080 --port-range-max 8090 --remote-group-id ${CLIENT_SG}    verbose=FALSE
    ${group_rule_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${GROUP_RULE_ID}    ${group_rule_id}

Verify Create Security Group Rule With Remote Group ID
    [Documentation]    Verifies contract generated for security group rule with remote group id
    ${contract_path}    Get Contract Path    ${TENANT_ID}    ${GROUP_RULE_ID}
    ${contract}    Get Data From URI    session    ${contract_path}    headers=${headers}
    Should Not Be Empty    ${contract}
    Verify Allow Action in Single Rule Contract    ${contract}
    ${classif_inst_json}    Get Classifier Instance    ${TENANT_ID}    ${contract}
    ${parameter_values}    Set Variable    ${classif_inst_json['classifier-instance'][0]['parameter-value']}
    : FOR    ${par_value}    IN    @{parameter_values}
    \    Run Keyword If    "${par_value['name']}" == "destport_range"    Check CI Range Values    ${par_value['range-value']}    8080    8090
    \    ...    ELSE IF    "${par_value['name']}" == "proto"    Should Be Equal As Numbers    ${par_value['int-value']}    17
    \    ...    ELSE IF    "${par_value['name']}" == "ethertype"    Should Be Equal As Numbers    ${par_value['int-value']}    2048
    \    ...    ELSE    Fail
    Check Endpoint Group Name and Selector    ${SERVER_SG_ID}    ${SERVER_SG}    ${TENANT_ID}    ${GROUP_RULE_ID}    provider-named-selector
    Check Endpoint Group Name and Selector    ${CLIENT_SG_ID}    ${CLIENT_SG}    ${TENANT_ID}    ${GROUP_RULE_ID}    consumer-named-selector

Test Create Router
    [Documentation]    Creates neutron router.
    ${uuid}    Create Router    ${ROUTER_NAME}    verbose=FALSE
    ${router_id}    Should Match Regexp    ${uuid}    ${UUID_PATTERN}
    Set Global Variable    ${ROUTER_ID}    ${router_id}

Test Router Interface Add
    [Documentation]    Adds router's interface to subnet
    Router Interface Add Port    ${ROUTER_NAME}    ${SUBNET_NAME}    verbose=FALSE

Verify Added Router Interface
    [Documentation]    Verifies generated data for router in GBP
    ...    In beryllium l3-context is generated on router update, so the checking
    ...    is placed here.
    ${l3_ctx_path}    Get L3 Context Path    ${TENANT_ID}    ${ROUTER_ID}
    ${l3_ctx}    Get Data From URI    session    ${l3_ctx_path}    headers=${headers}
    Check Name    ${l3_ctx}    ${ROUTER_NAME}

Test Create Neutron Ports
    [Documentation]    Creates neutron ports
    ${mac_address}    Create Neutron Port    ${SERVER_PORT_IP}    ${SERVER_PORT_NAME}    ${SERVER_SG}
    Set Global Variable    ${SERVER_MAC_ADDR}    ${mac_address}
    ${mac_address}    Create Neutron Port    ${CLIENT_PORT_IP}    ${CLIENT_PORT_NAME}    ${CLIENT_SG}
    Set Global Variable    ${CLIENT_MAC_ADDR}    ${mac_address}

Verify Created Server Port
    [Documentation]    Verifies fields for generated endpoints in GBP
    ...    Mac addr may be stored as lowercase or uppercase. It's not important which format is used. Both are tried to overcome 404.
    ${SERVER_MAC_ADDR}    Convert To Uppercase    ${SERVER_MAC_ADDR}
    ${status}    ${value}    Run Keyword And Ignore Error    Verify Neutron Port    ${SERVER_MAC_ADDR}    ${SERVER_PORT_IP}    ${SERVER_SG_ID}
    Pass Execution If    "${status}" == "PASS"    Endpoint Verified.
    ${SERVER_MAC_ADDR}    Convert To Lowercase    ${SERVER_MAC_ADDR}
    Verify Neutron Port    ${SERVER_MAC_ADDR}    ${SERVER_PORT_IP}    ${SERVER_SG_ID}

Verify Created Client Port
    [Documentation]    Verifies fields for generated endpoints in GBP
    ...    Mac addr may be stored as lowercase or uppercase. It's not important which format is used. Both are tried to overcome 404.
    ${CLIENT_MAC_ADDR}    Convert To Uppercase    ${CLIENT_MAC_ADDR}
    ${status}    ${value}    Run Keyword And Ignore Error    Verify Neutron Port    ${CLIENT_MAC_ADDR}    ${CLIENT_PORT_IP}    ${CLIENT_SG_ID}
    Pass Execution If    "${status}" == "PASS"    Endpoint Verified.
    ${CLIENT_MAC_ADDR}    Convert To Lowercase    ${CLIENT_MAC_ADDR}
    Verify Neutron Port    ${CLIENT_MAC_ADDR}    ${CLIENT_PORT_IP}    ${CLIENT_SG_ID}

*** Keywords ***
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

Create Neutron Port
    [Arguments]    ${ip}    ${port_name}    ${sg_name}    ${subnet_name}=${SUBNET_NAME}
    [Documentation]    Creates neutron port by issuing neutron port-create command.
    ${output}    Write Commands Until Prompt    neutron port-create ${NETWORK_NAME} --fixed-ip subnet_id=${subnet_name},ip_address=${ip} --security-group ${sg_name} --name ${port_name} | grep -w mac_address | awk '{print $4}'
    Should Not Be Empty    ${output}
    ${mac_address}    Should Match Regexp    ${output}    ${MAC_ADDRESS_PATTERN}
    ${mac_address}    Convert To Lowercase    ${mac_address}
    [Return]    ${mac_address}

Verify Neutron Port
    [Arguments]    ${mac_address}    ${ip_address}    ${endpoint_group_id}
    [Documentation]    Verifies ODL data generated by neutron port-create command.
    ${out}    Get Data From URI    session    restconf/operational/endpoint:endpoints    headers=${headers}
    Log    ${out}
    ${endpoint_path}    Get Endpoint Path    ${BRIDGE_DOMAIN_ID}    ${mac_address}
    ${endpoint-l3_path}    Get EndpointL3 Path    ${ROUTER_ID}    ${ip_address}
    ${endpoint}    Get Data From URI    session    ${endpoint_path}    headers=${headers}
    ${endpoint-l3}    Get Data From URI    session    ${endpoint-l3_path}    headers=${headers}
    Check Endpoint    ${endpoint}    ${ip_address}    ${endpoint_group_id}    ${ROUTER_ID}    ${SUBNET_ID}    ${TENANT_ID}
    Check Endpoint-L3    ${endpoint-l3}    ${mac_address}    ${endpoint_group_id}    ${BRIDGE_DOMAIN_ID}    ${SUBNET_ID}    ${TENANT_ID}

Get Classifier Instance
    [Arguments]    ${tenant-id}    ${contract}
    ${classif_inst_name}    Get Classifier Instance Name of Single Rule Contract    ${contract}
    ${classif_inst_path}    Get Classifier Instance Path    ${tenant-id}    ${classif_inst_name}
    ${classif_inst}    Get Data From URI    session    ${classif_inst_path}    headers=${headers}
    ${classif_inst_json}    To Json    ${classif_inst}
    [Return]    ${classif_inst_json}

Clean Suite
    [Documentation]    Clears Openstack. This is also helpful when debugging tests locally.
    @{commands}    Set Variable    neutron port-delete ${CLIENT_PORT_NAME}    neutron port-delete ${SERVER_PORT_NAME}    neutron security-group-delete client_sg    neutron security-group-delete server_sg    neutron router-interface-delete ${ROUTER_NAME} subnet=${SUBNET_NAME}
    ...    neutron router-delete ${ROUTER_NAME}    neutron net-delete net123
    : FOR    ${cmd}    IN    @{commands}
    \    ${output}    Write Commands Until Prompt    ${cmd}
    \    Should Match Regexp    ${output}    Deleted|Removed
    Delete All Sessions
