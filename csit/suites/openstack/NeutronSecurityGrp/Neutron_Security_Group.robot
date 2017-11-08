*** Settings ***
Documentation     Test Suite for Neutron Security Group
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    Close All Connections
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     Get Test Teardown Debugs
Library           SSHLibrary
Library           OperatingSystem
Library           RequestsLibrary
Library           json
Resource          ../../../libraries/DevstackUtils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${RESP_CODE}      200
${DESCRIPTION}    --description "new security group 1"
${VERIFY_DESCRIPTION}    new security group 1
${VERIFY_NAME}    SSH_UPDATED
${NAME_UPDATE}    --name SSH_UPDATED
${SECURITY_FALSE}    --port-security-enabled false
${SECURITY_TRUE}    --port-security-enabled true
${SEC_GROUP}      /restconf/config/neutron:neutron/security-groups/
${SEC_RULE}       /restconf/config/neutron:neutron/security-rules/
${ADD_ARG_SSH}    --direction ingress --ethertype IPv4 --port_range_max 22 --port_range_min 22 --protocol tcp
@{NETWORK}        net1    net2    net3    net4    net5    net6    net7
...               net8    net9    net10
@{SUBNET}         sub1    sub2    sub3    sub4    sub5    sub6    sub7
...               sub8    sub9    sub10
@{IP_SUBNET}      20.2.1.0/24    20.2.2.0/24    20.2.3.0/24    20.2.4.0/24    20.2.5.0/24    20.2.6.0/24
@{PORT}           port01    port02    port03    port04    port05    port06    port07
...               port08    port09    port10
${SECURITY_GROUPS}    --security-group
@{SGP_SSH}        SSH1    SSH2    SSH3    SSH4    SSH5    SSH6    SSH7
...               SSH8    SSH9    SSH10
${ADD_ARG_SSH5}    --direction ingress --ethertype IPv4 --port_range_max 20 --port_range_min 25 --protocol tcp
@{ADD_PARAMS}     ingression    IPv4    20    25    tcp
${ADD_ARG_SSH6}    --direction ingress --ethertype IPv4 --port_range_max 25 --port_range_min -1 --protocol tcp
${ADD_ARG_SSH7}    --direction ingress --ethertype IPv4 --port_range_max -1 --port_range_min 20 --protocol tcp
${PORT_RANGE_ERROR}    For TCP/UDP protocols, port_range_min must be <= port_range_max
${INVALID_PORT_RANGE_MIN}    Invalid value for port

*** Testcases ***
TC01_Update Security Group description and Name
    [Documentation]    This test case validates the security group creation with optional parameter description, Update Security Group description and name
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[0]}
    Create Security Rule and Validate    ${SGP_SSH[0]}    direction=${ADD_PARAMS[0]}    ethertype=${ADD_PARAMS[1]}    port_range_max=${ADD_PARAMS[3]}    port_range_min=${ADD_PARAMS[2]}    protocol=${ADD_PARAMS[4]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Setup Creation    ${NETWORK[0]}    ${SUBNET[0]}    ${IP_SUBNET[0]}    ${PORT[0]}    ${PORT[1]}    ${SECURITY_GROUPS}
    ...    ${SGP_ID}
    Security group verification on Neutron port    ${PORT[0]}    ${SGP_ID}
    Security group verification on Neutron port    ${PORT[1]}    ${SGP_ID}
    Update Security Group Description and Verification    ${SGP_ID}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    Update Security Group Name and Verification    ${SGP_ID}    ${NAME_UPDATE}    ${VERIFY_NAME}

TC02_Create Security Rule with port_range_min > port_range_max
    [Documentation]    This test case validates the security group and rule creation with optional parameters Create Security Rule with port_range_min greater than port_range_max
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[1]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[1]}    ${ADD_ARG_SSH5}    ${PORT_RANGE_ERROR}

TC03_Create Security Rule with port_range_min = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_min = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[2]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[2]}    ${ADD_ARG_SSH6}    ${INVALID_PORT_RANGE_MIN}

TC04_Create Security Rule with port_range_max = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_max = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[3]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[3]}    ${ADD_ARG_SSH7}    ${INVALID_PORT_RANGE_MIN}

*** Keywords ***
Get Flows
    [Arguments]    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    [Documentation]    Get the Flows from DPN1 and DPN2
    ${resp}=    Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    ${resp}=    Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    ${resp}=    Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    ${resp}=    Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13

Create Security Group and Validate
    [Arguments]    ${SGP_SSH}
    [Documentation]    Create Security Group and Validate
    ${OUTPUT}    ${SGP_ID}    Neutron Security Group Create    ${SGP_SSH}
    Set Global Variable    ${SGP_ID}
    Log    "Verifying the security group"
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${SGP_SSH}

Create Security Rule and Validate
    [Arguments]    ${SGP_SSH}    &{Kwargs}
    [Documentation]    Create Security Rule and Validate
    ${OUTPUT}    ${RULE_ID}    Neutron Security Group Rule Create    ${SGP_SSH}
    Set Global Variable    ${RULE_ID}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_RULE}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${RULE_ID}

Neutron Setup Creation
    [Arguments]    ${NETWORK}    ${SUBNET}    ${IP_SUBNET}    ${PORT1}    ${PORT2}    ${SECURITY_GROUPS}
    ...    ${SGP_ID}
    [Documentation]    Neutron Setup Creation
    ${net_id}    Create Network    ${NETWORK}
    Set Global Variable    ${net_id}
    ${subnet_id}    Create SubNet    ${NETWORK}    ${SUBNET}    ${IP_SUBNET}
    Set Global Variable    ${subnet_id}
    ${ADD_ARGMS}=    Set Variable    ${SECURITY_GROUPS} ${SGP_ID}
    ${port_id}    Create Neutron Port With Additional Params    ${NETWORK}    ${PORT1}    ${ADD_ARGMS}
    ${port_id}    Create Neutron Port With Additional Params    ${NETWORK}    ${PORT2}    ${ADD_ARGMS}

Security group verification on Neutron port
    [Arguments]    ${PORT}    ${SGP_ID}
    [Documentation]    Security group verification on Neutron port
    ${PORT_SHOW}    Neutron Port Show    ${PORT}
    Should Contain    ${PORT_SHOW}    ${SGP_ID}

Update Security Group Description and Verification
    [Arguments]    ${SGP_ID}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    [Documentation]    Update Security Group Description and Verification
    ${output}    Neutron Security Group Update    ${SGP_ID}    ${DESCRIPTION}
    ${output}    Neutron Security Group Show    ${SGP_ID}
    Should Contain    ${output}    ${VERIFY_DESCRIPTION}

Update Security Group Name and Verification
    [Arguments]    ${SGP_ID}    ${NAME_UPDATE}    ${VERIFY_NAME}
    [Documentation]    Update Security Group Name and Verification
    ${output}    Neutron Security Group Update    ${SGP_ID}    ${NAME_UPDATE}
    ${output}    Neutron Security Group Show    ${SGP_ID}
    Should Contain    ${output}    ${VERIFY_NAME}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE}
    Should Contain    ${resp.content}    ${VERIFY_NAME}

Neutron Rule Creation With Invalid Parameters
    [Arguments]    ${SecurityGroupName}    ${additional_args}    ${EXPECTED_ERROR}
    [Documentation]    Neutron Rule Creation With Null Protocol
    ${rc}    ${output}=    Run And Return Rc And Output    neutron security-group-rule-create ${SecurityGroupName} ${additional_args}
    Log    ${output}
    Should Contain    ${output}    ${EXPECTED_ERROR}
    Close Connection
    [Return]    ${output}
