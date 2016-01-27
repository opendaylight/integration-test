*** Settings ***
Documentation     This resource file defines keywords that are used in more
...               than one lispflowmapping test suite. Those suites include
...               ../variables/Variables.py, which is where some of the
...               variables are coming from.

*** Variables ***
${JSON_DIR}       ${CURDIR}/../variables/lispflowmapping/Be

*** Keywords ***
Authentication Key Should Be
    [Arguments]    ${resp}    ${password}
    [Documentation]    Check if the authentication key in the ${resp} is ${password}
    ${authkey}=    Get Authentication Key    ${resp}
    Should Be Equal As Strings    ${authkey}    ${password}

Get Authentication Key
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${mapping_authkey}=    Get From Dictionary    ${output}    mapping-authkey
    ${authkey}=    Get From Dictionary    ${mapping_authkey}    key-string
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
    ${eid_record}=    Get From Dictionary    ${output}    mapping-record
    [Return]    ${eid_record}

Get Ipv4 Rloc
    [Arguments]    ${loc_record}
    ${loc}=    Get From Dictionary    ${loc_record}    rloc
    ${ipv4}=    Get From Dictionary    ${loc}    ipv4
    [Return]    ${ipv4}

Get Elp Hop
    [Arguments]    ${loc_record}    ${hop_index}
    [Documentation]    Returns the Rloc object pointed to by ${hop_index}
    ${rloc}=    Get From Dictionary    ${loc_record}    rloc
    ${exp_loc_path}=    Get From Dictionary    ${rloc}    explicit-locator-path
    ${actual_hop_index}=    Evaluate    ${hop_index} - 1
    ${hop}=    Get From List    ${exp_loc_path}    ${actual_hop_index}
    [Return]    ${hop}

Check Mapping Removal
    [Arguments]    ${json}
    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}    404
