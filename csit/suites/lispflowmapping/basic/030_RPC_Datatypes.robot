*** Settings ***
Documentation     Test suite to verify data types using RPCs
Suite Setup       Create Session And Set External Variables
Suite Teardown    Delete All Sessions
Test Setup        Set Suite Variable    ${CURJSON}    ${EMPTY}
Test Template     Check Datatype
Test Teardown     Remove Datatype And Check Removal
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/LISPFlowMapping.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${IPV4_C_MAP}     ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_ipv4_ipv4.json
${IPV4_RD}        ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_ipv4.json
${IPV6_C_MAP}     ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_ipv6_ipv4.json
${IPV6_RD}        ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_ipv6.json
${MAC_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_mac_ipv4.json
${MAC_RD}         ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_mac.json
${DN_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_dn_ipv4.json
${DN_RD}          ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_dn.json
${AS_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_as_ipv4.json
${AS_RD}          ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_as.json
${IID_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_iid_ipv4.json
${IID_RD}         ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_iid.json
${SD_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_srcdst_ipv4.json
${SD_RD}          ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_srcdst.json
${KV_C_MAP}       ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_kv_ipv4.json
${KV_RD}          ${CURDIR}/../../../variables/lispflowmapping/rpc_get-remove_kv.json
${LST_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_ipv4_list.json
${APP_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_ipv4_appdata.json
${ELP_C_MAP}      ${CURDIR}/../../../variables/lispflowmapping/rpc_add-mapping_ipv4_elp.json

*** Test Cases ***
IPv4 Prefix
    [Documentation]    Perform mapping operations with an IPv4 EID
    ${IPV4_C_MAP}    ${IPV4_RD}

IPv6 Prefix
    [Documentation]    Perform mapping operations with an IPv6 EID
    ${IPV6_C_MAP}    ${IPV6_RD}

MAC Address
    [Documentation]    Perform mapping operations with a MAC address EID
    ${MAC_C_MAP}    ${MAC_RD}

Distinguished Name
    [Documentation]    Perform mapping operations with a Distinguished Name EID
    ${DN_C_MAP}    ${DN_RD}

AS Number
    [Documentation]    Perform mapping operations with an Autonomous System Number EID
    ${AS_C_MAP}    ${AS_RD}

Instance ID
    [Documentation]    Perform mapping operations with an IPv4 EID in Instance ID 1
    ${IID_C_MAP}    ${IID_RD}

Source/Destination
    [Documentation]    Perform mapping operations with a Source/Destination EID
    ${SD_C_MAP}    ${SD_RD}

Key/Value
    [Documentation]    Perform mapping operations with a Key/Value EID
    ${KV_C_MAP}    ${KV_RD}

AFI List
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an AFI List RLOC
    ${LST_C_MAP}    ${IPV4_RD}

Application Data
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an Application Data RLOC
    ${APP_C_MAP}    ${IPV4_RD}

Explicit Locator Path
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an ELP RLOC
    ${ELP_C_MAP}    ${IPV4_RD}

*** Keywords ***
Check Datatype
    [Arguments]    ${add_mapping_json_file}    ${get_mapping_json_file}
    [Documentation]    Perform CRD operations using a specific datatype
    ${add_mapping}=    OperatingSystem.Get File    ${add_mapping_json_file}
    ${get_mapping}=    OperatingSystem.Get File    ${get_mapping_json_file}
    Set Suite Variable    ${CURJSON}    ${get_mapping}
    Post Log Check    ${LFM_RPC_API}:add-mapping    ${add_mapping}
    Sleep    200ms    Avoid race conditions
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${get_mapping}
    ${output}=    Get From Dictionary    ${resp.json()}    output
    ${eid_record}=    Get From Dictionary    ${output}    eidToLocatorRecord
    ${eid_record_0}=    Get From List    ${eid_record}    0
    Dictionary Should Contain Key    ${eid_record_0}    LocatorRecord

Remove Datatype And Check Removal
    Variable Should Exist    ${CURJSON}
    Post Log Check    ${LFM_RPC_API}:remove-mapping    ${CURJSON}
    Sleep    200ms    Avoid race conditions
    Check Mapping Removal    ${CURJSON}
    Set Suite Variable    ${CURJSON}    ${EMPTY}
