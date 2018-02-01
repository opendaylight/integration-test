*** Settings ***
Documentation     Robot keyword library (Resource) for performing PCEP operations via restconf calls.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               TODO: Remove all old keywords, update pcepuser.robot accordingly
...               TODO: Add new KWs, update all pcep tests to use them.
Library           RequestsLibrary
Library           norm_json.py
Resource          ../variables/Variables.robot
Resource          TemplatedRequests.robot

*** Variables ***
${PCEP_VAR_FOLDER}    ${CURDIR}/../variables/tcpmd5user

*** Keywords ***
Setup_Pcep_Operations
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    # Do not append slash at the end uf URL, Requests would add another, resulting in error.
    Create_Session    pcep_session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}/restconf/operations    headers=${HEADERS_XML}    auth=${AUTH}

Teardown_Pcep_Operations
    [Documentation]    Teardown to pair with Setup (otherwise no-op).
    Log    TODO: The following line does not seem to be implemented by RequestsLibrary. Look for a workaround.
    # Delete_Session    pcep_session

Add_Xml_Lsp_Return_Json
    [Arguments]    ${xml_data}
    [Documentation]    Instantiate LSP according to XML data and return response (json) text.
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:add-lsp    ${xml_data}
    [Return]    ${response}

Update_Xml_Lsp_Return_Json
    [Arguments]    ${xml_data}
    [Documentation]    Update LSP according to XML data and return response (json) text.
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:update-lsp    ${xml_data}
    [Return]    ${response}

Remove_Xml_Lsp_Return_Json
    [Arguments]    ${xml_data}
    [Documentation]    Remove LSP according to XML data and return response (json) text.
    # Also no slash here
    ${response}=    Operate_Xml_Lsp_Return_Json    network-topology-pcep:remove-lsp    ${xml_data}
    [Return]    ${response}

Operate_Xml_Lsp_Return_Json
    [Arguments]    ${uri_part}    ${xml_data}
    [Documentation]    Post XML data to given pcep-operations URI, check status_code is 200 and return response text (JSON).
    ${response}=    RequestsLibrary.Post Request    pcep_session    ${uri_part}    data=${xml_data}
    Log    ${xml_data}
    Should_Be_Equal_As_Strings    ${response.status_code}    200
    [Return]    ${response.text}

Pcep_Json_Is_Success
    [Arguments]    ${text}
    [Documentation]    Given text should be equal to successfull json response.
    Should_Be_Equal_As_Strings    ${text}    {"output":{}}

Pcep_Json_Is_Refused
    [Arguments]    ${actual_raw}
    [Documentation]    Given text should be equal to json response when device refuses tunnel removal.
    ${expected_raw}=    BuiltIn.Set_Variable    {"output":{"error":[{"error-object":{"ignore":false,"processing-rule":false,"type":19,"value":9}}],"failure":"failed"}}
    # TODO: Is that JSON worth referencing pcepuser variables from this library?
    ${expected_normalized}=    norm_json.normalize_json_text    ${expected_raw}
    ${actual_normalized}=    norm_json.normalize_json_text    ${actual_raw}
    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}
    # TODO: Would the diff approach be more useful?

Pcep_Topology_Precondition
    [Arguments]    ${session}
    [Documentation]    Compare current pcep-topology to empty one.
    ...    Timeout is long enough to see that pcep is ready.
    BuiltIn.Wait_Until_Keyword_Succeeds    300s    1s    TemplatedRequests.Get_As_Json_Templated    ${PCEP_VAR_FOLDER}/default_off    session=${session}    verify=True
