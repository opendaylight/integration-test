*** Settings ***
Documentation     Test suite for SFC Rendered Service Paths. Logical SFF
Suite Setup       Init Suite
Suite Teardown    Delete All Elements
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../libraries/SFC/SfcKeywords.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VERSION_DIR}    master
${TEST_DIR}       ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
${SERVICE_FUNCTIONS_FILE}    ${TEST_DIR}/service-functions-logicalsff.json
${SERVICE_FORWARDERS_FILE}    ${TEST_DIR}/service-function-forwarders-logicallsff.json
${SERVICE_CHAINS_FILE}    ${TEST_DIR}/service-function-chains-logicalsff.json
${SERVICE_FUNCTION_PATHS_FILE}    ${TEST_DIR}/service-function-paths-logicalsff.json
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
    Utils.Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Utils.Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Added    ${SF_NAMES}
    Utils.Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}

Get Rendered Service Path By Name
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    # The RSP should be symetric, so 2 should be created for the SFP
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}/${rsp_name}
    ${rsp_name_rev} =    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}/${rsp_name_rev}
    ${elements} =    Create List    "parent-service-function-path":"${SFP_NAME}"    "hop-number":0    "service-index":255    "hop-number":1    "service-index":254
    Utils.Check For Elements At URI    ${OPERATIONAL_RSPS_URI}    ${elements}

Delete one Rendered Service Path By Name
    [Documentation]    Delete One Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    # First verify that the RSPs exist
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}/${rsp_name}
    ${rsp_name_rev} =    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}    True
    Utils.Get URI And Verify    ${OPERATIONAL_RSP_URI}/${rsp_name_rev}
    # Delete the SFP, which will delete the RSPs
    SfcKeywords.Delete Sfp And Wait For Rsps Deletion    ${SFP_NAME}

Get Rendered Service Path Hop
    [Documentation]    Get Rendered Service Path By Name Through RESTConf APIs. Logical SFF
    # Create the SFP, which will create the RSPs
    SfcKeywords.Create Sfp And Wait For Rsp Creation    ${SERVICE_FUNCTION_PATHS_FILE}
    ${rsp_name} =    SfcKeywords.Get Rendered Service Path Name    ${SFP_NAME}
    ${elements} =    BuiltIn.Create List    "hop-number":0    "service-index":255    "service-function-name":"dpi-1
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/0/    ${elements}
    ${elements} =    BuiltIn.Create List    "hop-number":1    "service-index":254    "service-function-name":"firewall-1
    Utils.Check For Elements At URI    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/1/    ${elements}
    ${resp} =    RequestsLibrary.GET On Session    session    ${OPERATIONAL_RSP_URI}/${rsp_name}/rendered-service-path-hop/2/
    BuiltIn.Should Be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Init Suite
    [Documentation]    Create session and initialize ODL version specific variables
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    BuiltIn.log    ${ODL_STREAM}
    BuiltIn.Set Suite Variable    ${SFP_NAME}    SFP1
    BuiltIn.Set Suite Variable    ${VERSION_DIR}    master
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions-logicalsff.json
    BuiltIn.Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-forwarders-logicallsff.json
    BuiltIn.Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-chains-logicalsff.json
    BuiltIn.Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths-logicalsff.json
    BuiltIn.Set Suite Variable    @{SF_NAMES}    "name":"firewall-1"    "name":"dpi-1"

Delete All Elements
    [Documentation]    Delete all provisioned elements
    Utils.Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_FORWARDERS_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    BuiltIn.Wait Until Keyword Succeeds    60s    2s    SfcKeywords.Check Service Function Types Removed    ${SF_NAMES}
    RequestsLibrary.Delete All Sessions
