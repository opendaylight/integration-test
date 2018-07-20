*** Settings ***
Documentation     Test suite for SFC Rendered Service Paths, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SERVICE_FUNCTION_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    # Creates SFPs: SFC1-100, SFC1-200, SFC1-300, SFC2-100, and SFC2-200
    ${created_sfps} =    Create List    "SFC1-100"    "SFC1-200"    "SFC1-300"    "SFC2-100"    "SFC1-200"
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${created_sfps}

Get Rendered Service Path By Name
    [Documentation]    Get The Rendered Service Path Created in "Basic Environment Setup Tests" By Name Via RESTConf APIs
    ${sfp_name} =    Set Variable    SFC1-100
    ${rsp_name}    Get Rendered Service Path Name    ${sfp_name}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp_name}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # The RSP should not be symetric, so only 1 should be created for the SFP
    Check For Specific Number Of Elements At URI    ${SERVICE_FUNCTION_PATH_STATE_URI}${sfp_name}    "sfp-rendered-service-path"    1
    ${elements}=    Create List    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1    "service-index":254
    ...    "hop-number":2    "service-index":253
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Get Rendered Service Path Hop
    [Documentation]    Check Rendered Service Path Hops Created in "Basic Environment Setup Tests"
    ${sfp_name} =    Set Variable    SFC1-100
    ${rsp_name}    Get Rendered Service Path Name    ${sfp_name}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/2/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/3/
    Should Be Equal As Strings    ${resp.status_code}    404

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By deleting the parent Service Function Path
    ...    The RSP to be deleted was created in "Basic Environment Setup Tests"
    ${sfp_name} =    Set Variable    SFC2-200
    ${rsp_name}    Get Rendered Service Path Name    ${sfp_name}
    # First verify that the RSP exists
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp_name}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # Delete the SFP, which will delete the RSP
    Delete Sfp And Wait For Rsps Deletion    ${sfp_name}

Generate RSPs with Random Schedule Algorithm type
    [Documentation]    Generate RSPs with Random Schedule Algorithm type Through RESTConf APIs
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_RANDOM_SCHED_TYPE_FILE}
    # Delete all existing SFPs, which will delete the RSPs
    ${sfp_name} =    Set Variable    SFC1-100
    Delete Sfp And Wait For Rsps Deletion    ${sfp_name}
    # Create the SFPs which will create the RSPs with the Random scheduler
    ${created_sfps} =    Create List    "SFC1-100"    "SFC1-200"    "SFC1-300"    "SFC2-100"    "SFC1-200"
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${created_sfps}
    ${rsp_name}    Get Rendered Service Path Name    SFC1-100
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp_name}/rendered-service-path-hop/2/    ${elements}

Generate RSPs with Round Robin Schedule Algorithm type
    [Documentation]    Generate RSPs with Round Robin Schedule Algorithm type
    [Tags]    exclude
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}
    # Delete all existing SFPs, which will delete the RSPs
    ${sfp_name} =    Set Variable    SFC1-100
    Delete Sfp And Wait For Rsps Deletion    ${sfp_name}
    # Create the SFPs which will create the RSPs with the Random scheduler
    ${created_sfps} =    Create List    "SFC1-100"    "SFC1-200"    "SFC1-300"    "SFC2-100"    "SFC1-200"
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${created_sfps}
    ${rsp1_name}    Get Rendered Service Path Name    SFC1-100
    ${rsp2_name}    Get Rendered Service Path Name    SFC1-200
    ${rsp3_name}    Get Rendered Service Path Name    SFC1-300
    ${rsp4_name}    Get Rendered Service Path Name    SFC2-100
    ${rsp5_name}    Get Rendered Service Path Name    SFC2-200
    ${path1_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    ${path1_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    ${path1_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
    ${path2_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    ${path2_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    ${path2_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
    ${path3_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    ${path3_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    ${path3_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
    ${path4_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    ${path4_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    ${path4_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
    ${path5_hop0}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    ${path5_hop1}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    ${path5_hop2}    Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
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
    Should Be Equal    ${path3_hop0}    ${path1_hop0}
    Should Not Be Equal    ${path3_hop0}    ${path1_hop0}
    Should Be Equal    ${path3_hop1}    ${path1_hop1}
    Should Not Be Equal    ${path3_hop1}    ${path1_hop1}
    Should Be Equal    ${path3_hop2}    ${path1_hop2}
    Should Not Be Equal    ${path3_hop2}    ${path1_hop2}

Generate RSPs with Shortest Path Schedule Algorithm type
    [Documentation]    Generate RSPs with Shortest Path Schedule Algorithm type Through RESTConf APIs
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Add Elements To URI From File    ${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}
    # Delete all existing SFPs, which will delete the RSPs
    ${sfp_name} =    Set Variable    SFC1-100
    Delete Sfp And Wait For Rsps Deletion    ${sfp_name}
    # Create the SFPs which will create the RSPs with the Random scheduler
    ${created_sfps} =    Create List    "SFC1-100"    "SFC1-200"    "SFC1-300"    "SFC2-100"    "SFC1-200"
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${created_sfps}
    ${rsp1_name}    Get Rendered Service Path Name    SFC1-100
    ${rsp2_name}    Get Rendered Service Path Name    SFC1-200
    ${rsp3_name}    Get Rendered Service Path Name    SFC1-300
    ${rsp4_name}    Get Rendered Service Path Name    SFC2-100
    ${rsp5_name}    Get Rendered Service Path Name    SFC2-200
    ${elements}=    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/    ${elements}
    ${elements}=    Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/    ${elements}
    ${elements}=    Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Check For Elements At URI    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/    ${elements}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/1/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp1_name}/rendered-service-path-hop/2/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop3}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    Should Be Equal    ${fwd_hop2}    ${fwd_hop3}
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp2_name}/rendered-service-path-hop/0/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop1}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp2_name}/rendered-service-path-hop/1/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    ${resp}    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}${rsp2_name}/rendered-service-path-hop/2/
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop3}    Extract Value From Content    ${resp.content}    /rendered-service-path-hop/0/service-function-forwarder
    Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    Should Be Equal    ${fwd_hop2}    ${fwd_hop3}

Clean Datastore After Tests
    [Documentation]    Clean All Items In Datastore After Tests
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Removed    ${SERVICE_FUNCTION_NAMES}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Empty Service Function Paths State

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
    Set Suite Variable    @{SERVICE_FUNCTION_NAMES}    "napt44-103-2"    "napt44-103-1"    "dpi-102-2"    "firewall-101-2"    "napt44-104"
    ...    "dpi-102-1"    "firewall-104"    "dpi-102-3"    "firewall-101-1"
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-random-schedule-type.json
    Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-roundrobin-schedule-type.json
    Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-loadbalance-schedule-type.json
    Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-shortestpath-schedule-type.json
