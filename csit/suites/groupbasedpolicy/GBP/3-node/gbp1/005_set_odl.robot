*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Library           RequestsLibrary
Library           OperatingSystem
Resource          ../Variables.robot
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Suite Setup       Create Session    session    http://${ODL}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions



*** Variables ***
${GBP_TENANT_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}
${TENANT_FILE}       ${CURDIR}/../../../../../variables/gbp/demo-gbp1/tenants.json

${TUNNELS_PATH}      /restconf/config/opendaylight-inventory:nodes
${TUNNELS_FILE}      ${CURDIR}/../../../../../variables/gbp/demo-gbp1/tunnels.json

${ENDPOINTS_PATH}    /restconf/operations/endpoint:register-endpoint
${h35_2_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_2.json
${h35_3_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_3.json
${h35_4_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_4.json
${h35_5_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_5.json
${h36_2_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_2.json
${h36_3_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_3.json
${h36_4_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_4.json
${h36_5_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_5.json

*** Test Cases ***
Put Tenant
    [Documentation]    Send GBP policy to ODL
    Add Elements To URI From File    ${TENANT_PATH}    ${TENANT_FILE}

Register Endpoints
    [Documentation]    Endpoints registration
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_2_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_3_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_4_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_5_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_2_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_3_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_4_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_5_FILE}

Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBPSFC1}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER2    ${GBPSFC2}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER3    ${GBPSFC3}
    ${resp}    RequestsLibrary.Put    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS}

