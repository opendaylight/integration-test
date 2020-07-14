*** Settings ***
Documentation     Checking Network deleted in OpenStack are deleted also in OpenDaylight
Suite Setup       Start Suite
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot

*** Variables ***
${OSREST}         /v2.0/networks/${NETID}
${postNet}        {"network":{"name":"odl_network","admin_state_up":true}}

*** Test Cases ***
Delete Network
    [Documentation]    Delete network in OpenStack
    [Tags]    Delete Network OpenStack Neutron
    Log    ${postNet}
    ${resp}    delete request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.text}
    sleep    2

Check Network deleted
    [Documentation]    Check network deleted in OpenDaylight
    [Tags]    Check Network OpenDaylight
    ${resp}    get request    ODLSession    ${NEUTRON_NETWORKS_API}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.text}
    Log    ${ODLResult}
    ${resp}    get request    ODLSession    ${NEUTRON_NETWORKS_API}/${NETID}
    Should be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Check Network Exists
    [Arguments]    ${netid}
    ${resp}    get request    ODLSession    ${NEUTRON_NETWORKS_API}/${netid}
    Should be Equal As Strings    ${resp.status_code}    200

Start Suite
    Create Session    OSSession    ${NEUTRONURL}    headers=${X-AUTH-NOCONTENT}
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    Check Network Exists    ${NETID}
