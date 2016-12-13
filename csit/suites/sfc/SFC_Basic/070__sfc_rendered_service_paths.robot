*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           HttpLibrary.HTTP
Resource          SFC_Basic.robot

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
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
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
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    SFC1-100-Path-1    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1
    ...    "service-index":254    "hop-number":2    "service-index":253
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Get Non Existing Rendered Service Path
    [Documentation]    Get Non Existing Rendered Service Path Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/non-existing-rsp
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    non-existing-rsp

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    SFC1-100-Path-1
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    SFC1-100-Path-1

Delete Non Existing Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    SFC1-100-Path-1
    Post Elements To URI As JSON    ${OPERATIONS_DELETE_RSP_URI}    ${DELETE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    {"rendered-service-paths":{}}

Get Rendered Service Path Hop
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP1_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
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
    [Tags]    exclude
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
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/1/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-1/rendered-service-path-hop/2/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop3}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    Should Be Equal    ${fwd_hop2}    ${fwd_hop3}
    Post Elements To URI As JSON    ${OPERATIONS_CREATE_RSP_URI}    ${CREATE_RSP2_INPUT}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/1/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/SFC1-100-Path-2/rendered-service-path-hop/2/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
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
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Init Suite
    SFC_Basic.Init    070__sfc_rendered_service_paths
