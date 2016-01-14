*** Settings ***
Documentation     Test suite for GBP Tenants, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Default Tags      multi-tenant    setup    multi-tenant-setup
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../Variables.robot

*** Variables ***

*** Test Cases ***
Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBP1}
    ${edited_json}    Replace String    ${edited_json}    _CLASSIFIER2    ${GBP2}
    ${edited_json}    Replace String    ${edited_json}    _CLASSIFIER3    ${GBP3}
    ${resp}    RequestsLibrary.Put Request    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS_YANG_JSON}
    Should Be Equal As Strings    ${resp.status_code}    200

Register Endpoints
    [Documentation]    Endpoints registration
    @{endpoint_files} =    OperatingSystem.List Files In Directory    ${ENDPOINTS_GBP2_DIR}    vethl*.*json    absolute
    : FOR    ${endpoint_file}    IN    @{endpoint_files}
    \    Post Elements To URI From File    ${ENDPOINT_REG_PATH}    ${endpoint_file}    ${HEADERS_YANG_JSON}

Put Tenants
    [Documentation]    Send GBP policy to ODL
    Add Elements To URI From File    ${TENANT1_PATH}    ${TENANT1_FILE}    ${HEADERS_YANG_JSON}
    Add Elements To URI From File    ${TENANT2_PATH}    ${TENANT2_FILE}    ${HEADERS_YANG_JSON}
