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
${RESP_CODE_200}    200
${DESCRIPTION}    --description "new security group 1"
${VERIFY_DESCRIPTION}    new security group 1
${VERIFY_NAME}    SSH_UPDATED
${NAME_UPDATE}    --name SSH_UPDATED
${SECURITY_FALSE}    --port-security-enabled false
${SECURITY_TRUE}    --port-security-enabled true
${SEC_GROUP_PATH}      /restconf/config/neutron:neutron/security-groups/
${SEC_RULE_PATH}       /restconf/config/neutron:neutron/security-rules/
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
    ${sg_id} =    BuiltIn.Run Keyword    Create Security Group and Validate    ${SGP_SSH[0]}
    Create Security Rule and Validate    ${SGP_SSH[0]}    direction=${ADD_PARAMS[0]}    ethertype=${ADD_PARAMS[1]}    port_range_max=${ADD_PARAMS[3]}    port_range_min=${ADD_PARAMS[2]}    protocol=${ADD_PARAMS[4]}
    Get Flows
    Neutron Setup Creation    ${NETWORK[0]}    ${SUBNET[0]}    ${IP_SUBNET[0]}    ${PORT[0]}    ${PORT[1]}    ${SECURITY_GROUPS}
    ...    ${sg_id}
    Security group verification on Neutron port    ${PORT[0]}    ${sg_id}
    Security group verification on Neutron port    ${PORT[1]}    ${sg_id}
    Update Security Group Description and Verification    ${sg_id}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    Update Security Group Name and Verification    ${sg_id}    ${NAME_UPDATE}    ${VERIFY_NAME}

TC02_Create Security Rule with port_range_min > port_range_max
    [Documentation]    This test case validates the security group and rule creation with optional parameters Create Security Rule with port_range_min greater than port_range_max
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[1]}
    Get Flows
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[1]}    ${ADD_ARG_SSH5}    ${PORT_RANGE_ERROR}

TC03_Create Security Rule with port_range_min = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_min = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[2]}
    Get Flows
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[2]}    ${ADD_ARG_SSH6}    ${INVALID_PORT_RANGE_MIN}

TC04_Create Security Rule with port_range_max = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_max = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGP_SSH[3]}
    Get Flows
    Neutron Rule Creation With Invalid Parameters    ${SGP_SSH[3]}    ${ADD_ARG_SSH7}    ${INVALID_PORT_RANGE_MIN}

*** Keywords ***
Get Flows On Node
    [Arguments]    ${ip}=${EMPTY}
    [Documentation]    Get the Flows from DPN
    Builtin.Return From Keyword If    '${ip}' == '${EMPTY}'
    Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    Run Command On Remote System And Log    ${ip}    sudo ovs-ofctl dump-groups br-int -OOpenflow13

Get Flows
    [Documentation]    Get the Flows from DPNs
    : FOR    ${ip}    IN    @{OS_ALL_IPS}
    \    Get Flows On Node    ${ip}

Create Security Group and Validate
    [Arguments]    ${sg_ssh}
    [Documentation]    Create Security Group and Validate
    ${output}    ${sg_id} =    Neutron Security Group Create    ${sg_ssh}
    ${resp} =    RequestsLibrary.Get Request    session    ${SEC_GROUP_PATH}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE_200}
    Should Contain    ${resp.content}    ${sg_ssh}
    [Return]    ${sg_id}

Create Security Rule and Validate
    [Arguments]    ${sg_ssh}    &{Kwargs}
    [Documentation]    Create Security Rule and Validate
    ${output}    ${rule_id} =    OpenStackOperations.Neutron Security Group Rule Create    ${sg_ssh}
    ${resp} =    RequestsLibrary.Get Request    session    ${SEC_RULE_PATH}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE_200}
    Should Contain    ${resp.content}    ${rule_id}

Neutron Setup Creation
    [Arguments]    ${network}    ${subnet}    ${ip_subnet}    ${port1}    ${port2}    ${sg_groups}    ${sg_id}
    [Documentation]    Neutron Setup Creation
    ${net_id} =    OpenStackOperations.Create Network    ${network}
    ${subnet_id} =    OpenStackOperations.Create SubNet    ${network}    ${subnet}    ${ip_subnet}
    ${add_args} =    Set Variable    ${sg_groups} ${sg_id}
    ${port_id}    OpenStackOperations.Create Neutron Port With Additional Params    ${network}    ${port1}    ${add_args}
    ${port_id}    OpenStackOperations.Create Neutron Port With Additional Params    ${network}    ${port2}    ${add_args}

Security group verification on Neutron port
    [Arguments]    ${port}    ${sg_id}
    [Documentation]    Security group verification on Neutron port
    ${port_show} =    OpenStackOperations.Neutron Port Show    ${port}
    Should Contain    ${port_show}    ${sg_id}

Update Security Group Description and Verification
    [Arguments]    ${sg_id}    ${description}    ${verify_description}
    [Documentation]    Update Security Group Description and Verification
    OpenStackOperations.Neutron Security Group Update    ${sg_id}    ${description}
    ${output} =    OpenStackOperations.Neutron Security Group Show    ${sg_id}
    Should Contain    ${output}    ${verify_description}

Update Security Group Name and Verification
    [Arguments]    ${sg_id}    ${name_update}    ${verify_name}
    [Documentation]    Update Security Group Name and Verification
    OpenStackOperations.Neutron Security Group Update    ${sg_id}    ${name_update}
    ${output} =    OpenStackOperations.Neutron Security Group Show    ${sg_id}
    Should Contain    ${output}    ${verify_name}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP_PATH}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE_200}
    Should Contain    ${resp.content}    ${verify_name}

Neutron Rule Creation With Invalid Parameters
    [Arguments]    ${sg_name}    ${additional_args}    ${expected_error}
    [Documentation]    Neutron Rule Creation With Null Protocol
    ${cmd} =    Set Variable    neutron security-group-rule-create ${sg_name} ${additional_args}
    ${rc}    ${output} =    Run And Return Rc And Output    ${cmd}
    Log    ${output}
    Log    ${rc}
    Should Contain    ${output}    ${expected_error}
    Close Connection
