*** Settings ***
Documentation       Test suite for resourcepool

Library             RequestsLibrary
Variables           ../../../variables/Variables.py
Variables           ../../../variables/alto/Variables.py

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown      Delete All Sessions


*** Test Cases ***
Check the resource pool status
    [Documentation]    If default resource pool is ready, the resource pool has loaded sucessfully
    ${resp}    RequestsLibrary.Get Request    session    /${RESOURCE_POOL_BASE}/${DEFAULT_CONTEXT_ID}
    Should Be Equal As Strings    ${resp.status_code}    200
