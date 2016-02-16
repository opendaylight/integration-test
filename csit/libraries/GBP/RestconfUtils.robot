*** Settings ***
Documentation     Utils for Restconf operations for GBP
Library           RequestsLibrary
Library           OperatingSystem
Library           json
Variables         ../../variables/Variables.py
Resource          ../Utils.robot

*** Variables ***
${ENDPOINT_UNREG_PATH}    ${GBP_UNREGEP_API}
${ENDPOINTS_OPER_PATH}    /restconf/operational/endpoint:endpoints

*** Keywords ***
Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    ${result} =    RequestsLibrary.Get Request    session    ${ENDPOINTS_OPER_PATH}
    ${json_result} =    json.loads    ${result.text}
    Pass Execution If    ${json_result['endpoints']}=={}    No Endpoints available
    ${L2_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint']}
    ${L3_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint-l3']}
    Log    ${L2_ENDPOINTS}
    Unregister L2Endpoints    ${L2_ENDPOINTS}
    Log    ${L3_ENDPOINTS}
    Unregister L3Endpoints    ${L3_ENDPOINTS}
    ${result} =    RequestsLibrary.Get Request    session    ${ENDPOINTS_OPER_PATH}
    ${json_result} =    json.loads    ${result.text}
    Should Be Empty    ${json_result['endpoints']}

Unregister L2Endpoints
    [Arguments]    ${l2_eps}
    [Documentation]    Unregister Endpoints L2Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l2_eps}
    \    ${l2_data} =    Create L2 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${ENDPOINT_UNREG_PATH}    ${l2_data}    ${HEADERS_YANG_JSON}

Unregister L3Endpoints
    [Arguments]    ${l3_eps}
    [Documentation]    Unregister Endpoints L3Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l3_eps}
    \    ${l3_data} =    Create L3 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${ENDPOINT_UNREG_PATH}    ${l3_data}    ${HEADERS_YANG_JSON}

Create L2 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L2 Endpoints
    ${data}    Set Variable    {"input": {"l2": [{"mac-address": "${endpoint['mac-address']}", "l2-context": "${endpoint['l2-context']}"}]}}
    [Return]    ${data}

Create L3 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L3 Endpoints
    ${data}    Set Variable    {"input": {"l3": [{"l3-context": "${endpoint['l3-context']}", "ip-address": "${endpoint['ip-address']}"}]}}
    [Return]    ${data}
