*** Settings ***
Documentation     Test suite for SFC Service Function ACL, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Test Setup        Remove All Elements If Exist    ${SERVICE_FUNCTION_ACLS_URI}
Test Teardown     Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${SERVICE_FUNCTION_ACL_FILE}    ${CURDIR}/../../../variables/sfc/master/service-function-acl.json

*** Test Cases ***
Add ACL
    [Documentation]    Add Service Function ACL from JSON file
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    ${jsonbody}    To Json    ${body}
    ${functions}    Get From Dictionary    ${jsonbody}    access-lists
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}
    ${result}    To JSON    ${resp.content}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    ${function}    Get From Dictionary    ${result}    access-lists
    Lists Should be Equal    ${function}    ${functions}

Delete All ACLs
    [Documentation]    Delete all ACL
    ${body}    OperatingSystem.Get File    ${SERVICE_FUNCTION_ACL_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}
    Should Be Equal As Strings    ${resp.status_code}    404
    [Teardown]    NONE

Get one ACL
    [Documentation]    Get one ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}/acl/ietf-access-control-list:ipv4-acl/ACL1
    Should Be Equal As Strings    ${resp.status_code}    200

Get A Non-existing ACL
    [Documentation]    Get A Non-existing ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}/acl/unexisting-acl
    Should Be Equal As Strings    ${resp.status_code}    404

Delete An ACL
    [Documentation]    Delete an ACL
    Add Elements To URI From File    ${SERVICE_FUNCTION_ACLS_URI}    ${SERVICE_FUNCTION_ACL_FILE}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}/acl/ietf-access-control-list:ipv4-acl/ACL1
    ${resp}    RequestsLibrary.GET On Session    session    ${SERVICE_FUNCTION_ACLS_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Should Not Contain    ${resp.text}    ACL1
