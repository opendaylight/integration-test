*** Settings ***
Documentation     Test Suite for Neutron Security Group
Suite Setup       BuiltIn.Run Keywords    SetupUtils.Setup_Utils_For_Setup_And_Teardown
...               AND    DevstackUtils.Devstack Suite Setup
Suite Teardown    OpenStackOperations.OpenStack Suite Teardown
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     OpenStackOperations.Get Test Teardown Debugs
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
${SEC_GROUP_API}    /restconf/config/neutron:neutron/security-groups/
${SEC_RULE_API}    /restconf/config/neutron:neutron/security-rules/
${ADD_ARG_SSH}    --direction ingress --ethertype IPv4 --port_range_max 22 --port_range_min 22 --protocol tcp
@{NETWORKS}       sgs_net_1
@{SUBNETS}        sgs_sub_1
@{IP_SUBNETS}     61.2.1.0/24
@{PORTS}          sgs_port_1    sgs_port_2
${SECURITY_GROUPS}    --security-group
@{SGS}            sgs_sg_1    sgs_sg_2    sgs_sg_3    sgs_sg_4
${SG_UPDATED}     SSH_UPDATED
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
    ${sg_id} =    BuiltIn.Run Keyword    Create Security Group and Validate    ${SGS[0]}
    Create Security Rule and Validate    ${SGS[0]}    direction=${ADD_PARAMS[0]}    ethertype=${ADD_PARAMS[1]}    port_range_max=${ADD_PARAMS[3]}    port_range_min=${ADD_PARAMS[2]}    protocol=${ADD_PARAMS[4]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Setup Creation    ${NETWORKS[0]}    ${SUBNETS[0]}    ${IP_SUBNETS[0]}    ${PORTS[0]}    ${PORTS[1]}    ${SECURITY_GROUPS}
    ...    ${sg_id}
    Security group verification on Neutron port    ${PORTS[0]}    ${sg_id}
    Security group verification on Neutron port    ${PORTS[1]}    ${sg_id}
    Update Security Group Description and Verification    ${sg_id}    ${DESCRIPTION}    ${VERIFY_DESCRIPTION}
    Update Security Group Name and Verification    ${sg_id}    ${NAME_UPDATE}    ${VERIFY_NAME}

TC02_Create Security Rule with port_range_min > port_range_max
    [Documentation]    This test case validates the security group and rule creation with optional parameters Create Security Rule with port_range_min greater than port_range_max
    [Tags]    Regression
    Create Security Group and Validate    ${SGS[1]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGS[1]}    ${ADD_ARG_SSH5}    ${PORT_RANGE_ERROR}

TC03_Create Security Rule with port_range_min = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_min = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGS[2]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGS[2]}    ${ADD_ARG_SSH6}    ${INVALID_PORT_RANGE_MIN}

TC04_Create Security Rule with port_range_max = -1
    [Documentation]    This test case validates the security group and rule creation with optional parameters, Create Security Rule with port_range_max = -1
    [Tags]    Regression
    Create Security Group and Validate    ${SGS[3]}
    Get Flows    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    Neutron Rule Creation With Invalid Parameters    ${SGS[3]}    ${ADD_ARG_SSH7}    ${INVALID_PORT_RANGE_MIN}

*** Keywords ***
Get Flows
    [Arguments]    ${OS_COMPUTE_1_IP}    ${OS_COMPUTE_2_IP}
    [Documentation]    Get the Flows from DPN1 and DPN2
    ${resp} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    ${resp} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_1_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13
    ${resp} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-flows br-int -O OpenFlow13
    ${resp} =    Utils.Run Command On Remote System And Log    ${OS_COMPUTE_2_IP}    sudo ovs-ofctl dump-groups br-int -OOpenflow13

Create Security Group and Validate
    [Arguments]    ${sg_ssh}
    ${output}    ${sg_id} =    OpenStackOperations.Neutron Security Group Create    ${sg_ssh}
    ${sec_groups} =    BuiltIn.Create List    ${sg_ssh}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${SEC_GROUP_API}    ${sec_groups}
    [Return]    ${sg_id}

Create Security Rule and Validate
    [Arguments]    ${sg_ssh}    &{Kwargs}
    ${output}    ${rule_id} =    OpenStackOperations.Neutron Security Group Rule Create    ${sg_ssh}
    ${rule_ids} =    BuiltIn.Create List    ${rule_id}
    BuiltIn.Wait Until Keyword Succeeds    10s    2s    Utils.Check For Elements At URI    ${SEC_RULE_API}    ${rule_ids}

Neutron Setup Creation
    [Arguments]    ${network}    ${subnet}    ${ip_subnet}    ${port1}    ${port2}    ${sg_groups}
    ...    ${sg_id}
    ${net_id} =    OpenStackOperations.Create Network    ${network}
    ${subnet_id} =    OpenStackOperations.Create SubNet    ${network}    ${subnet}    ${ip_subnet}
    ${add_args} =    BuiltIn.Set Variable    ${sg_groups} ${sg_id}
    ${port_id}    OpenStackOperations.Create Neutron Port With Additional Params    ${network}    ${port1}    ${add_args}
    ${port_id}    OpenStackOperations.Create Neutron Port With Additional Params    ${network}    ${port2}    ${add_args}

Security group verification on Neutron port
    [Arguments]    ${port}    ${sg_id}
    ${port_show} =    OpenStackOperations.Neutron Port Show    ${port}
    BuiltIn.Should Contain    ${port_show}    ${sg_id}

Update Security Group Description and Verification
    [Arguments]    ${sg_id}    ${description}    ${verify_description}
    OpenStackOperations.Neutron Security Group Update    ${sg_id}    ${description}
    ${output} =    OpenStackOperations.Neutron Security Group Show    ${sg_id}
    BuiltIn.Should Contain    ${output}    ${verify_description}

Update Security Group Name and Verification
    [Arguments]    ${sg_id}    ${name_update}    ${verify_name}
    OpenStackOperations.Neutron Security Group Update    ${sg_id}    ${name_update}
    ${output} =    OpenStackOperations.Neutron Security Group Show    ${sg_id}
    Should Contain    ${output}    ${verify_name}
    ${resp}    RequestsLibrary.Get Request    session    ${SEC_GROUP_API}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    ${RESP_CODE_200}
    BuiltIn.Should Contain    ${resp.content}    ${verify_name}

Neutron Rule Creation With Invalid Parameters
    [Arguments]    ${sg_name}    ${additional_args}    ${expected_error}
    ${rc}    ${output} =    OperatingSystem.Run And Return Rc And Output    neutron security-group-rule-create ${sg_name} ${additional_args}
    BuiltIn.Log    ${output}
    BuiltIn.Should Contain    ${output}    ${expected_error}
    SSHLibrary.Close Connection
