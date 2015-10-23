*** Settings ***
Documentation     Robot keyword library (Resource) for common handling of data change counter.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This resource assumes that RequestsLibrary has open a connection named "operational"
...               which points to (an analogue of) http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/${OPERATIONAL_API}
Library           RequestsLibrary
Resource          ${CURDIR}/ConfigViaRestconf.robot
Resource          ${CURDIR}/ScalarClosures.robot
Resource          ${CURDIR}/WaitUtils.robot

*** Variables ***
${CHANGE_COUNTER_TEMPLATE_FOLDER}    ${CURDIR}/../variables/bgpuser

*** Keywords ***
CC_Setup
    [Documentation]    Initialize dependency libraries.
    ConfigViaRestconf.Setup_Config_Via_Restconf
    WaitUtils.WU_Setup    # includes ScalarClosures.SC_Setup
    ${counter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Change_Count
    BuiltIn.Set_Suite_Variable    ${ChangeCounter__getter}    ${counter}

Get_Change_Count
    [Documentation]    GET data change request, assert status 200, return the value.
    ${response} =    RequestsLibrary.Get_Request    operational    data-change-counter:data-change-counter
    BuiltIn.Should_Be_Equal    ${response.status_code}    ${200}    Got status: ${response.status_code} and message: ${response.text}
    # TODO: The following line can be insecure. Should we use regexp instead?
    ${count} =    BuiltIn.Evaluate    ${response.text}["data-change-counter"]["count"]
    [Return]    ${count}

Reconfigure_Topology_Name
    [Arguments]    ${topology_name}=example-linkstate-topology
    [Documentation]    Configure data change counter to count transactions affecting
    ...    ${topology_name} instead of previously configured topology name.
    ${template_as_string}=    BuiltIn.Set_Variable    {'TOPOLOGY_NAME': '${topology_name}'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${CHANGE_COUNTER_TEMPLATE_FOLDER}${/}change_counter    ${template_as_string}

Wait_For_Change_Count_To_Become_Stable
    [Arguments]    ${timeout}=60s    ${period}=1s    ${repetitions}=4    ${count_to_overcome}=-1
    [Documentation]    Each ${period} get count. After ${repetitions} of constant value above ${count_to_overcome} within ${timeout}, Return validator output. Fail early on getter error.
    ${validator} =    WaitUtils.Create_Limiting_Stability_Safe_Stateful_Validator_From_Value_To_Overcome    maximum_invalid=${count_to_overcome}
    ${result} =    WaitUtils.Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=${timeout}    period=${period}    count=${repetitions}    getter=${ChangeCounter__getter}    safe_validator=${validator}
    ...    initial_state=${count_to_overcome}
    [Return]    ${result}
