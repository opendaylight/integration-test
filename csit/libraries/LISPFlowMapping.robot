*** Settings ***
Documentation     This resource file defines keywords that are used in more
...               than one lispflowmapping test suite. Those suites include
...               ../variables/Variables.py, which is where some of the
...               variables are coming from.

*** Variables ***
${ODL_VERSION}    Be

*** Keywords ***
Authentication Key Should Be
    [Arguments]    ${resp}    ${password}
    [Documentation]    Check if the authentication key in the ${resp} is ${password}
    ${authkey}=    Get Authentication Key    ${resp}
    Should Be Equal As Strings    ${authkey}    ${password}

Get Authentication Key
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${authkey}=    Run Keyword If    "${ODL_VERSION}" == "Li"    Get Authentication Key Lithium    ${output}
    ...    ELSE    Get Authentication Key Beryllium   ${output}
    [Return]    ${authkey}

Get Authentication Key Beryllium
    [Arguments]    ${output}
    ${mapping_authkey}=    Get From Dictionary    ${output}    mapping-authkey
    ${authkey}=    Get From Dictionary    ${mapping_authkey}    key-string
    [Return]    ${authkey}

Get Authentication Key Lithium
    [Arguments]    ${output}
    ${authkey}=    Get From Dictionary    ${output}    authkey
    [Return]    ${authkey}

Ipv4 Rloc Should Be
    [Arguments]    ${resp}    ${address}
    [Documentation]    Check if the RLOC in the ${resp} is ${address}
    ${eid_record}=    Get Eid Record    ${resp}
    ${loc_record}=    Get From Dictionary    ${eid_record}    LocatorRecord
    ${loc_record_0}=    Get From List    ${loc_record}    0
    ${ipv4}=    Get Ipv4 Rloc    ${loc_record_0}
    Should Be Equal As Strings    ${ipv4}    ${address}

Get Eid Record
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${eid_record}=    Run Keyword If    "${ODL_VERSION}" == "Li"    Get Eid Record Lithium    ${output}
    ...    ELSE    Get Eid Record Beryllium   ${output}
    [Return]    ${eid_record}

Get Eid Record Beryllium
    [Arguments]    ${output}
    ${eid_record}=    Get From Dictionary    ${output}    mapping-record
    [Return]    ${eid_record}

Get Eid Record Lithium
    [Arguments]    ${output}
    ${eid_record}=    Get From Dictionary    ${output}    eidToLocatorRecord
    ${eid_record}=    Get From List    ${eid_record}    0
    [Return]    ${eid_record}

Get Ipv4 Rloc
    [Arguments]    ${loc_record}
    ${ipv4}=    Run Keyword If    "${ODL_VERSION}" == "Li"    Get Ipv4 Rloc Lithium    ${loc_record}
    ...    ELSE    Get Ipv4 Rloc Beryllium   ${loc_record}
    [Return]    ${ipv4}

Get Ipv4 Rloc Beryllium
    [Arguments]    ${loc_record}
    ${loc}=    Get From Dictionary    ${loc_record}    rloc
    ${ipv4}=    Get From Dictionary    ${loc}    ipv4
    [Return]    ${ipv4}

Get Ipv4 Rloc Lithium
    [Arguments]    ${loc_record}
    ${loc}=    Get From Dictionary    ${loc_record}    LispAddressContainer
    ${address}=    Get From Dictionary    ${loc}    Ipv4Address
    ${ipv4}=    Get From Dictionary    ${address}    Ipv4Address
    [Return]    ${ipv4}

Check Mapping Removal
    [Arguments]    ${json}
    Run Keyword If    "${ODL_VERSION}" == "Li"    Check Mapping Removal Lithium    ${json}
    ...    ELSE    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}    404

Check Mapping Removal Lithium
    [Arguments]    ${json}
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${eid_record}=    Get From Dictionary    ${output}    eidToLocatorRecord
    ${eid_record_0}=    Get From List    ${eid_record}    0
    ${action}=    Get From Dictionary    ${eid_record_0}    action
    Should Be Equal As Strings    ${action}    NativelyForward

Post Log Check
    [Arguments]    ${uri}    ${body}    ${status_code}=200
    [Documentation]    Post body to uri, log response content, and check status
    ${resp}=    RequestsLibrary.Post    session    ${uri}    ${body}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    ${status_code}
    [Return]    ${resp}

Create Session And Set External Variables
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Run Keyword If    "${ODL_VERSION}" == "Li"    Set Suite Variable    ${LFM_RPC_API}    ${LFM_RPC_API_LI}
