*** Settings ***
Documentation       Robot keyword library (Resource) for performing PCEP operations via restconf calls.
...
...                 Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 TODO: Remove all old keywords, update pcepuser.robot accordingly
...                 TODO: Add new KWs, update all pcep tests to use them.

Library             RequestsLibrary
Library             norm_json.py
Resource            ../variables/Variables.robot
Resource            TemplatedRequests.robot


*** Variables ***
${PCEP_VAR_FOLDER}      ${CURDIR}/../variables/tcpmd5user


*** Keywords ***
Setup_Pcep_Operations
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    RequestsLibrary.Create_Session
    ...    pcep_session
    ...    url=http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    headers=${HEADERS_XML}
    ...    auth=${AUTH}

Teardown_Pcep_Operations
    [Documentation]    Teardown to pair with Setup (otherwise no-op).
    RequestsLibrary.Delete_All_Sessions

Add_Xml_Lsp_Return_Json
    [Documentation]    Instantiate LSP according to XML data and return response (json) text.
    [Arguments]    ${xml_data}
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:add-lsp    ${xml_data}
    RETURN    ${response}

Update_Xml_Lsp_Return_Json
    [Documentation]    Update LSP according to XML data and return response (json) text.
    [Arguments]    ${xml_data}
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:update-lsp    ${xml_data}
    RETURN    ${response}

Remove_Xml_Lsp_Return_Json
    [Documentation]    Remove LSP according to XML data and return response (json) text.
    [Arguments]    ${xml_data}
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:remove-lsp    ${xml_data}
    RETURN    ${response}

Operate_Xml_Lsp_Return_Json
    [Documentation]    Post XML data to given pcep-operations URI, check status_code is 200 and return response text (JSON).
    [Arguments]    ${uri_part}    ${xml_data}
    ${uri_path}=    BuiltIn.Set_Variable    /rests/operations/${uri_part}
    ${response}=    RequestsLibrary.POST On Session
    ...    pcep_session
    ...    url=${uri_path}
    ...    data=${xml_data}
    ...    expected_status=anything
    Log    ${xml_data}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${response.status_code}
    RETURN    ${response.text}

Pcep_Json_Is_Success
    [Documentation]    Given text should be equal to successfull json response.
    [Arguments]    ${text}
    Should_Be_Equal_As_Strings    ${text}    {"output":{}}

Pcep_Json_Is_Refused
    [Documentation]    Given text should be equal to json response when device refuses tunnel removal.
    [Arguments]    ${actual_raw}
    ${expected_raw}=    BuiltIn.Set_Variable
    ...    {"network-topology-pcep:output":{"error":[{"error-object":{"ignore":false,"processing-rule":false,"type":19,"value":9}}],"failure":"failed"}}
    # TODO: Is that JSON worth referencing pcepuser variables from this library?
    ${expected_normalized}=    norm_json.normalize_json_text    ${expected_raw}
    ${actual_normalized}=    norm_json.normalize_json_text    ${actual_raw}
    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}
    # TODO: Would the diff approach be more useful?

Pcep_Topology_Precondition
    [Documentation]    Compare current pcep-topology to empty one.
    ...    Timeout is long enough to see that pcep is ready.
    [Arguments]    ${session}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    300s
    ...    1s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${PCEP_VAR_FOLDER}/default_off
    ...    session=${session}
    ...    verify=True
