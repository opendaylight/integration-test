*** Settings ***
Documentation     Test suite to verify data types using RPCs
Suite Setup       Create Session And Set External Variables
Suite Teardown    Delete All Sessions
Test Setup        Set Suite Variable    ${RPC_Datatype__current_json}    ${EMPTY}
Test Teardown     Remove Datatype And Check Removal
Test Template     Check Datatype
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/LISPFlowMapping.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${IPV4_C_MAP}     ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_ipv4_ipv4.json
${IPV4_C_KEY}     ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_ipv4.json
${IPV4_RD}        ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_ipv4.json
${IPV6_C_MAP}     ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_ipv6_ipv4.json
${IPV6_C_KEY}     ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_ipv6.json
${IPV6_RD}        ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_ipv6.json
${MAC_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_mac_ipv4.json
${MAC_C_KEY}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_mac.json
${MAC_RD}         ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_mac.json
${DN_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_dn_ipv4.json
${DN_C_KEY}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_dn.json
${DN_RD}          ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_dn.json
${AS_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_as_ipv4.json
${AS_C_KEY}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_as.json
${AS_RD}          ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_as.json
${IID_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_iid_ipv4.json
${IID_C_KEY}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_iid.json
${IID_RD}         ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_iid.json
${SD_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_srcdst_ipv4.json
${SD_C_KEY}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_srcdst.json
${SD_RD}          ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_srcdst.json
${KV_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_kv_ipv4.json
${KV_C_KEY}       ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-key_kv.json
${KV_RD}          ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_get-remove_kv.json
${LST_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_ipv4_list.json
${APP_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_ipv4_appdata.json
${ELP_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/${ODL_VERSION}/rpc_add-mapping_ipv4_elp.json

*** Test Cases ***
IPv4 Prefix
    [Documentation]    Perform mapping operations with an IPv4 EID
    ${IPV4_C_MAP}    ${IPV4_RD}    ${IPV4_C_KEY}

IPv6 Prefix
    [Documentation]    Perform mapping operations with an IPv6 EID
    ${IPV6_C_MAP}    ${IPV6_RD}    ${IPV6_C_KEY}

MAC Address
    [Documentation]    Perform mapping operations with a MAC address EID
    ${MAC_C_MAP}    ${MAC_RD}    ${MAC_C_KEY}

Distinguished Name
    [Documentation]    Perform mapping operations with a Distinguished Name EID
    ${DN_C_MAP}    ${DN_RD}    ${DN_C_KEY}

AS Number
    [Documentation]    Perform mapping operations with an Autonomous System Number EID
    ${AS_C_MAP}    ${AS_RD}    ${AS_C_KEY}

Instance ID
    [Documentation]    Perform mapping operations with an IPv4 EID in Instance ID 1
    ${IID_C_MAP}    ${IID_RD}    ${IID_C_KEY}

Source/Destination
    [Documentation]    Perform mapping operations with a Source/Destination EID
    ${SD_C_MAP}    ${SD_RD}    ${SD_C_KEY}

Key/Value
    [Documentation]    Perform mapping operations with a Key/Value EID
    ${KV_C_MAP}    ${KV_RD}    ${KV_C_KEY}

AFI List
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an AFI List RLOC
    ${LST_C_MAP}    ${IPV4_RD}    ${EMPTY}

Application Data
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an Application Data RLOC
    ${APP_C_MAP}    ${IPV4_RD}    ${EMPTY}

Explicit Locator Path
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an ELP RLOC
    ${ELP_C_MAP}    ${IPV4_RD}    ${EMPTY}

*** Keywords ***
Check Datatype
    [Arguments]    ${add_mapping_json_file}    ${get_mapping_json_file}    ${add_key_json_file}
    [Documentation]    Perform CRD operations using a specific datatype
    ${add_mapping}=    OperatingSystem.Get File    ${add_mapping_json_file}
    ${get_mapping}=    OperatingSystem.Get File    ${get_mapping_json_file}
    Check Mapping Datatype    ${add_mapping}    ${get_mapping}
    Run Keyword If    "${ODL_VERSION}" == "Be" and "${add_key_json_file}" != ""   Check Key Datatype    ${add_key_json_file}    ${get_mapping}

Remove Datatype And Check Removal
    Remove Mapping Datatype And Check Removal
    Run Keyword If    "${ODL_VERSION}" == "Be"    Remove Key Datatype And Check Removal

Check Mapping Datatype
    [Arguments]    ${add_mapping}    ${get_mapping}
    [Documentation]    Perform CRD operations on mappings using a specific datatype
    Set Suite Variable    ${RPC_Datatype__current_json}    ${get_mapping}
    Post Log Check    ${LFM_RPC_API}:add-mapping    ${add_mapping}
    Sleep    200ms    Avoid race conditions
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${get_mapping}
    ${eid_record}=    Get Eid Record    ${resp}
    Dictionary Should Contain Key    ${eid_record}    LocatorRecord

Check Key Datatype
    [Arguments]    ${add_key_json_file}    ${get_key}
    [Documentation]    Perform CRD operations on keys using a specific datatype
    ${add_key}=    OperatingSystem.Get File    ${add_key_json_file}
    Post Log Check    ${LFM_RPC_API}:add-key    ${add_key}
    Sleep    200ms    Avoid race conditions
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-key    ${get_key}
    Authentication Key Should Be    ${resp}    password

Remove Mapping Datatype And Check Removal
    Variable Should Exist    ${RPC_Datatype__current_json}
    Post Log Check    ${LFM_RPC_API}:remove-mapping    ${RPC_Datatype__current_json}
    Sleep    200ms    Avoid race conditions
    Check Mapping Removal    ${RPC_Datatype__current_json}

Remove Key Datatype And Check Removal
    Variable Should Exist    ${RPC_Datatype__current_json}
    Post Log Check    ${LFM_RPC_API}:remove-key    ${RPC_Datatype__current_json}
    Sleep    200ms    Avoid race conditions
    Post Log Check    ${LFM_RPC_API}:get-key    ${RPC_Datatype__current_json}    404
    Set Suite Variable    ${RPC_Datatype__current_json}    ${EMPTY}
