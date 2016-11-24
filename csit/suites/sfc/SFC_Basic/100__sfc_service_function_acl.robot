*** Settings ***
Documentation     Test suite for SFC Service Function ACL, Operates functions from Restconf APIs.
Suite Setup       Init Suite
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_ACL_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot

*** Test Cases ***
Add ACL
    [Documentation]    Add Service Function ACL from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    ${jsonbody}    To Json    ${body}
    ${keys}       Get Dictionary Keys    ${jsonbody}
    ${functions}    Get From Dictionary    ${jsonbody}    access-lists
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    ${result}    To JSON    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${function}    Get From Dictionary    ${result}    access-lists
    Lists Should be Equal    ${function}    ${functions}
    Remove All ACLs

Delete All ACLs
    [Documentation]    Delete all ACL
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACL_URI}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Be Equal As Strings    ${resp.status_code}    404

Get one ACL
    [Documentation]    Get one ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}acl/ietf-access-control-list:ipv4-acl/ACL1
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All ACLs

Get A Non-existing ACL
    [Documentation]    Get A Non-existing ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}acl/unexisting-acl
    Should Be Equal As Strings    ${resp.status_code}    404
    Remove All ACLs

Delete An ACL
    [Documentation]    Delete an ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACL_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACL_URI}acl/ietf-access-control-list:ipv4-acl/ACL1
    ${resp}    RequestsLibrary.Get Request    session    ${SERVICE_FUNCTION_ACL_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.content}    ACL1
    Remove All ACLs



*** Keywords ***
Init Suite
    [Documentation]    Initialize session and ODL version specific variables
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    Set Suite Variable    ${SERVICE_FUNCTION_ACL_URI}    /restconf/config/ietf-access-control-list:access-lists/
    Set Suite Variable    ${SERVICE_FUNCTION_ACL_FILE}    ${CURDIR}/../../../variables/sfc/master/service-function-acl.json

Remove All ACLs
    [Documentation]    Delete all ACL
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACL_URI}
