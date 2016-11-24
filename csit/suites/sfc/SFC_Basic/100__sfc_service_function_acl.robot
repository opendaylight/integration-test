*** Settings ***
Documentation     Test suite for SFC Service Function ACL, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_ACL_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Test Cases ***
Add ACL
    [Documentation]    Add Service Function ACL from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    ${jsonbody}    To Json    ${body}
    ${keys}       Get Dictionary Keys    ${jsonbody}
    ${functions}    Get From Dictionary    ${jsonbody}    access-lists
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${result}    To JSON    ${resp.content}
    ${function}    Get From Dictionary    ${result}    access-lists
    Lists Should be Equal    ${function}    ${functions}

Delete All ACLs
    [Documentation]    Delete all ACL
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACL_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one ACL
    [Documentation]    Get one ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}acl/ietf-access-control-list:ipv4-acl/ACL1
    Should Be Equal As Strings    ${resp.status_code}    200

Get A Non-existing ACL
    [Documentation]    Get A Non-existing ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}acl/unexisting-acl
    Should Be Equal As Strings    ${resp.status_code}    404

Delete An ACL
    [Documentation]    Delete an ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACL_URI}acl/ietf-access-control-list:ipv4-acl/ACL1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    ACL1



*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    log    ${ODL_STREAM}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    Set Suite Variable    ${SERVICE_FUNCTION_ACL_URI}    /restconf/config/ietf-access-control-list:access-lists/
    Set Suite Variable    ${SERVICE_FUNCTION_ACL_FILE}    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/service-function-acl.json
