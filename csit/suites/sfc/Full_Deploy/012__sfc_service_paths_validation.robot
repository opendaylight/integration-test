*** Settings ***
Documentation     Test suite for SFC Service Function Paths validation. This validation is in charge of verifying that the SF types for the SFs defined in newly added SFPs are consistent with SF types defined in the referenced SFC.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
Test Teardown     Clean_All_URIs
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Add Service Function Path referencing a non-existing SF
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File And Check Validation Error    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Add Service Function Path referencing a non-existing SFC
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File And Check Validation Error    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}

Add Service Function Path where SFC types size and hop sizes differ
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File And Check Validation Error    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}

Add Service Function Path where SFC types size and types for SFs in hops differ
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File And Check Validation Error    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_WITH_THREE_HOPS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}

Add Service Function Path where SFC types size and types for SFs in hops match
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE_FW_NAPT44_DPI}
    Add Elements To URI From File And Verify    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_WITH_THREE_HOPS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-paths
    Lists Should be Equal    ${path}    ${paths}

*** keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SFC_JSON_TEST_FILES_DIR}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${SFC_JSON_TEST_FILES_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_URI}    ${SERVICE_FUNCTION_PATHS_URI}/SFC1-400
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_FILE}    ${SFC_JSON_TEST_FILES_DIR}/sfp_sfc1_path400.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_WITH_HOP_FILE}    ${SFC_JSON_TEST_FILES_DIR}/service-function-paths-with-one-hop.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_WITH_THREE_HOPS_FILE}    ${SFC_JSON_TEST_FILES_DIR}/service-function-paths-with-three-hops-firewall-napt44-dpi.json
    Set Suite Variable    ${SFC_MODEL_VALIDATION_ERROR}    ${500}
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${SFC_JSON_TEST_FILES_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${SFC_JSON_TEST_FILES_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE_FW_NAPT44_DPI}    ${SFC_JSON_TEST_FILES_DIR}/service-function-chain-firewall-napt44-dpi.json

Clean_All_URIs
    [Documentation]    Deletes all the elements which might have been created during SFP validation tests
    Utils.Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_CHAINS_URI}
    Utils.Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
