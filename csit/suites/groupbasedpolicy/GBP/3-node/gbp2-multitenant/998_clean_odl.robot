*** Settings ***
Documentation     Test suite for cleaning up / unregister infrastructure constructs like endpoints for demo-asymmetric-chain
Default Tags      multi-tenant    teardown    multi-tenant-teardown
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           json
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot


*** Variables ***

${GBP_TENANT_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}

${TUNNELS_PATH}      /restconf/config/opendaylight-inventory:nodes

${OPER_ENDPOINTS_PATH}     /restconf/operational/endpoint:endpoints
${UNREG_ENDPOINTS_PATH}    /restconf/operations/endpoint:unregister-endpoint



*** Test Cases ***

Delete Tenant
    Delete Elements at URI    ${TENANT_PATH}

Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    ${result} =    RequestsLibrary.Get    session    ${OPER_ENDPOINTS_PATH}
    ${json_result} =    json.loads    ${result.text}
    Pass Execution If    ${json_result['endpoints']}=={}    No Endpoints available
    ${L2_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint']}
    ${L3_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint-l3']}
    Log    ${L2_ENDPOINTS}
    Unregister L2Endpoints    ${L2_ENDPOINTS}
    Log    ${L3_ENDPOINTS}
    Unregister L3Endpoints    ${L3_ENDPOINTS}

Delete Nodes
    Delete Elements at URI    ${TUNNELS_PATH}


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

Delete Elements at URI
    [Arguments]        ${rest_uri}
    [Documentation]    Perform a DELETE rest operation, using the URL and data provided
    ${restHeader} =    Create Rest Header
    ${resp}    RequestsLibrary.Delete    session    ${rest_uri}    headers=${restHeader}
    Should Be Equal As Strings    ${resp.status_code}    200

Post Elements To URI
    [Arguments]    ${rest_uri}    ${data}
    [Documentation]    Perform a POST rest operation, using the URL and data provided
    ${restHeader} =    Create Rest Header
    ${resp} =    RequestsLibrary.Post Request    session    ${rest_uri}    data=${data}    headers=${restHeader}
    Should Be Equal As Strings    ${resp.status_code}    200

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
