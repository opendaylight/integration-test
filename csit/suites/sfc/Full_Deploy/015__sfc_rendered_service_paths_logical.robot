*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs. Logical SFF
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Create All Elements
Test Teardown     Delete All Elements
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VERSION_DIR}    master
${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions-logicalsff.json
${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders-logicallsff.json
${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains-logicalsff.json
${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths-logicalsff.json
${CREATE_RSP1_INPUT}    {"input":{"name": "RSP1","parent-service-function-path": "SFP1","symmetric": "true"}}
${CREATE_RSP2_INPUT}    {"input":{"name": "RSP2","parent-service-function-path": "SFP2","symmetric": "true"}}
${CREATE_RSP_FAILURE_INPUT}    {"input":{"name": "RSP1","parent-service-function-path": "SFP3","symmetric": "true"}}
${DELETE_RSP1_INPUT}    {"input":{"name":"RSP1"}}
${DELETE_RSP1_REVERSE_INPUT}    {"input":{"name":"RSP1-Reverse"}}
${DELETE_RSP2_INPUT}    {"input":{"name":"RSP2"}}
@{SF_NAMES}       "name":"firewall-1"    "name":"dpi-1"

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment. Logical SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs. Logical SFF
    [Tags]    include
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements1}=    Create List    RSP1    "parent-service-function-path":"SFP1"    "service-chain-name":"SFC1"    "hop-number":0    "service-index":255
    ...    "hop-number":1    "service-index":254    "service-function-forwarder":"sfflogical1"    "sfc-encapsulation":"service-locator:nsh"
    ${elements2}=    Create List    RSP1-Reverse    "parent-service-function-path":"SFP1"    "service-chain-name":"SFC1"    "hop-number":0    "service-index":255
    ...    "hop-number":1    "service-index":254    "service-function-forwarder":"sfflogical1"    "sfc-encapsulation":"service-locator:nsh"
    ${elements}=    Combine Lists    ${elements1}    ${elements2}
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create Get Rendered Service Path Failure
    [Documentation]    Create Rendered Service Path Failure Cases. Logical SFF
    ${resp}    RequestsLibrary.Post Request    session    ${OPERATIONS_CREATE_RSP_URI}    data=${CREATE_RSP_FAILURE_INPUT}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    500

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    RSP1    "parent-service-function-path":"SFP1"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Get Non Existing Rendered Service Path
    [Documentation]    Get Non Existing Rendered Service Path Through RESTConf APIs. Logical SFF
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/non-existing-rsp
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    non-existing-rsp

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1-Reverse
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    RSP1-Reverse
    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_REVERSE_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1-Reverse
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    RSP1-Reverse

Delete Non Existing Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    RSP1
    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    {"rendered-service-paths":{}}

Get Rendered Service Path Hop
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    Post Elements To URI    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/0/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/1/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"firewall-1
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/1/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/2/
    Should Be Equal As Strings    ${resp.status_code}    404
    Post Elements To URI    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}

Delete All Elements
    [Documentation]    Delete all provisioned elements
    Remove All Elements If Exist    ${RENDERED_SERVICE_PATHS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
    Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Removed    ${SF_NAMES}

Create All Elements
    [Documentation]    Delete all provisioned elements
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
