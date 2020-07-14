*** Settings ***
Documentation     Checking Network created in OpenStack are pushed to OpenDaylight
Suite Setup       Create Session    OSSession    ${NEUTRONURL}    headers=${X-AUTH}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot

*** Variables ***
${OSREST}         /v2.0/networks
${postNet}        {"network":{"name":"odl_network","admin_state_up":true}}

*** Test Cases ***
Check OpenStack Networks
    [Documentation]    Checking OpenStack Neutron for known networks
    [Tags]    Network Neutron OpenStack
    Log    ${X-AUTH}
    ${resp}    get request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${OSResult}    To Json    ${resp.text}
    Log    ${OSResult}

Check OpenDaylight Networks
    [Documentation]    Checking OpenDaylight Neutron API for known networks
    [Tags]    Network Neutron OpenDaylight
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    ${resp}    get request    ODLSession    ${NEUTRON_NETWORKS_API}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.text}
    Log    ${ODLResult}

Create Network
    [Documentation]    Create new network in OpenStack
    [Tags]    Create Network OpenStack Neutron
    Log    ${postNet}
    ${resp}    post request    OSSession    ${OSREST}    data=${postNet}
    Should be Equal As Strings    ${resp.status_code}    201
    ${result}    To JSON    ${resp.text}
    ${result}    Get From Dictionary    ${result}    network
    ${NETID}    Get From Dictionary    ${result}    id
    Log    ${result}
    Log    ${NETID}
    Set Global Variable    ${NETID}
    sleep    2

Check Network
    [Documentation]    Check network created in OpenDaylight
    [Tags]    Check    Network OpenDaylight
    ${resp}    get request    ODLSession    ${NEUTRON_NETWORKS_API}/${NetID}
    Should be Equal As Strings    ${resp.status_code}    200
