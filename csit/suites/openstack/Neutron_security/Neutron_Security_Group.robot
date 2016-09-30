*** Settings ***
Documentation     Test Suite for Neutron Security Group
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           json
Resource          ../../../libraries/DevstackUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${RESP_CODE}      200
${DSG_NAME}       8cda7416-6e93-4b3d-93de-65dfa38d8399
${DESCRIPTION}    --description "new security group 1"
${VERIFY_DESCRIPTION}    new security group 1
${VERIFY_NAME}    SSH_UPDATED
${NAME_UPDATE}    --name SSH_UPDATED
${SECURITY_FALSE}    --port-security-enabled false
${SECURITY_TRUE}    --port-security-enabled true
${SEC_GROUP}      /restconf/config/neutron:neutron/security-groups/
${SEC_RULE}       /restconf/config/neutron:neutron/security-rules/
${ADD_ARG_SSH}    --direction ingress --ethertype IPv4 --port_range_max 22 --port_range_min 22 --protocol tcp
${NETWORK3}       net3
${SUBNET3}        sub3
${IP_SUBNET12}    20.2.1.0/24
${PORT5}          port05
${PORT6}          port06
${SECURITY_GROUPS}    --security-group
${SGP_SSH1}       SSH1
${ADD_ARG_SSH5}    --direction ingress --ethertype IPv4 --port_range_max 20 --port_range_min 25 --protocol tcp
${SGP_SSH2}       SSH2
${ADD_ARG_SSH6}    --direction ingress --ethertype IPv4 --port_range_max 25 --port_range_min -1 --protocol tcp
${SGP_SSH3}       SSH3
${ADD_ARG_SSH7}    --direction ingress --ethertype IPv4 --port_range_max -1 --port_range_min 20 --protocol tcp

*** Testcases ***
TC01_Update Security Group description and Name
    [Documentation]    Update Security Group description and name
    [Tags]    Regression
    Log    "Creating security Group and verification"
    Create Security Group and Validate    ${SGP_SSH}
    Log    "Creating security Rule and verification"
    Create Security Rule and Validate    ${SGP_SSH}    ${ADD_ARG_SSH}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Log    "Creating neutron setup as network subnet port"
    Neutron Setup Creation    ${NETWORK3}    ${SUBNET3}    ${IP_SUBNET12}    ${PORT5}    ${PORT6}    ${SECURITY_GROUPS}
    ...    ${SGP_ID}
    Log    "Securuty group verification on Neutron port"
    Securuty group verification on Neutron port    ${PORT5}    ${PORT6}    ${SGP_ID}
    Log    "Update Security Group Description and Verification"
    Update Security Group Description and Verification    ${SGP_ID}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    Log    "Update Security Group Name and Verification"
    Update Security Group Name and Verification    ${SGP_ID}    ${NAME_UPDATE}    ${VERIFY_NAME}

TC02_Create Security Rule with port_range_min > port_range_max
    [Documentation]    Create Security Rule with port_range_min > port_range_max
    [Tags]    Regression
    Log    "Creating security Group and verification"
    Create Security Group and Validate    ${SGP_SSH1}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Log    "Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation"
    Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation    ${SGP_SSH1}    ${ADD_ARG_SSH5}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}

TC03_Create Security Rule with port_range_min = -1
    [Documentation]    7.1.15 Create Security Rule with port_range_min = -1 This Test case covers 1 testcases ids are SF96_UC3_TC15
    [Tags]    Regression
    Log    "Creating security Group and verification"
    Create Security Group and Validate    ${SGP_SSH2}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Log    "Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation"
    Neutron Rule Creation With Invalid Port Ranges    ${SGP_SSH2}    ${ADD_ARG_SSH6}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}

TC04_Create Security Rule with port_range_max = -1
    [Documentation]    Create Security Rule with port_range_max = -1
    [Tags]    Regression
    Log    "Creating security Group and verification"
    Create Security Group and Validate    ${SGP_SSH3}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Log    "Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation"
    Neutron Rule Creation With Invalid Port Ranges    ${SGP_SSH3}    ${ADD_ARG_SSH7}
    Log    "Fetching the flows from DPN1 and DPN2"
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}

*** Keywords ***
Get Flows
    [Arguments]    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    [Documentation]    Get the Flows from DPN1 and DPN2
    Log    "Fetching the flows from DPN1"
    ${resp}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    Log    ${resp}
    Log    "Fetching the Groups from DPN1"
    ${resp}=    Run Command On Remote System    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    Log    ${resp}
    Log    "Fetching the flows from DPN2"
    ${resp}=    Run Command On Remote System    ${OS_COMPUTE_1_IP1}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    Log    ${resp}
    Log    "Fetching the Groups from DPN2"
    ${resp}=    Run Command On Remote System    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    Log    ${resp}

Create Security Group and Validate
    [Arguments]    ${SGP_SSH}
    [Documentation]    Create Security Group and Validate
    Log    "Creating security Group I.E SSH"
    ${OUTPUT}    ${SGP_ID}    Neutron Security Group Create    ${SGP_SSH}
    Set Global Variable    ${SGP_ID}
    Log    ${OUTPUT}
    Log    ${SGP_ID}
    Log    "Verifying the security group"
    ${resp}    RequestsLibrary.Get    session    ${SEC_GROUP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${SGP_SSH}

Create Security Rule and Validate
    [Arguments]    ${SGP_SSH}    ${ADD_ARG_SSH}
    [Documentation]    Create Security Rule and Validate
    Log    "Creating the Rules for SSH groups"
    ${OUTPUT}    ${RULE_ID}    Neutron Security Group Rule Create    ${SGP_SSH}    ${ADD_ARG_SSH}
    Log    ${OUTPUT}
    Log    ${RULE_ID}
    Set Global Variable    ${RULE_ID}
    Log    "Verifying the security Rule"
    ${resp}    RequestsLibrary.Get    session    ${SEC_RULE}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${RULE_ID}

Neutron Setup Creation
    [Arguments]    ${NETWORK}    ${SUBNET}    ${IP_SUBNET}    ${PORT1}    ${PORT2}    ${SECURITY_GROUPS}
    ...    ${SGP_ID}
    [Documentation]    Neutron Setup Creation
    Log    "Creating networks"
    ${net_id}    Create Network    ${NETWORK}
    Log    ${net_id}
    Set Global Variable    ${net_id}
    Log    "Creating subnets"
    ${subnet_id}    Create SubNet    ${NETWORK}    ${SUBNET}    ${IP_SUBNET}
    Log    ${subnet_id}
    Set Global Variable    ${subnet_id}
    ${port_id}    Create Neutron Port With SecurityGroups    ${NETWORK}    ${PORT1}    ${SECURITY_GROUPS}    ${SGP_ID}
    Log    ${port_id}
    Log    "Creating ports"
    ${port_id}    Create Neutron Port With SecurityGroups    ${NETWORK}    ${PORT2}    ${SECURITY_GROUPS}    ${SGP_ID}
    Log    ${port_id}

Securuty group verification on Neutron port
    [Arguments]    ${PORT5}    ${PORT6}    ${SGP_ID}
    [Documentation]    Securuty group verification on Neutron port
    Log    "security group verification"
    ${PORT_SHOW}    Neutron Port Show    ${PORT5}
    Log    ${PORT_SHOW}
    Should Contain    ${PORT_SHOW}    ${SGP_ID}
    Log    "security group verification"
    ${PORT_SHOW}    Neutron Port Show    ${PORT6}
    Log    ${PORT_SHOW}
    Should Contain    ${PORT_SHOW}    ${SGP_ID}

Update Security Group Description and Verification
    [Arguments]    ${SGP_ID}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    [Documentation]    Update Security Group Description and Verification
    Log    "Update Security Group Description"
    ${output}    Neutron Security Group Update    ${SGP_ID}    ${DESCRIPTION}
    Log    "Verification of Description"
    ${output}    Neutron Security Group Show    ${SGP_ID}
    Log    ${output}
    Should Contain    ${output}    ${VERIFY_DESCRIPTION}

Update Security Group Name and Verification
    [Arguments]    ${SGP_ID}    ${NAME_UPDATE}    ${VERIFY_NAME}
    [Documentation]    Update Security Group Name and Verification
    Log    "Update Security Group Name"
    ${output}    Neutron Security Group Update    ${SGP_ID}    ${NAME_UPDATE}
    Log    "Verification of Updated Name"
    ${output}    Neutron Security Group Show    ${SGP_ID}
    Log    ${output}
    Should Contain    ${output}    ${VERIFY_NAME}
    Log    "Verification of Updated Name via Rest"
    ${resp}    RequestsLibrary.Get    session    ${SEC_GROUP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${VERIFY_NAME}

Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation
    [Arguments]    ${SecurityGroupName}    ${additional_args}
    [Documentation]    Neutron Rule Creation With Port Range Min Grt Port Range Max and Validation
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-rule-create ${SecurityGroupName} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Should Contain    ${output}    ${PORT_RANGE_ERROR}
    Close Connection
    [Return]    ${OUTPUT}

Neutron Rule Creation With Invalid Port Ranges
    [Arguments]    ${SecurityGroupName}    ${additional_args}
    [Documentation]    Neutron Rule Creation With Invalid Port Ranges
    ${devstack_conn_id}=    Get ControlNode Connection
    Switch Connection    ${devstack_conn_id}
    ${cmd}=    Set Variable    neutron security-group-rule-create ${SecurityGroupName} ${additional_args}
    Log    ${cmd}
    ${OUTPUT}=    Write Commands Until Prompt    ${cmd}    30s
    Log    ${OUTPUT}
    Should Contain    ${output}    ${INVALID_PORT_RANGE_MIN}
    Close Connection
    [Return]    ${OUTPUT}
