*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Run Keywords    Init Suite    ClusterManagement Setup
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/BackupRestoreKeywords.robot

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Create and Get Rendered Service Path
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.GET On Session    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254    "hop-number":2    "service-index":253
    ConditionalBackupRestoreCheck
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}

Create Get Rendered Service Path Failure
    [Documentation]    Create and Get Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.GET On Session    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254    "hop-number":2    "service-index":253
    ConditionalBackupRestoreCheck
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}

Clean Datastore After Tests
    [Documentation]    Clean All Items In Datastore After Tests
    Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Remove All Elements If Exist    ${SERVICE_NODES_URI}
    Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.GET On Session    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_URI}    /restconf/config/service-function-forwarder:service-function-forwarders/
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_URI}    /restconf/config/service-node:service-nodes/
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_URI}    /restconf/config/service-function-chain:service-function-chains/
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_SCHED_TYPES_URI}    /restconf/config/service-function-scheduler-type:service-function-scheduler-types/
    Set Suite Variable    ${SERVICE_SCHED_TYPE_URI_BASE}    ${SERVICE_SCHED_TYPES_URI}service-function-scheduler-type/service-function-scheduler-type:
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}random
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-random-schedule-type.json
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}round-robin
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-roundrobin-schedule-type.json
    Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}load-balance
    Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-loadbalance-schedule-type.json
    Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}    ${SERVICE_SCHED_TYPE_URI_BASE}shortest-path
    Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-shortestpath-schedule-type.json
    Set Suite Variable    ${RENDERED_SERVICE_PATHS_URI}    /restconf/config/rendered-service-path:rendered-service-paths/
    Set Suite Variable    ${OPERATIONAL_RSPS_URI}    /restconf/operational/rendered-service-path:rendered-service-paths/
    Set Suite Variable    ${OPERATIONS_CREATE_RSP_URI}    /restconf/operations/rendered-service-path:create-rendered-path/
    Set Suite Variable    ${OPERATIONS_DELETE_RSP_URI}    /restconf/operations/rendered-service-path:delete-rendered-path
    Set Suite Variable    ${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-1"}}
    Set Suite Variable    ${CREATE_RSP2_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-2"}}
    Set Suite Variable    ${CREATE_RSP3_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-3"}}
    Set Suite Variable    ${CREATE_RSP4_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-4"}}
    Set Suite Variable    ${CREATE_RSP5_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-5"}}
    Set Suite Variable    ${CREATE_RSP6_INPUT}    {"input":{"parent-service-function-path":"SFC1-100","name":"SFC1-100-Path-6"}}
    Set Suite Variable    ${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"SFC1-empty-Path-1"}}
    Set Suite Variable    ${DELETE_RSP1_INPUT}    {"input":{"name":"SFC1-100-Path-1"}}
    Set Suite Variable    ${DELETE_RSP2_INPUT}    {"input":{"name":"SFC1-100-Path-2"}}
    Set Suite Variable    ${DELETE_RSP3_INPUT}    {"input":{"name":"SFC1-100-Path-3"}}
    Set Suite Variable    ${DELETE_RSP4_INPUT}    {"input":{"name":"SFC1-100-Path-4"}}
    Set Suite Variable    ${DELETE_RSP5_INPUT}    {"input":{"name":"SFC1-100-Path-5"}}
    Set Suite Variable    ${DELETE_RSP6_INPUT}    {"input":{"name":"SFC1-100-Path-6"}}
