*** Settings ***
Documentation     Test suite for SFC Service Function Paths, Operates paths from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_PATHS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Add Service Function Paths
    [Documentation]    Add Service Function Paths from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-paths
    Lists Should be Equal    ${path}    ${paths}

Delete All Service Function Paths
    [Documentation]    Delete all Service Function Paths
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function Path
    [Documentation]    Get one Service Function Path
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${elements}=    Create List    SFC1-100    "service-chain-name":"SFC1"
    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100    ${elements}

Get A Non-existing Service Function Path
    [Documentation]    Get A Non-existing Service Function Path
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/non-existing-sfp
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function Path
    [Documentation]    Delete A Service Function Path
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/SFC1-100
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    SFC1-100

Delete A Non-existing Empty Service Function Path
    [Documentation]    Delete A Non existing Service Function Path
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_PATHS_FILE}
    ${jsonbody}    To Json    ${body}
    ${paths}    Get From Dictionary    ${jsonbody}    service-function-paths
    ${resp}    RequestsLibrary.Delete Request    session    ${SERVICE_FUNCTION_PATHS_URI}service-function-path/non-existing-sfp
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${path}    Get From Dictionary    ${result}    service-function-paths
    Lists Should be Equal    ${path}    ${paths}

Put one Service Function
    [Documentation]    Put one Service Function
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATH400_URI}    ${SERVICE_FUNCTION_PATH400_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATH400_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    SFC1-400
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_PATHS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Contain    ${resp.content}    SFC1-400

*** keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_URI}    /restconf/config/service-function-path:service-function-paths/
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-paths.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_URI}    /restconf/config/service-function-path:service-function-paths/service-function-path/SFC1-400
    Set Suite Variable    ${SERVICE_FUNCTION_PATH400_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sfp_sfc1_path400.json
