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
Library           ../../../libraries/JsonGenerator.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/LISPFlowMapping.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
IPv4 Prefix
    [Documentation]    Perform mapping operations with an IPv4 EID
    ipv4:192.0.2.1/32    ipv4:10.10.10.10    ipv4:192.0.2.1/32

IPv6 Prefix
    [Documentation]    Perform mapping operations with an IPv6 EID
    ipv6:2001:db8::1/128    ipv4:10.10.10.10    ipv6:2001:db8::1/128

MAC Address
    [Documentation]    Perform mapping operations with a MAC address EID
    mac:00:11:22:33:44:55    ipv4:10.10.10.10    mac:00:11:22:33:44:55

Distinguished Name
    [Documentation]    Perform mapping operations with a Distinguished Name EID
    dn:stringAsIs    ipv4:10.10.10.10    dn:stringAsIs

AS Number
    [Documentation]    Perform mapping operations with an Autonomous System Number EID
    as:64500    ipv4:10.10.10.10    as:64500

Source/Destination
    [Documentation]    Perform mapping operations with a Source/Destination EID
    srcdst:192.0.2.1/32|192.0.2.2/32    ipv4:10.10.10.10    srcdst:192.0.2.1/32|192.0.2.2/32

Key/Value
    [Documentation]    Perform mapping operations with a Key/Value EID
    kv:192.0.2.1->192.0.2.2    ipv4:10.10.10.10    kv:192.0.2.1->192.0.2.2

Service Path
    [Documentation]    Perform mapping operations with a Service Path EID
    sp:42(3)    ipv4:10.10.10.10    sp:42(3)

AFI List
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an AFI List RLOC
    ipv4:192.0.2.1/32    list:{10.10.10.10,2001:db8::1}    ipv4:192.0.2.1/32

Application Data
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an Application Data RLOC
    ipv4:192.0.2.1/32    appdata:10.10.10.10!128!17!80-81!6667-7000    ipv4:192.0.2.1/32

Explicit Locator Path
    [Documentation]    Perform mapping operations with an IPv4 EID mapped to an ELP RLOC
    ipv4:192.0.2.1/32    elp:{20.20.20.20|lps->30.30.30.30|ls}    ipv4:192.0.2.1/32

*** Keywords ***
Check Datatype
    [Arguments]    ${add_mapping_eid}    ${add_mapping_rloc}    ${get_mapping_eid}
    [Documentation]    Perform CRD operations using a specific datatype
    ${add_mapping}=    Get Mapping JSON    ${add_mapping_eid}    ${add_mapping_rloc}
    ${get_mapping}=    Get LispAddress JSON And Wrap input    ${get_mapping_eid}
    Set Suite Variable    ${RPC_Datatype__current_json}    ${get_mapping}
    Post Log Check    ${LFM_RPC_API}:add-mapping    ${add_mapping}    204
    Wait Until Keyword Succeeds    5s    200ms    Post Log Check LocatorRecord    ${get_mapping}

Remove Datatype And Check Removal
    Variable Should Exist    ${RPC_Datatype__current_json}
    Post Log Check    ${LFM_RPC_API}:remove-mapping    ${RPC_Datatype__current_json}    204
    Wait Until Keyword Succeeds    5s    200ms    Check Mapping Removal    ${RPC_Datatype__current_json}
    Set Suite Variable    ${RPC_Datatype__current_json}    ${EMPTY}
