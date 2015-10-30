*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Default Tags      single-tenant    setup    single-tenant-setup
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../Variables.robot

*** Variables ***
${GBP_TENANT_ID}     f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}       /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}
${TENANT_FILE}       ${CURDIR}/../../../../../variables/gbp/demo-gbp1/tenants.json

${TUNNELS_PATH}      /restconf/config/opendaylight-inventory:nodes
${TUNNELS_FILE}      ${CURDIR}/../../../../../variables/gbp/demo-gbp1/tunnels.json

${ENDPOINTS_PATH}    /restconf/operations/endpoint:register-endpoint
@{ENDPOINTS_FILES}=
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_2.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_3.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_4.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h35_5.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_2.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_3.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_4.json
    ...    ${CURDIR}/../../../../../variables/gbp/demo-gbp1/vethl-h36_5.json

*** Test Cases ***
Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}     Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBP1}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER2    ${GBP2}
    ${edited_json}     Replace String    ${edited_json}     _CLASSIFIER3    ${GBP3}
    ${resp}    RequestsLibrary.Put Request    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Register Endpoints
    [Documentation]    Endpoints registration
    :FOR    ${file}    IN    @{ENDPOINTS_FILES}
    \    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${file}

Put Tenant
    [Documentation]    Send GBP policy to ODL
    Add Elements To URI From File    ${TENANT_PATH}    ${TENANT_FILE}
