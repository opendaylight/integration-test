*** Settings ***
Documentation     Test suite for SFC Service Functions using Logical SFF functionality, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
Test Teardown     Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${VERSION_DIR}    master
${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions-logicalsff.json
${SF_DPI_URI}     ${SERVICE_FUNCTION_URI}/dpi-1/
${SF_DPI_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sf_dpi.json

*** Test Cases ***
Add Service Functions
    [Documentation]    Add Service Functions from JSON file. Logical SFF
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-functions
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    service-functions
    Lists Should be Equal    ${function}    ${functions}

Delete All Service Functions
    [Documentation]    Delete all Service Functions. Logical SFF
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Service Function
    [Documentation]    Get one Service Function. Logical SFF
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${elements}=    Create List    firewall-1    firewall
    Check For Elements At URI    ${SERVICE_FUNCTION_URI}/firewall-1    ${elements}

Get A Non-existing Service Function
    [Documentation]    Get A Non-existing Service Function. Logical SFF
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_URI}/non-existing-sf
    Should Be Equal As Strings    ${resp.status_code}    404

Delete A Service Function
    [Documentation]    Delete A Service Function. Logical SFF
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Remove All Elements At URI    ${SERVICE_FUNCTION_URI}/dpi-1
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.text}    dpi-1

Delete A Non-existing Empty Service Function
    [Documentation]    Delete A Non existing Service Function. Logical SFF
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-functions
    ${resp}    RequestsLibrary.DELETE On Session    session    ${SERVICE_FUNCTION_URI}/non-existing-sf
    Should Be Equal As Strings    ${resp.status_code}    404
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    service-functions
    Lists Should be Equal    ${function}    ${functions}

Put one Service Function
    [Documentation]    Put one Service Function. Logical SFF
    [Tags]    include
    Add Elements To URI From File    ${SF_DPI_URI}    ${SF_DPI_FILE}
    ${elements}=    Create List    dpi-1    dpi
    Check For Elements At URI    ${SF_DPI_URI}    ${elements}
    Check For Elements At URI    ${SERVICE_FUNCTIONS_URI}    ${elements}

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables .Logical SFF
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
