*** Settings ***
Documentation     Test suite for SFC Rendered Service Paths, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Utils.Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Added    ${SERVICE_FUNCTION_NAMES}
    Utils.Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    # Creates SFPs: SFC1-100, SFC1-200, SFC1-300, SFC2-100, and SFC2-200
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}

Get Rendered Service Path By Name
    [Documentation]    Get The Rendered Service Path Created in "Basic Environment Setup Tests" By Name Via RESTConf APIs
    ${sfp_name} =    BuiltIn.Set Variable    SFC1-100
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${sfp_name}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp_name}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    # The RSP should not be symetric, so only 1 should be created for the SFP
    Utils.Check For Specific Number Of Elements At URI    ${SERVICE_FUNCTION_PATH_STATE_URI}/${sfp_name}    "sfp-rendered-service-path"    1
    ${elements} =    BuiltIn.Create List    "parent-service-function-path":"SFC1-100"    "hop-number":0    "service-index":255    "hop-number":1    "service-index":254
    ...    "hop-number":2    "service-index":253
    Utils.Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Get Rendered Service Path Hop
    [Documentation]    Check Rendered Service Path Hops Created in "Basic Environment Setup Tests"
    ${sfp_name} =    BuiltIn.Set Variable    SFC1-100
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${sfp_name}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/0/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${elements} =    BuiltIn.Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/2/    ${elements}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/3/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    404

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By deleting the parent Service Function Path
    ...    The RSP to be deleted was created in "Basic Environment Setup Tests"
    ${sfp_name} =    BuiltIn.Set Variable    SFC2-200
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${sfp_name}
    # First verify that the RSP exists
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp_name}
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    SfcKeywords.Delete Sfp And Wait For Rsps Deletion    ${sfp_name}

Generate RSPs with Random Schedule Algorithm type
    [Documentation]    Generate RSPs with Random Schedule Algorithm type Through RESTConf APIs
    Utils.Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Utils.Add Elements To URI From File    ${SERVICE_RANDOM_SCHED_TYPE_URI}    ${SERVICE_RANDOM_SCHED_TYPE_FILE}
    SfcKeywords.Delete All Sfps And Wait For Rsps Deletion
    # Create the SFPs which will create the RSPs with the Random scheduler
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}
    ${sfp_name} =    BuiltIn.Set Variable    SFC1-100
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${sfp_name}
    ${elements} =    BuiltIn.Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/2/    ${elements}

Generate RSPs with Round Robin Schedule Algorithm type
    [Documentation]    Generate RSPs with Round Robin Schedule Algorithm type
    [Tags]    exclude
    Utils.Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Utils.Add Elements To URI From File    ${SERVICE_ROUNDROBIN_SCHED_TYPE_URI}    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}
    SfcKeywords.Delete All Sfps And Wait For Rsps Deletion
    # Create the SFPs which will create the RSPs with the Random scheduler
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}
    ${rsp1_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-100
    ${rsp2_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-200
    ${rsp3_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-300
    ${rsp4_name} =    SfcKeywords.Get Rendered Service Path Name    SFC2-100
    ${rsp5_name} =    SfcKeywords.Get Rendered Service Path Name    SFC2-200
    ${path1_hop0} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    ${path1_hop1} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    ${path1_hop2} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    ${path2_hop0} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    ${path2_hop1} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    ${path2_hop2} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    ${path3_hop0} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    ${path3_hop1} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    ${path3_hop2} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    ${path4_hop0} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    ${path4_hop1} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    ${path4_hop2} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    ${path5_hop0} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    ${path5_hop1} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    ${path5_hop2} =    SfcKeywords.Get JSON Elements From URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    BuiltIn.Should Be Equal    ${path1_hop0}    ${path4_hop0}
    BuiltIn.Should Not Be Equal    ${path1_hop0}    ${path2_hop0}
    BuiltIn.Should Be Equal    ${path1_hop1}    ${path4_hop1}
    BuiltIn.Should Not Be Equal    ${path1_hop1}    ${path2_hop1}
    BuiltIn.Should Be Equal    ${path1_hop2}    ${path4_hop2}
    BuiltIn.Should Not Be Equal    ${path1_hop2}    ${path2_hop2}
    BuiltIn.Should Be Equal    ${path2_hop0}    ${path5_hop0}
    BuiltIn.Should Not Be Equal    ${path2_hop0}    ${path3_hop0}
    BuiltIn.Should Be Equal    ${path2_hop1}    ${path5_hop1}
    BuiltIn.Should Not Be Equal    ${path2_hop1}    ${path3_hop1}
    BuiltIn.Should Be Equal    ${path2_hop2}    ${path5_hop2}
    BuiltIn.Should Not Be Equal    ${path2_hop2}    ${path3_hop2}
    BuiltIn.Should Be Equal    ${path3_hop0}    ${path1_hop0}
    BuiltIn.Should Not Be Equal    ${path3_hop0}    ${path1_hop0}
    BuiltIn.Should Be Equal    ${path3_hop1}    ${path1_hop1}
    BuiltIn.Should Not Be Equal    ${path3_hop1}    ${path1_hop1}
    BuiltIn.Should Be Equal    ${path3_hop2}    ${path1_hop2}
    BuiltIn.Should Not Be Equal    ${path3_hop2}    ${path1_hop2}

Generate RSPs with Shortest Path Schedule Algorithm type
    [Documentation]    Generate RSPs with Shortest Path Schedule Algorithm type Through RESTConf APIs
    Utils.Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Utils.Add Elements To URI From File    ${SERVICE_SHORTESTPATH_SCHED_TYPE_URI}    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}
    SfcKeywords.Delete All Sfps And Wait For Rsps Deletion
    # Create the SFPs which will create the RSPs with the Random scheduler
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}
    ${rsp1_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-100
    ${rsp2_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-200
    ${rsp3_name} =    SfcKeywords.Get Rendered Service Path Name    SFC1-300
    ${rsp4_name} =    SfcKeywords.Get Rendered Service Path Name    SFC2-100
    ${rsp5_name} =    SfcKeywords.Get Rendered Service Path Name    SFC2-200
    ${elements} =    BuiltIn.Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":1    "service-index":254    "service-function-name":"napt44
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":2    "service-index":253    "service-function-name":"firewall
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/    ${elements}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/0/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${temp_vars}=    BuiltIn.Set Variable    ['rendered-service-path-hop'][0]['service-function-forwarder']
    ${fwd_hop1} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/1/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp1_name}/rendered-service-path-hop/2/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop3} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    BuiltIn.Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    BuiltIn.Should Be Equal    ${fwd_hop2}    ${fwd_hop3}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp2_name}/rendered-service-path-hop/0/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop1} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp2_name}/rendered-service-path-hop/1/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop2} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSP_URI}/${rsp2_name}/rendered-service-path-hop/2/
    BuiltIn.Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${fwd_hop3} =    Utils.Extract Value From Content    ${resp.content}    ${temp_vars}
    BuiltIn.Should Be Equal    ${fwd_hop1}    ${fwd_hop2}
    BuiltIn.Should Be Equal    ${fwd_hop2}    ${fwd_hop3}

Clean Datastore After Tests
    [Documentation]    Clean All Items In Datastore After Tests
    Utils.Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Removed    ${SERVICE_FUNCTION_NAMES}
    Utils.Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Utils.Remove All Elements At URI    ${SERVICE_NODES_URI}
    Utils.Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Utils.Remove All Elements At URI    ${SERVICE_SCHED_TYPES_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Empty Service Function Paths State

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.log    ${ODL_STREAM}
    BuiltIn.Set Suite Variable    ${VERSION_DIR}    master
    BuiltIn.Set Suite Variable    ${TEST_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${TEST_DIR}/service-functions.json
    BuiltIn.Set Suite Variable    @{SERVICE_FUNCTION_NAMES}    "napt44-103-2"    "napt44-103-1"    "dpi-102-2"    "firewall-101-2"    "napt44-104"
    ...    "dpi-102-1"    "firewall-104"    "dpi-102-3"    "firewall-101-1"
    BuiltIn.Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${TEST_DIR}/service-function-forwarders.json
    BuiltIn.Set Suite Variable    ${SERVICE_NODES_FILE}    ${TEST_DIR}/service-nodes.json
    BuiltIn.Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${TEST_DIR}/service-function-chains.json
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${TEST_DIR}/service-function-paths.json
    BuiltIn.Set Suite Variable    ${SERVICE_RANDOM_SCHED_TYPE_FILE}    ${TEST_DIR}/service-random-schedule-type.json
    BuiltIn.Set Suite Variable    ${SERVICE_ROUNDROBIN_SCHED_TYPE_FILE}    ${TEST_DIR}/service-roundrobin-schedule-type.json
    BuiltIn.Set Suite Variable    ${SERVICE_LOADBALANCE_SCHED_TYPE_FILE}    ${TEST_DIR}/service-loadbalance-schedule-type.json
    BuiltIn.Set Suite Variable    ${SERVICE_SHORTESTPATH_SCHED_TYPE_FILE}    ${TEST_DIR}/service-shortestpath-schedule-type.json
