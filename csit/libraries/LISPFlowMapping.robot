*** Keywords ***
Check Mapping Removal
    [Arguments]    ${json}
    Run Keyword If    "${ODL_VERSION}" == "Li"    Check Mapping Removal Lithium    ${json}    ELSE
    ...    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}    404

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
