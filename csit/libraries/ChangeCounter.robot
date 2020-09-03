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
...               This resource creates a "default" session using TemplatedRequests.Create_Default_Session
...               which points to (an analogue of) http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
Library           RequestsLibrary
Resource          ${CURDIR}/CompareStream.robot
Resource          ${CURDIR}/ScalarClosures.robot
Resource          ${CURDIR}/TemplatedRequests.robot
Resource          ${CURDIR}/WaitUtils.robot

*** Variables ***
${CHANGE_COUNTER_TEMPLATE_FOLDER}    ${CURDIR}/../variables/bgpuser
${CC_DATA_CHANGE_COUNTER_URL}    /restconf/operational/data-change-counter:data-change-counter

*** Keywords ***
CC_Setup
    [Documentation]    Initialize dependency libraries.
    TemplatedRequests.Create_Default_Session
    WaitUtils.WU_Setup    # includes ScalarClosures.SC_Setup
    ${counter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Change_Count
    BuiltIn.Set_Suite_Variable    ${ChangeCounter__getter}    ${counter}

Get_Change_Count
    [Arguments]    ${session}=operational
    [Documentation]    GET data change request, assert status 200, return the value.
    ${response} =    RequestsLibrary.Get_Request    ${session}    ${CC_DATA_CHANGE_COUNTER_URL}
    BuiltIn.Should_Be_Equal    ${response.status_code}    ${200}    Got status: ${response.status_code} and message: ${response.text}
    # CompareStream.Set_Variable_If_At_Least_Else cannot be used direcly, because ${response.text}["data-change-counter"]["count"] would be
    # evaluated before the stream comparison and it causes failures
    BuiltIn.Log    ${response.text}
    ${count} =    BuiltIn.Evaluate    json.loads('${response.text}')["data-change-counter"]["counter"][0]["count"]    modules=json
    [Return]    ${count}

Reconfigure_Topology_Name
    [Arguments]    ${topology_name}=example-linkstate-topology
    [Documentation]    Configure data change counter to count transactions affecting
    ...    ${topology_name} instead of previously configured topology name.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    TOPOLOGY_NAME=${topology_name}
    TemplatedRequests.Put_As_Xml_Templated    ${CHANGE_COUNTER_TEMPLATE_FOLDER}${/}change_counter    mapping=${mapping}

Wait_For_Change_Count_To_Become_Stable
    [Arguments]    ${timeout}=60s    ${period}=1s    ${repetitions}=4    ${count_to_overcome}=-1
    [Documentation]    Each ${period} get count. After ${repetitions} of constant value above ${count_to_overcome} within ${timeout}, Return validator output. Fail early on getter error.
    ${validator} =    WaitUtils.Create_Limiting_Stability_Safe_Stateful_Validator_From_Value_To_Overcome    maximum_invalid=${count_to_overcome}
    ${result} =    WaitUtils.Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=${timeout}    period=${period}    count=${repetitions}    getter=${ChangeCounter__getter}    safe_validator=${validator}
    ...    initial_state=${count_to_overcome}
    [Return]    ${result}
