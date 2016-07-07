*** Settings ***
Documentation     Test suite to verify CRUD operations using RPCs
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/JsonGenerator.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/LISPFlowMapping.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Create Key
    [Documentation]    Create a key for an IPv4 EID
    ${eid_json}=    Get LispAddress JSON    ipv4:192.0.2.1/32
    ${authkey_json}=    Get MappingAuthkey JSON
    ${add_key}=    Merge And Wrap input    ${eid_json}    ${authkey_json}
    Post Log Check    ${LFM_RPC_API}:add-key    ${add_key}

Attempt To Read Non-Existing Key
    [Documentation]    Try to read a non-existing key for an IPv4 EID
    ${get_key}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.255/32
    Post Log Check    ${LFM_RPC_API}:get-key    ${get_key}    404

Read Key
    [Documentation]    Read an existing key for an IPv4 EID
    ${get_key}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-key    ${get_key}
    Authentication Key Should Be    ${resp}    password

Update Key
    [Documentation]    Update an existing key for an IPv4 EID
    ${eid_json}=    Get LispAddress JSON    ipv4:192.0.2.1/32
    ${authkey_json}=    Get MappingAuthkey JSON    key_string=updated-password
    ${update_key}=    Merge And Wrap input    ${eid_json}    ${authkey_json}
    Post Log Check    ${LFM_RPC_API}:update-key    ${update_key}

Read Updated Key
    [Documentation]    Read the key updated in the previous test
    ${get_key}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-key    ${get_key}
    Authentication Key Should Be    ${resp}    updated-password

Delete Key
    [Documentation]    Delete an existing key for an IPv4 EID
    ${remove_key}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    Post Log Check    ${LFM_RPC_API}:remove-key    ${remove_key}

Attempt To Read Deleted Key
    [Documentation]    Try to read the key deleted in the previous test
    ${get_key}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    Post Log Check    ${LFM_RPC_API}:get-key    ${get_key}    404

Attempt To Update Non-Existing Key
    [Documentation]    Update a non-existing key for an IPv4 EID
    ${eid_json}=    Get LispAddress JSON    ipv4:192.0.2.1/32
    ${authkey_json}=    Get MappingAuthkey JSON    key_string=updated-password
    ${update_key}=    Merge And Wrap input    ${eid_json}    ${authkey_json}
    Post Log Check    ${LFM_RPC_API}:update-key    ${update_key}    404

Create Mapping
    [Documentation]    Create a mapping for an IPv4 EID
    ${loc_record}=    Get LocatorRecord Object    ipv4:10.10.10.10
    ${lisp_address}=    Get LispAddress Object    ipv4:192.0.2.1/32
    ${loc_record_list}=    Create List    ${loc_record}
    ${mapping_record_json}=    Get MappingRecord JSON    ${lisp_address}    ${loc_record_list}
    ${add_mapping}=    Wrap input    ${mapping_record_json}
    Post Log Check    ${LFM_RPC_API}:add-mapping    ${add_mapping}

Attempt To Read Non-Existing Mapping
    [Documentation]    Try to read a non-existing mapping for an IPv4 EID
    ${get_mapping}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.255/32
    Check Mapping Removal    ${get_mapping}

Read Mapping
    [Documentation]    Read an existing mapping for an IPv4 EID
    ${get_mapping}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${get_mapping}
    Ipv4 Rloc Should Be    ${resp}    10.10.10.10

Update Mapping
    [Documentation]    Update an existing mapping for an IPv4 EID
    ${loc_record}=    Get LocatorRecord Object    ipv4:20.20.20.20
    ${lisp_address}=    Get LispAddress Object    ipv4:192.0.2.1/32
    ${loc_record_list}=    Create List    ${loc_record}
    ${mapping_record_json}=    Get MappingRecord JSON    ${lisp_address}    ${loc_record_list}
    ${update_mapping}=    Wrap input    ${mapping_record_json}
    Post Log Check    ${LFM_RPC_API}:update-mapping    ${update_mapping}

Read Updated Mapping
    [Documentation]    Read the mapping updated in the previous test
    ${get_mapping}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${get_mapping}
    Ipv4 Rloc Should Be    ${resp}    20.20.20.20

Delete Mapping
    [Documentation]    Delete an existing mapping for an IPv4 EID
    ${remove_mapping}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    Post Log Check    ${LFM_RPC_API}:remove-mapping    ${remove_mapping}

Attempt To Read Deleted Mapping
    [Documentation]    Try to read the mapping deleted in the previous test
    Sleep    200ms    Avoid race conditions
    ${get_mapping}=    Get LispAddress JSON And Wrap input    ipv4:192.0.2.1/32
    Check Mapping Removal    ${get_mapping}
