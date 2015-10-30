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
Resource          ../../../../../libraries/GBP/RestconfUtils.robot


*** Variables ***

${GBP_TENANT_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}

${TUNNELS_PATH}      /restconf/config/opendaylight-inventory:nodes

${OPER_ENDPOINTS_PATH}     /restconf/operational/endpoint:endpoints
${UNREG_ENDPOINTS_PATH}    /restconf/operations/endpoint:unregister-endpoint



*** Test Cases ***

Delete Tenant
    Remove All Elements At URI    ${TENANT_PATH}

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
    Remove All Elements At URI    ${TUNNELS_PATH}
