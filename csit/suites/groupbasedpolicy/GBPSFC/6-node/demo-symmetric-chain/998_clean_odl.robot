*** Settings ***
Documentation     Test suite for cleaning up / unregister infrastructure constructs like endpoints for demo-symmetric-chain
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           OperatingSystem
Library           Collections
Library           json
Variables         ../../../../../variables/Variables.py
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/RestconfUtils.robot
Resource          ../Variables.robot

*** Test Cases ***
Delete Service Function Paths
    [Documentation]    Delete Service Function Paths from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFP_PATH}

Delete Service Function Chains
    [Documentation]    Delete Service Function Chains from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFC_PATH}

Delete Service Functions
    [Documentation]    Delete Service Function from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SF_PATH}

Delete Service Function Forwarders
    [Documentation]    Delete Service Function Forwarders from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${SFF_PATH}

Delete Tunnels
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${TUNNELS_PATH}

Delete Tenant
    [Documentation]    Delete Tenant from ODL
    [Tags]    GBPSFCTEAR
    Remove All Elements At URI And Verify    ${TENANT_PATH}

Unregister Endpoints
    [Documentation]    Unregister Endpoints Endpoints from ODL
    [Tags]    GBPSFCTEAR
    RestconfUtils.Unregister Endpoints

Delete OVSDB Topology If Present
    [Documentation]    Delete OVSDB topology from ODL
    [Tags]    GBPSFCTEAR
    ${resp}    RequestsLibrary.Get Request    session    ${TOPOLOGY_PATH}
    Run Keyword If    ${resp.status_code} == 200    Remove All Elements At URI And Verify    ${TOPOLOGY_PATH}
