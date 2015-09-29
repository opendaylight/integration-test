*** Settings ***
Documentation     Utils for Restconf operations for GBP
Library           RequestsLibrary
Library           OperatingSystem
Library           json
Variables         ../../variables/Variables.py
Resource          ../Utils.robot


*** Keywords ***
Unregister L2Endpoints
    [Arguments]        ${l2_eps}
    [Documentation]    Unregister Endpoints L2Endpoints from ODL
    :FOR    ${endpoint}    IN    @{l2_eps}
    \    ${l2_data} =    Create L2 Endpoint JSON Data    ${endpoint}
    \    ${l2_data_json} =    json.dumps    ${l2_data}
    \    Log    ${l2_data_json}
    \    Post Elements To URI    ${UNREG_ENDPOINTS_PATH}    ${l2_data_json}

Unregister L3Endpoints
    [Arguments]        ${l3_eps}
    [Documentation]    Unregister Endpoints L3Endpoints from ODL
    :FOR    ${endpoint}    IN    @{l3_eps}
    \    ${l3_data} =    Create L3 Endpoint JSON Data    ${endpoint}
    \    ${l3_data_json} =    json.dumps    ${l3_data}
    \    Log    ${l3_data_json}
    \    Post Elements To URI    ${UNREG_ENDPOINTS_PATH}    ${l3_data_json}

Create L2 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L2 Endpoints
    ${l2ctx} =    Create Dictionary    l2-context=${endpoint['l2-context']}    mac-address=${endpoint['mac-address']}
    Log    ${l2ctx}
    ${l2_ctx_list} =    Create List    ${l2ctx}
    Log    ${l2_ctx_list}
    ${l2} =    Create Dictionary    l2=${l2_ctx_list}
    Log    ${l2}
    ${data} =    Create Dictionary     input=${l2}
    Log    ${data}
    [Return]    ${data}

Create L3 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L3 Endpoints
    ${l3ctx} =    Create Dictionary    l3-context=${endpoint['l3-context']}    ip-address=${endpoint['ip-address']}
    Log    ${l3ctx}
    ${l3_ctx_list} =    Create List    ${l3ctx}
    Log    ${l3_ctx_list}
    ${l3} =    Create Dictionary    l3=${l3_ctx_list}
    Log    ${l3}
    ${data} =    Create Dictionary     input=${l3}
    Log    ${data}
    [Return]    ${data}

Create Rest Header
    [Documentation]    Generate custom Rest headers
    ${restHeader} =    Create Dictionary    Content-type=application/yang.data+json    Accept=application/yang.data+json
    Log    ${restHeader}
    [Return]    ${restHeader}
