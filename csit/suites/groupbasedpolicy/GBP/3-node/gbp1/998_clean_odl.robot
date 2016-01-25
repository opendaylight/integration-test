*** Settings ***
Documentation     Test suite for cleaning up / unregister infrastructure constructs like endpoints for demo-asymmetric-chain
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Default Tags      single-tenant    teardown    single-tenant-teardown
Library           RequestsLibrary
Library           OperatingSystem
Library           json
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/RestconfUtils.robot
Resource          ../Variables.robot

*** Variables ***

*** Test Cases ***
Delete Tenant
    [Documentation]    Delete Tenants from ODL
    Remove All Elements At URI    ${TENANT1_PATH}

Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    RestconfUtils.Unregister Endpoints

Delete Nodes
    [Documentation]    Delete Nodes from ODL
    Remove All Elements At URI    ${TUNNELS_PATH}
