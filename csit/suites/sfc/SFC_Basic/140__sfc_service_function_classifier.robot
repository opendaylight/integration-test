*** Settings ***
Documentation     Test suite for SFC Service Function Classifiers, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_CLASSIFIERS_URI}
Test Teardown     Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_CLASSIFIER_FILE}    ${CURDIR}/../../../variables/sfc/master/service-function-classifiers.json

*** Test Cases ***
Add Service Function Classifier
    [Documentation]    Add Service Function Classifiers from JSON file
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_CLASSIFIER_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    service-function-classifiers
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}
    ${result}    To JSON    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${function}    Get From Dictionary    ${result}    service-function-classifiers
    Lists Should be Equal    ${function}    ${functions}

Delete All Classifiers
    [Documentation]    Delete all Classifiers
    ${body}    OperatingSystem.Get File    ${SERVICE_CLASSIFIER_FILE}
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    [Teardown]    NONE

Get one Classifier
    [Documentation]    Get one Classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}/service-function-classifier/Classifier1
    Should Be Equal As Strings    ${resp.status_code}    200

Get A Non-existing Classifier
    [Documentation]    Get A Non-existing Classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIER_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}/service-function-classifier/nonexistant-classifier
    Should Be Equal As Strings    ${resp.status_code}    404

Delete a Classifier
    [Documentation]    Delete a classifier
    Add Elements To URI From File    ${SERVICE_CLASSIFIERS_URI}    ${SERVICE_CLASSIFIER_FILE}
    Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}/service-function-classifier/Classifier1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_CLASSIFIERS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.text}    Classifier1
