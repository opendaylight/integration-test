*** Settings ***
Documentation     Test suite for SFC Rendered Service Paths. Logical SFF
Suite Setup       Init Suite
Suite Teardown    Delete All Elements
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment. Logical SFF
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Added    ${SF_NAMES}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${CREATED_SFPS}

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    ${rsp_name} =    Get Rendered Service Path Name    ${SFP_NAME}
    Get URI And Verify    ${OPERATIONAL_RSP_URI}${rsp_name}
    # The RSP should be symetric, so only 2 should be created for the SFP
    Check For Specific Number Of Elements At URI    ${SERVICE_FUNCTION_PATH_STATE_URI}${SFP_NAME}    "sfp-rendered-service-path"    2
    ${elements} =    Create List    "parent-service-function-path":"${SFP_NAME}"    "hop-number":0    "service-index":255    "hop-number":1    "service-index":254
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    ${rsp_name} =    Get Rendered Service Path Name    ${SFP_NAME}
    ${rsp_name_rev} =    Get Rendered Service Path Name    ${SFP_NAME}    True
    # First verify that the RSPs exist
    Get URI And Verify    ${OPERATIONAL_RSP_URI}${rsp_name}
    Get URI And Verify    ${OPERATIONAL_RSP_URI}${rsp_name_rev}
    # Delete the SFP, which will delete the RSPs
    Delete Sfp And Wait For Rsps Deletion    ${SFP_NAME}

Get Rendered Service Path Hop
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    # Create the SFP, which will create the RSPs
    Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}    ${CREATED_SFPS}
    ${rsp_name} =    Get Rendered Service Path Name    ${SFP_NAME}
    ${elements} =    Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements} =    Create List    "hop-number":1    "service-index":254    "service-function-name":"firewall-1
    Check For Elements At URI    ${OPERATIONAL_RSPS_URI}rendered-service-path/${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${resp} =    RequestsLibrary.Get Request    session    ${OPERATIONAL_RSPS_URI}rendered-service-path/RSP1/rendered-service-path-hop/2/
    Should Be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${SFP_NAME}    SFP1
    Set Suite Variable    @{CREATED_SFPS}    ${SFP_NAME}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions-logicalsff.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders-logicallsff.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains-logicalsff.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths-logicalsff.json
    Set Suite Variable    @{SF_NAMES}    "name":"firewall-1"    "name":"dpi-1"

Delete All Elements
    [Documentation]    Delete all provisioned elements
    Delete All Sessions
    Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
    Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Wait Until Keyword Succeeds    60s    2s    Check Service Function Types Removed    ${SF_NAMES}
