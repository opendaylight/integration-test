*** Settings ***
Documentation     Test suite for resourcepool
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${ACCEPT_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${RESOURCE_POOL_BASE}    /restconf/operational/alto-resourcepool:context
${DEFAULT_CONTEXT_ID}    /00000000-0000-0000-0000-000000000000

*** Test Cases ***
Check the resource pool status
    [Documentation]    If default resource pool is ready, the resource pool has loaded sucessfully
    ${resp}    RequestsLibrary.Get    session    ${RESOURCE_POOL_BASE}${DEFAULT_CONTEXT_ID}
    Should Be Equal As Strings    ${resp.status_code}    200
