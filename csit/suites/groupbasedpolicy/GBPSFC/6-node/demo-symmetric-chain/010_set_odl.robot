*** Settings ***
Documentation     Test suite for setting up infrastructure for demo-symmetric-chain
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../Variables.robot

*** Variables ***
${GBP_TENANT_ID}    f5c7d344-d1c7-4208-8531-2c2693657e12
${TENANT_PATH}    /restconf/config/policy:tenants/tenant/${GBP_TENANT_ID}
${TENANT_FILE}    ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/tenants.json
${TUNNELS_PATH}    /restconf/config/opendaylight-inventory:nodes
${TUNNELS_FILE}    ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/tunnels.json
${ENDPOINTS_PATH}    /restconf/operations/endpoint:register-endpoint
${SF_PATH}        /restconf/config/service-function:service-functions
${SF_FILE}        ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/service_functions.json
${SFF_PATH}       /restconf/config/service-function-forwarder:service-function-forwarders
${SFF_FILE}       ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/service_function_forwarders.json
${SFC_PATH}       /restconf/config/service-function-chain:service-function-chains
${SFC_FILE}       ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/service_function_chains.json
${SFP_PATH}       /restconf/config/service-function-path:service-function-paths
${SFP_FILE}       ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/service_function_paths.json
${h35_2_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h35_2.json
${h35_3_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h35_3.json
${h35_4_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h35_4.json
${h35_5_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h35_5.json
${h36_2_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h36_2.json
${h36_3_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h36_3.json
${h36_4_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h36_4.json
${h36_5_FILE}     ${CURDIR}/../../../../../variables/gbp/demo-symmetric-chain/vethl-h36_5.json
@{ENDPOINT_FILES}    ${h35_2_FILE}    ${h35_3_FILE}    ${h35_4_FILE}    ${h35_5_FILE}    ${h36_2_FILE}    ${h36_3_FILE}    ${h36_4_FILE}
...               ${h36_5_FILE}

*** Test Cases ***
Put Service Functions
    [Documentation]    Register Service Functions to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${SF_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _SF1    ${GBPSFC3}
    ${edited_json}    Replace String    ${edited_json}    _SF2    ${GBPSFC5}
    ${resp}    RequestsLibrary.Put    session    ${SF_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Put Service Function Forwarders
    [Documentation]    Register Service Function Forwarders to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${SFF_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _SFF1    ${GBPSFC2}
    ${edited_json}    Replace String    ${edited_json}    _SFF2    ${GBPSFC4}
    ${resp}    RequestsLibrary.Put    session    ${SFF_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Put Service Function Chains
    [Documentation]    Register Service Function Chains to ODL
    Add Elements To URI From File    ${SFC_PATH}    ${SFC_FILE}

Put Service Function Paths
    [Documentation]    Register Service Function Paths to ODL
    Add Elements To URI From File    ${SFP_PATH}    ${SFP_FILE}

Put Tunnels
    [Documentation]    Send tunnel augmentation to ODL
    ${json_to_edit}    OperatingSystem.Get File    ${TUNNELS_FILE}
    ${edited_json}    Replace String    ${json_to_edit}    _CLASSIFIER1    ${GBPSFC1}
    ${edited_json}    Replace String    ${edited_json}    _CLASSIFIER2    ${GBPSFC6}
    ${resp}    RequestsLibrary.Put    session    ${TUNNELS_PATH}    ${edited_json}    ${HEADERS}
    Should Be Equal As Strings    ${resp.status_code}    200

Put Tenant
    [Documentation]    Send Tenant Data to ODL
    Add Elements To URI From File    ${TENANT_PATH}    ${TENANT_FILE}

Register Endpoints
    [Documentation]    Endpoints registration
    : FOR    ${endpoint_file}    IN    @{ENDPOINT_FILES}
    \    Post Elements To URI From File    ${ENDPOINTS_PATH}    ${endpoint_file}
