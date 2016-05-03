*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot



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
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254    "hop-number":2    "service-index":253
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Create Get Rendered Service Path Failure
    [Documentation]    Create Rendered Service Path Failure Cases
    ${resp}    RequestsLibrary.Post Request    session    ${OPERATIONS_CREATE_RSP_URI}    data=${CREATE_RSP_FAILURE_INPUT}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    500

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254    "hop-number":2    "service-index":253
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Get Non Existing Rendered Service Path
    [Documentation]    Get Non Existing Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/non-existing-rsp
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    non-existing-rsp

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFC1-100-Path-1
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    SFC1-100-Path-1

Delete Non Existing Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    SFC1-100-Path-1
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    {"rendered-service-paths":{}}

Get Rendered Service Path Hop
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/3/
    Should Be Equal As Strings    ${resp.status_code}    404
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}

Generate RSPs with Random Schedule Algorithm type
    [Documentation]    Generate RSPs with Random Schedule Algorithm type Through RESTConf APIs
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_RANDOM_SCHED_TYPE_FILE}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/    ${elements}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/2/    ${elements}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
Generate RSPs with Round Robin Schedule Algorithm type
    [Documentation]    Generate RSPs with Round Robin Schedule Algorithm type
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP3_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP4_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP5_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP6_INPUT}
    ${path1_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/
    ${path1_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/
    ${path1_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/
    ${path2_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/0/
    ${path2_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/1/
    ${path2_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/2/
    ${path3_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-3/rendered-service-path-hop/0/
    ${path3_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-3/rendered-service-path-hop/1/
    ${path3_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-3/rendered-service-path-hop/2/
    ${path4_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-4/rendered-service-path-hop/0/
    ${path4_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-4/rendered-service-path-hop/1/
    ${path4_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-4/rendered-service-path-hop/2/
    ${path5_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-5/rendered-service-path-hop/0/
    ${path5_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-5/rendered-service-path-hop/1/
    ${path5_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-5/rendered-service-path-hop/2/
    ${path6_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-6/rendered-service-path-hop/0/
    ${path6_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-6/rendered-service-path-hop/1/
    ${path6_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-6/rendered-service-path-hop/2/
    Should Be Equal    ${path1_hop0}    ${path4_hop0}
    Should Not Be Equal    ${path1_hop0}    ${path2_hop0}
    Should Be Equal    ${path1_hop1}    ${path4_hop1}
    Should Not Be Equal    ${path1_hop1}    ${path2_hop1}
    Should Be Equal    ${path1_hop2}    ${path4_hop2}
    Should Not Be Equal    ${path1_hop2}    ${path2_hop2}
    Should Be Equal    ${path2_hop0}    ${path5_hop0}
    Should Not Be Equal    ${path2_hop0}    ${path3_hop0}
    Should Be Equal    ${path2_hop1}    ${path5_hop1}
    Should Not Be Equal    ${path2_hop1}    ${path3_hop1}
    Should Be Equal    ${path2_hop2}    ${path5_hop2}
    Should Not Be Equal    ${path2_hop2}    ${path3_hop2}
    Should Be Equal    ${path3_hop0}    ${path6_hop0}
    Should Not Be Equal    ${path3_hop0}    ${path1_hop0}
    Should Be Equal    ${path3_hop1}    ${path6_hop1}
    Should Not Be Equal    ${path3_hop1}    ${path1_hop1}
    Should Be Equal    ${path3_hop2}    ${path6_hop2}
    Should Not Be Equal    ${path3_hop2}    ${path1_hop2}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP3_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP4_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP5_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP6_INPUT}
Generate RSPs with Shortest Path Schedule Algorithm type
    [Documentation]    Generate RSPs with Shortest Path Schedule Algorithm type Through RESTConf APIs
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop3}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    Should Be Equal    ${fwd_hop2}    ${fwd_hop3}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/0/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/1/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/2/
    Should Be Equal As Strings    ${resp.status_code}    200
    ${fwd_hop3}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    Should Be Equal    ${fwd_hop2}    ${fwd_hop3}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
Clean Datastore After Tests
    [Documentation]    Clean All Items In Datastore After Tests
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Be Equal As Strings    ${resp.status_code}    200

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master

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

