*** Settings ***
Documentation     Test suite for SFC Service Function Classifiers, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_CLASSIFIER_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Add Service Function Classifier
    [Documentation]    Add Service Function Classifiers from JSON file
    Add Elements To URI From File    ${SERVICE_CLASSIFIER_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CLASSIFIER_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-function-classifiers
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}
    ${result}    To JSON    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${function}    Get From Dictionary    ${result}    service-function-classifiers
    Lists Should be Equal    ${function}    ${functions}
    Remove All Classifiers

Delete All Classifiers
    [Documentation]    Delete all Classifiers
    ${body}    OperatingSystem.Get File    ${SERVICE_CLASSIFIER_FILE}
    Add Elements To URI From File    ${SERVICE_CLASSIFIER_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_CLASSIFIER_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one Classifier
    [Documentation]    Get one Classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIER_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}service-function-classifier/Classifier1
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Classifiers

Get A Non-existing Classifier
    [Documentation]    Get A Non-existing Classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIER_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}service-function-classifier/unexisting-classifier
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove All Classifiers

Delete a Classifier
    [Documentation]    Delete a classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIER_URI}    ${SERVICE_CLASSIFIER_FILE}
    Remove All Elements At URI    ${SERVICE_CLASSIFIER_URI}service-function-classifier/Classifier1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIER_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    Classifier1
    Remove All Classifiers


*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_CLASSIFIER_URI}    /restconf/config/service-function-classifier:service-function-classifiers/
    Set Suite Variable    ${SERVICE_CLASSIFIER_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-classifiers.json

Remove All Classifiers
    [Documentation]    Delete all Classifiers
    Remove All Elements At URI    ${SERVICE_CLASSIFIER_URI}
