*** Settings ***
Documentation     Test suite for cleaning up / unregister infrastructure constructs like endpoints for demo-symmetric-chain
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           Collections
Library           json
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot


*** Variables ***

${GBP_TENENT_ID}           f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}             /restconf/config/policy:tenants/tenant/${GBP_TENENT_ID}
${TUNNELS_PATH}            /restconf/config/opendaylight-inventory:nodes

${OPER_ENDPOINTS_PATH}     /restconf/operational/endpoint:endpoints
${UNREG_ENDPOINTS_PATH}    /restconf/operations/endpoint:unregister-endpoint

${SF_PATH}                 /restconf/config/service-function:service-functions
${SFF_PATH}                /restconf/config/service-function-forwarder:service-function-forwarders
${SFC_PATH}                /restconf/config/service-function-chain:service-function-chains
${SFP_PATH}                /restconf/config/service-function-path:service-function-paths

${OPER_NODES}              /restconf/operational/opendaylight-inventory:nodes/


*** Test Cases ***

Delete Service Function Paths
    [Documentation]    Delete Service Function Paths from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${SFP_PATH}

Delete Service Function Chains
    [Documentation]    Delete Service Function Chains from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${SFC_PATH}

Delete Service Functions
    [Documentation]    Delete Service Function from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${SF_PATH}

Delete Service Function Forwarders
    [Documentation]    Delete Service Function Forwarders from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${SFF_PATH}

Delete Tunnels
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${TUNNELS_PATH}

Delete Tenant
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI    ${TENANT_PATH}

Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    [Tags]    GBPSFCTEAR
    ${result} =    RequestsLibrary.Get    session    ${OPER_ENDPOINTS_PATH}
    ${json_result} =    json.loads    ${result.text}
    Pass Execution If    ${json_result['endpoints']}=={}    No Endpoints available
    ${L2_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint']}
    ${L3_ENDPOINTS} =    Set Variable    ${json_result['endpoints']['endpoint-l3']}
    Log    ${L2_ENDPOINTS}
    Unregister L2Endpoints    ${L2_ENDPOINTS}
    Log    ${L3_ENDPOINTS}
    Unregister L3Endpoints    ${L3_ENDPOINTS}

*** Keywords ***
Unregister L2Endpoints
    [Arguments]        ${l2_eps}
    [Documentation]    Unregister Endpoints L2Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l2_eps}
    \    ${l2_data} =    Create L2 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${UNREG_ENDPOINTS_PATH}    ${l2_data}

Unregister L3Endpoints
    [Arguments]        ${l3_eps}
    [Documentation]    Unregister Endpoints L3Endpoints from ODL
    : FOR    ${endpoint}    IN    @{l3_eps}
    \    ${l3_data} =    Create L3 Endpoint JSON Data    ${endpoint}
    \    Post Elements To URI    ${UNREG_ENDPOINTS_PATH}    ${l3_data}

Create L2 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L2 Endpoints
    ${data}    Set Variable
    ...    {"input": {"l2": [{"mac-address": "${endpoint['mac-address']}", "l2-context": "${endpoint['l2-context']}"}]}}
    [Return]    ${data}

Create L3 Endpoint JSON Data
    [Arguments]    ${endpoint}
    [Documentation]    Generate the JSON data required for unregistering L3 Endpoints
    ${data}    Set Variable
    ...    {"input": {"l3": [{"l3-context": "${endpoint['l3-context']}", "ip-address": "${endpoint['ip-address']}"}]}}
    [Return]    ${data}

