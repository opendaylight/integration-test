*** Settings ***
Documentation     Robot keyword library (Resource) for common handling of data chnage counter.
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
CHANGE_COUNTER_TEMPLATE_FOLDER    ${CURDIR}/../variables/bgpuser

*** Keywords ***
CC_Setup
    [Documentation]    Initialize dependency libraries.
    ConfigViaRestconf.Setup_Config_Via_Restconf
    ScalarClosures.SC_Setup
    WaitUtils.WU_Setup
    ${counter} =    ScalarClosures.Closure_From_Keyword_And_Arguments    Get_Change_Count
    BuiltIn.Set_Suite_Variable    ${ChangeCounter__getter}    ${counter}
    ${validator} =    ScalarClosures.Closure_From_Keyword_And_Arguments    state_holder    data_holder
    BuiltIn.Set_Suite_Variable    ${ChangeCounter__validator}    ${validator}

Get_Change_Count
    [Documentation]    GET data change request, assert status 200, return the value.
    ${response} =    RequestsLibrary.Get_Request    operational    data-change-counter:data-change-counter
    BuiltIn.Shoule_Be_Equal    ${response.status_code}    ${200}
    [Return]    ${response.text}

Reconfigure_Topology_Name
    [Arguments]    ${topology_name}=example-linkstate-topology
    [Documentation]    Configure data change counter to count transactions affecting
    ...    ${topology_name} instead of previously configured topology name.
    ${template_as_string}=    BuiltIn.Set_Variable    {'TOPOLOGY_NAME': '${topology_name}'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${CHANGE_CONTER_TEMPLATE_FOLDER}${/}change_counter    ${template_as_string}

Stability_Safe_Stateful_Validator_As_Keyword
    [Arguments]    ${old_state}    ${data}
    [Documentation]    Report failure if minimum not reached or data value changed from last time.
    ${new_state} =    BuiltIn.Set_Variable    ${data}
    BuiltIn.Return_From_Keyword_If    ${data} < ${valid_minimum}    ${new_state}    FAIL    Minimum not reached.
    BuiltIn.Return_From_Keyword_If    ${data} != ${old_state}    ${new_state}    FAIL    Data value has changed.
    [Return]    ${new_state}    PASS    Validated stable: ${data}

Wait_For_Topology_To_Become_Stable
    [Arguments]    ${timeout}=60s    ${period}=1s    ${repetitions}=4    ${count_to_overcome}=-1
    [Documentation]    Each ${period} get count. After ${repetitions} of stable value above ${count_to_overcome} within ${timeout}, Return validator output. Fail early on getter error.
    ${result} =    WaitUtils.Wait_For_Getter_Error_Or_Safe_Stateful_Validator_Consecutive_Success    timeout=${timeout}    period=${period}    count=${repetitions}    getter=${ChangeCounter__getter}    safe_validator=${ChangeCounter__validator}    initial_state=${count_to_overcome}
    [Return]    ${result}
