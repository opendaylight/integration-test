*** Settings ***
Documentation     Test suite for B&R support library itself
Suite Setup       Run Keywords    Init Suite    ClusterManagement Setup
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTIONS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/BackupRestoreKeywords.robot

*** Test Cases ***
ConditionalBackupRestoreCheck keyword
    [Documentation]    Demostrates how the ConditionalBackupRestoreCheck keyword can be used together with the flag " -v BR_TESTING_ENABLED:false/true" in order to add backup-restore verification to existing testcases
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    ConditionalBackupRestoreCheck
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-functions
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    service-functions
    Lists Should be Equal    ${function}    ${functions}

BackupRestoreCheck keyword
    [Documentation]    Demostrates how the BackupRestoreCheck keyword can be used in order to create specific testcases performing backup-restore verification
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Run Keyword And Expect Error    *    BackupRestoreCheck    exclusionsOperationalBefore=../variables/backuprestore/json_prefilter.conf
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTIONS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTIONS_URI}    /restconf/config/service-function:service-functions/
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-functions.json
    Set Suite Variable    ${SF_DPI102100_URI}    /restconf/config/service-function:service-functions/service-function/dpi-102-100/
    Set Suite Variable    ${SF_DPI102100_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sf_dpi_102_100.json
    Set Suite Variable    ${SF_DPL101_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/sf_dpl_101.json
