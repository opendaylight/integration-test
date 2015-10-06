*** Settings ***
Documentation     Robot keyword library (Resource) for performing PCEP operations via restconf calls.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           RequestsLibrary
Library           ${CURDIR}/../../../libraries/HsfJson/hsf_json.py
Variables         ${CURDIR}/../variables/Variables.py

*** Keywords ***
Setup_Pcep_Operations
    [Documentation]    Creates Requests session to be used by subsequent keywords.
    # Do not append slash at the end uf URL, Requests would add another, resulting in error.
    Create_Session    pcep_session    http://${CONTROLLER}:${RESTCONFPORT}/restconf/operations    headers=${HEADERS_XML}    auth=${AUTH}

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
    ${response}=    RequestsLibrary.Post    pcep_session    ${uri_part}    data=${xml_data}
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
    ${expected_normalized}=    hsf_json.hsf_json    ${expected_raw}
    ${actual_normalized}=    hsf_json.hsf_json    ${actual_raw}
    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}
    # TODO: Would the diff approach be more useful?
