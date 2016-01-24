*** Settings ***
Documentation     Test suite to verify data types using RPCs
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
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

*** Test Cases ***
IPv4 Prefix
    [Documentation]    Perform mapping operations with an IPv4 EID
    rpc_add-mapping_ipv4_ipv4.json    rpc_get-remove_ipv4.json

IPv6 Prefix
    [Documentation]    Perform mapping operations with an IPv6 EID
    rpc_add-mapping_ipv6_ipv4.json    rpc_get-remove_ipv6.json

MAC Address
    [Documentation]    Perform mapping operations with a MAC address EID
    rpc_add-mapping_mac_ipv4.json    rpc_get-remove_mac.json

Distinguished Name
    [Documentation]    Perform mapping operations with a Distinguished Name EID
    rpc_add-mapping_dn_ipv4.json    rpc_get-remove_dn.json

AS Number
    [Documentation]    Perform mapping operations with an Autonomous System Number EID
    rpc_add-mapping_as_ipv4.json    rpc_get-remove_as.json

Instance ID
    [Documentation]    Perform mapping operations with an IPv4 EID in Instance ID 1
    rpc_add-mapping_iid_ipv4.json    rpc_get-remove_iid.json

Source/Destination
    [Documentation]    Perform mapping operations with a Source/Destination EID
    rpc_add-mapping_srcdst_ipv4.json    rpc_get-remove_srcdst.json

Key/Value
    [Documentation]    Perform mapping operations with a Key/Value EID
    rpc_add-mapping_kv_ipv4.json    rpc_get-remove_kv.json

Service Path
    [Documentation]    Perform mapping operations with a Service Path EID
    rpc_add-mapping_sp_ipv4.json    rpc_get-remove_sp.json

AFI List
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an AFI List RLOC
    rpc_add-mapping_ipv4_list.json    rpc_get-remove_ipv4.json

Application Data
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an Application Data RLOC
    rpc_add-mapping_ipv4_appdata.json    rpc_get-remove_ipv4.json

Explicit Locator Path
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an ELP RLOC
    rpc_add-mapping_ipv4_elp.json    rpc_get-remove_ipv4.json

*** Keywords ***
Check Datatype
    [Arguments]    ${add_mapping_json_file}    ${get_mapping_json_file}
    [Documentation]    Perform CRD operations using a specific datatype
    ${add_mapping}=    OperatingSystem.Get File    ${JSON_DIR}/${add_mapping_json_file}
    ${get_mapping}=    OperatingSystem.Get File    ${JSON_DIR}/${get_mapping_json_file}
    Set Suite Variable    ${RPC_Datatype__current_json}    ${get_mapping}
    Post Log Check    ${LFM_RPC_API}:add-mapping    ${add_mapping}
    Sleep    200ms    Avoid race conditions
    ${resp}=    Post Log Check    ${LFM_RPC_API}:get-mapping    ${get_mapping}
    ${eid_record}=    Get Eid Record    ${resp}
    Dictionary Should Contain Key    ${eid_record}    LocatorRecord

Remove Datatype And Check Removal
    Variable Should Exist    ${RPC_Datatype__current_json}
    Post Log Check    ${LFM_RPC_API}:remove-mapping    ${RPC_Datatype__current_json}
    Sleep    200ms    Avoid race conditions
    Check Mapping Removal    ${RPC_Datatype__current_json}
    Set Suite Variable    ${RPC_Datatype__current_json}    ${EMPTY}
