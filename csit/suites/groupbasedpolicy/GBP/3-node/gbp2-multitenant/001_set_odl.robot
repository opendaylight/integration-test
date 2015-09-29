*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Default Tags      multi-tenant    setup    multi-tenant-setup
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../Variables.robot

*** Variables ***
${GBP_TENANT1_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${GBP_TENANT2_ID}     25c7d344-d1c7-4208-8531-2c2693657e12
${TENANT1_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT1_ID}
${TENANT1_FILE}       ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/tenant1.json
${TENANT2_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT2_ID}
${TENANT2_FILE}       ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/tenant2.json

${TUNNELS_PATH}      /restconf/config/opendaylight-inventory:nodes
${TUNNELS_FILE}      ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/tunnels.json

${ENDPOINTS_PATH}    /restconf/operations/endpoint:register-endpoint
${h35_2_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_2.json
${h35_3_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_3.json
${h35_4_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_4.json
${h35_5_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_5.json
${h35_6_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_6.json
${h35_7_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_7.json
${h35_8_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_8.json
${h35_9_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h35_9.json
${h36_2_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_2.json
${h36_3_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_3.json
${h36_4_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_4.json
${h36_5_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_5.json
${h36_6_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_6.json
${h36_7_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_7.json
${h36_8_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_8.json
${h36_9_FILE}        ${CURDIR}/../../../../../variables/gbp/gbp2-multitenant/vethl-h36_9.json

*** Test Cases ***
Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBP1}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER2    ${GBP2}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER3    ${GBP3}
    ${resp}    RequestsLibrary.Put Request    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS}

Register Endpoints
    [Documentation]    Endpoints registration
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_2_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_3_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_4_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_5_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_6_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_7_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_8_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h35_9_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_2_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_3_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_4_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_5_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_6_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_7_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_8_FILE}
    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${h36_9_FILE}

Put Tenants
    [Documentation]    Send GBP policy to ODL
    Add Elements To URI From File    ${TENANT1_PATH}    ${TENANT1_FILE}
    Add Elements To URI From File    ${TENANT2_PATH}    ${TENANT2_FILE}
