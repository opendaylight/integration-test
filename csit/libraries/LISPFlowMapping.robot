*** Settings ***
Documentation       This resource file defines keywords that are used in more
...                 than one lispflowmapping test suite. Those suites include
...                 ../variables/Variables.py, which is where some of the
...                 variables are coming from.

Library             JsonGenerator.py


*** Variables ***
${JSON_DIR}     ${CURDIR}/../variables/lispflowmapping/Be


*** Keywords ***
Authentication Key Should Be
    [Documentation]    Check if the authentication key in the ${resp} is ${password}
    [Arguments]    ${resp}    ${password}
    ${authkey}=    Get Authentication Key    ${resp}
    Should Be Equal As Strings    ${authkey}    ${password}

Get Authentication Key
    [Arguments]    ${resp}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${mapping_authkey}=    Get From Dictionary    ${output}    mapping-authkey
    ${authkey}=    Get From Dictionary    ${mapping_authkey}    key-string
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
    ${eid_record}=    Get From Dictionary    ${output}    mapping-record
    RETURN    ${eid_record}

Get Ipv4 Rloc
    [Arguments]    ${loc_record}
    ${loc}=    Get From Dictionary    ${loc_record}    rloc
    ${ipv4}=    Get From Dictionary    ${loc}    ipv4
    RETURN    ${ipv4}

Get Elp Hop
    [Documentation]    Returns the Rloc object pointed to by ${hop_index}
    [Arguments]    ${loc_record}    ${hop_index}
    ${rloc}=    Get From Dictionary    ${loc_record}    rloc
    ${exp_loc_path}=    Get From Dictionary    ${rloc}    explicit-locator-path
    ${actual_hop_index}=    Evaluate    ${hop_index} - 1
    ${hop}=    Get From List    ${exp_loc_path}    ${actual_hop_index}
    RETURN    ${hop}

Check Key Removal
    [Arguments]    ${json}
    Post Log Check    ${LFM_RPC_API}:get-key    ${json}    status_codes=${DELETED_STATUS_CODES}

Check Mapping Removal
    [Arguments]    ${json}
    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}    status_codes=${DELETED_STATUS_CODES}

Get Mapping JSON
    [Documentation]    Returns mapping record JSON dict
    [Arguments]    ${eid}    ${rloc}
    ${loc_record}=    Get LocatorRecord Object    ${rloc}
    ${lisp_address}=    Get LispAddress Object    ${eid}
    ${loc_record_list}=    Create List    ${loc_record}
    ${mapping_record_json}=    Get MappingRecord JSON    ${lisp_address}    ${loc_record_list}
    ${mapping}=    Wrap input    ${mapping_record_json}
    RETURN    ${mapping}

Post Log Check Authkey
    [Documentation]    Extend the 'Post Log Check' keyword to check for the correct authentication key
    [Arguments]    ${json}    ${password}
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-key    ${json}
    Authentication Key Should Be    ${resp}    ${password}

Post Log Check Ipv4 Rloc
    [Documentation]    Extend the 'Post Log Check' keyword to check for the correct IPv4 RLOC
    [Arguments]    ${json}    ${rloc}
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}
    Ipv4 Rloc Should Be    ${resp}    ${rloc}

Post Log Check LocatorRecord
    [Documentation]    Extend the 'Post Log Check' keyword to check for the existence of a LocatorRecord
    [Arguments]    ${json}
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${json}
    ${eid_record}=    Get Eid Record    ${resp}
    Dictionary Should Contain Key    ${eid_record}    LocatorRecord
