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

Test Resolve Tenant ID
    [Documentation]  Test reading tenant id from default security group
    ${tenant_id}     Get Tenant ID From Security Group
    ${tenant_id}=    To Uuid  ${tenant_id}
    Should Match Regexp    ${tenant_id}    ${UUID_PATTERN}
    Set Global Variable    ${TENANT_ID}    ${tenant_id}

Test Create Network
    [Documentation]  Create sec group and verify data generated in GBP
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

Test neutron subnet-create and verify
    [Documentation]  Creates neutron subnet and verifies generated data
    ${uuid}    Create SubNet    ${NETWORK_NAME}    ${SUBNET_NAME}    ${SUBNET_IP_PREFIX}    verbose=FALSE
    ${subnet_id}     Should Match Regexp  ${uuid}  ${UUID_PATTERN}
    ${subnet_path}   Get Subnet Path    ${TENANT_ID}   ${subnet_id}
    ${subnet}        Get Data From URI  session        ${subnet_path}      headers=${headers}
    ${l2_fd_id}      Assert Subnet      ${subnet}      ${NETWORK_NAME}    ${SUBNET_IP_PREFIX}
    Should Be Equal as Strings          ${l2_fd_id}    ${FLOOD_DOMAIN_ID}
    Set Global Variable                 ${SUBNET_ID}   ${subnet_id}

Test neutron security-group-create
    [Documentation]        Creates neutron security groups.
    @{security_groups}    Set Variable    ${CLIENT_SG}    ${SERVER_SG}
    : FOR    ${security_group}    IN    @{security_groups}
    \    ${uuid}    Create Security Group    ${security_group}   verbose=FALSE
    \    ${security_group_id}     Should Match Regexp  ${uuid}  ${UUID_PATTERN}
    \    Run Keyword If  "${security_group}" == "${CLIENT_SG}"  Set Global Variable  ${CLIENT_SG_ID}  ${security_group_id}
    ...  ELSE    Set Global Variable    ${SERVER_SG_ID}   ${security_group_id}
    Pass Execution If    "${DEVSTACK_BRANCH}" == "stable/kilo"   Generated data for kilo not checked here.
    Check Endpoint Group Name and Selector    ${SERVER_SG_ID}    ${SERVER_SG}
    ...   ${TENANT_ID}    ${GROUP_RULE_ID}    provider-named-selector
    Check Endpoint Group Name and Selector    ${CLIENT_SG_ID}    ${CLIENT_SG}
    ...   ${TENANT_ID}    ${GROUP_RULE_ID}    consumer-named-selector

Test neutron security-group-rule-create and verify if not stable/kilo
    [Documentation]        Creates neutron security groups rules. Generated data are not checked here for stable/kilo.
    ${remote_ip_prefix}    Set Variable    ${REMOTE_IP_PREFIX}
    ${uuid}       Create Security Group Rule    ${SERVER_SG}
    ...    --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 80 --port-range-max 90 --remote-ip-prefix ${remote_ip_prefix}
    ...    verbose=FALSE
    ${group_rule_id}     Should Match Regexp  ${uuid}  ${UUID_PATTERN}
    Set Global Variable    ${GROUP_RULE_ID}   ${group_rule_id}
    Pass Execution If     "${DEVSTACK_BRANCH}" == "stable/kilo"    Generated data for kilo not checked here.
    Verify Contract        ${GROUP_RULE_ID}   ${REMOTE_IP_PREFIX}  ${TENANT_ID}

Test neutron router-create
    [Documentation]  Creates neutron router.
    ${uuid}          Create Neutron Router    ${ROUTER_NAME}    verbose=FALSE
    ${router_id}     Should Match Regexp  ${uuid}  ${UUID_PATTERN}
    Set Global Variable    ${ROUTER_ID}   ${router_id}

Test neutron router-interface-add and verify
    [Documentation]  Adds router's interface to subnet.
    Router Interface Add Port    ${ROUTER_NAME} ${SUBNET_NAME}    verbose=FALSE
    ${l3_ctx_path}   Get L3 Context Path  ${TENANT_ID}    ${ROUTER_ID}
    ${l3_ctx}        Get Data From URI    session         ${l3_ctx_path}    headers=${headers}
    Check Name       ${l3_ctx}            ${ROUTER_NAME}

Test server neutron port-create and verify
    [Documentation]   Creates neutron port and verifies generated data.
    ${mac_address}    Create neutron port      ${SERVER_PORT_IP}    ${SERVER_PORT_NAME}    ${SERVER_SG}
    Set Global Variable    ${SERVER_MAC_ADDR}  ${mac_address}
    Verify neutron port    ${mac_address}      ${SERVER_PORT_IP}    ${SERVER_SG_ID}

Test client neutron port-create and verify
    [Documentation]   Creates neutron port and verifies generated data.
    ${mac_address}    Create neutron port      ${CLIENT_PORT_IP}    ${CLIENT_PORT_NAME}    ${CLIENT_SG}
    Set Global Variable    ${CLIENT_MAC_ADDR}  ${mac_address}
    Verify neutron port    ${mac_address}      ${CLIENT_PORT_IP}    ${CLIENT_SG_ID}
    Run Keyword If        "${DEVSTACK_BRANCH}" == "stable/kilo"     Run Keywords
    ...  Verify Contract   ${GROUP_RULE_ID}      ${REMOTE_IP_PREFIX}  ${TENANT_ID}   AND
    ...  Check Endpoint Group Name and Selector  ${SERVER_SG_ID}      ${SERVER_SG}
    ...  ${TENANT_ID}    ${GROUP_RULE_ID}    provider-named-selector  AND
    ...  Check Endpoint Group Name and Selector  ${CLIENT_SG_ID}      ${CLIENT_SG}
    ...  ${TENANT_ID}    ${GROUP_RULE_ID}    consumer-named-selector

*** Keywords ***
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

Clean Suite
    [Documentation]  Clears Openstack. This is also helpful when debugging tests locally.
    ${output}   Write Commands Until Prompt     neutron net-delete net123
    Should Match Regexp    ${output}    Deleted|Removed
    Delete All Sessions
