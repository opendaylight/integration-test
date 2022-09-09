*** Settings ***
Documentation       This resource file defines keywords that are used in more
...                 than one lispflowmapping test suite. Those suites include
...                 ../variables/Variables.py, which is where some of the
...                 variables are coming from.


*** Variables ***
${JSON_DIR}     ${CURDIR}/../variables/lispflowmapping/Li


*** Keywords ***
Authentication Key Should Be
    [Documentation]    Check if the authentication key in the ${resp} is ${password}
    [Arguments]    ${resp}    ${password}
    ${authkey}=    Get Authentication Key    ${resp}
    Should Be Equal As Strings    ${authkey}    ${password}

Get Authentication Key
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${authkey}=    Get From Dictionary    ${output}    authkey
    RETURN    ${authkey}

Ipv4 Rloc Should Be
    [Documentation]    Check if the RLOC in the ${resp} is ${address}
    [Arguments]    ${resp}    ${address}
    ${eid_record}=    Get Eid Record    ${resp}
    ${loc_record}=    Get From Dictionary    ${eid_record}    LocatorRecord
    ${loc_record_0}=    Get From List    ${loc_record}    0
    ${ipv4}=    Get Ipv4 Rloc    ${loc_record_0}
    Should Be Equal As Strings    ${ipv4}    ${address}

Get Eid Record
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${eid_record}=    Get From Dictionary    ${output}    eidToLocatorRecord
    ${eid_record}=    Get From List    ${eid_record}    0
    RETURN    ${eid_record}

Get Ipv4 Rloc
    [Arguments]    ${loc_record}
    ${loc}=    Get From Dictionary    ${loc_record}    LispAddressContainer
    ${address}=    Get From Dictionary    ${loc}    Ipv4Address
    ${ipv4}=    Get From Dictionary    ${address}    Ipv4Address
    RETURN    ${ipv4}

Check Mapping Removal
    [Arguments]    ${json}
    ${resp}=    Post Log Check    ${LFM_RPC_API_LI}:get-mapping    ${json}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${eid_record}=    Get From Dictionary    ${output}    eidToLocatorRecord
    ${eid_record_0}=    Get From List    ${eid_record}    0
    ${action}=    Get From Dictionary    ${eid_record_0}    action
    Should Be Equal As Strings    ${action}    NativelyForward
