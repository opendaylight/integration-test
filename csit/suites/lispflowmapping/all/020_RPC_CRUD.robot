*** Settings ***
Documentation       Test suite to verify CRUD operations using RPCs

Library             Collections
Library             OperatingSystem
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py
Resource            ../../../libraries/LISPFlowMapping__Lithium.robot
Resource            ../../../libraries/Utils.robot

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Variables ***
${IPV4_C_KEY}       ${JSON_DIR}/rpc_add-key_ipv4.json
${IPV4_RD}          ${JSON_DIR}/rpc_get-remove_ipv4.json
${MISS_RD}          ${JSON_DIR}/rpc_get-remove_missing.json
${IPV4_U_KEY}       ${JSON_DIR}/rpc_update-key_ipv4.json
${IPV4_C_MAP}       ${JSON_DIR}/rpc_add-mapping_ipv4_ipv4.json
${IPV4_U_MAP}       ${JSON_DIR}/rpc_update-mapping_ipv4_ipv4.json


*** Test Cases ***
Create Key
    [Documentation]    Create a key for an IPv4 EID
    ${add_key}=    OperatingSystem.Get File    ${IPV4_C_KEY}
    Post Log Check    ${LFM_RPC_API_LI}:add-key    ${add_key}

Attempt To Create Key Again
    [Documentation]    Try to overwrite existing IPv4 EID key
    ${add_key}=    OperatingSystem.Get File    ${IPV4_C_KEY}
    Post Log Check    ${LFM_RPC_API_LI}:add-key    ${add_key}    status_codes=${409}

Attempt To Read Non-Existing Key
    [Documentation]    Try to read a non-existing key for an IPv4 EID
    ${get_key}=    OperatingSystem.Get File    ${MISS_RD}
    Post Log Check    ${LFM_RPC_API_LI}:get-key    ${get_key}    status_codes=${404}

Read Key
    [Documentation]    Read an existing key for an IPv4 EID
    ${get_key}=    OperatingSystem.Get File    ${IPV4_RD}
    ${resp}=    Post Log Check    ${LFM_RPC_API_LI}:get-key    ${get_key}
    Authentication Key Should Be    ${resp}    password

Update Key
    [Documentation]    Update an existing key for an IPv4 EID
    ${update_key}=    OperatingSystem.Get File    ${IPV4_U_KEY}
    Post Log Check    ${LFM_RPC_API_LI}:update-key    ${update_key}

Read Updated Key
    [Documentation]    Read the key updated in the previous test
    ${get_key}=    OperatingSystem.Get File    ${IPV4_RD}
    ${resp}=    Post Log Check    ${LFM_RPC_API_LI}:get-key    ${get_key}
    Authentication Key Should Be    ${resp}    updated-password

Delete Key
    [Documentation]    Delete an existing key for an IPv4 EID
    ${remove_key}=    OperatingSystem.Get File    ${IPV4_RD}
    Post Log Check    ${LFM_RPC_API_LI}:remove-key    ${remove_key}

Attempt To Read Deleted Key
    [Documentation]    Try to read the key deleted in the previous test
    ${get_key}=    OperatingSystem.Get File    ${IPV4_RD}
    Post Log Check    ${LFM_RPC_API_LI}:get-key    ${get_key}    status_codes=${404}

Attempt To Update Non-Existing Key
    [Documentation]    Update a non-existing key for an IPv4 EID
    ${update_key}=    OperatingSystem.Get File    ${IPV4_U_KEY}
    Post Log Check    ${LFM_RPC_API_LI}:update-key    ${update_key}    status_codes=${404}

Create Mapping
    [Documentation]    Create a mapping for an IPv4 EID
    ${add_mapping}=    OperatingSystem.Get File    ${IPV4_C_MAP}
    Post Log Check    ${LFM_RPC_API_LI}:add-mapping    ${add_mapping}

Attempt To Read Non-Existing Mapping
    [Documentation]    Try to read a non-existing mapping for an IPv4 EID
    ${get_mapping}=    OperatingSystem.Get File    ${MISS_RD}
    Check Mapping Removal    ${get_mapping}

Read Mapping
    [Documentation]    Read an existing mapping for an IPv4 EID
    ${get_mapping}=    OperatingSystem.Get File    ${IPV4_RD}
    ${resp}=    Post Log Check    ${LFM_RPC_API_LI}:get-mapping    ${get_mapping}
    Ipv4 Rloc Should Be    ${resp}    10.10.10.10

Update Mapping
    [Documentation]    Update an existing mapping for an IPv4 EID
    ${update_mapping}=    OperatingSystem.Get File    ${IPV4_U_MAP}
    Post Log Check    ${LFM_RPC_API_LI}:update-mapping    ${update_mapping}

Read Updated Mapping
    [Documentation]    Read the mapping updated in the previous test
    ${get_mapping}=    OperatingSystem.Get File    ${IPV4_RD}
    ${resp}=    Post Log Check    ${LFM_RPC_API_LI}:get-mapping    ${get_mapping}
    Ipv4 Rloc Should Be    ${resp}    20.20.20.20

Delete Mapping
    [Documentation]    Delete an existing mapping for an IPv4 EID
    ${remove_mapping}=    OperatingSystem.Get File    ${IPV4_RD}
    Post Log Check    ${LFM_RPC_API_LI}:remove-mapping    ${remove_mapping}

Attempt To Read Deleted Mapping
    [Documentation]    Try to read the mapping deleted in the previous test
    Sleep    200ms    Avoid race conditions
    ${get_mapping}=    OperatingSystem.Get File    ${IPV4_RD}
    Check Mapping Removal    ${get_mapping}
