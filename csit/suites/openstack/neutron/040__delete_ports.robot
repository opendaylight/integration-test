*** Settings ***
Documentation     Checking Port deleted in OpenStack are deleted also in OpenDaylight
Suite Setup       Start Suite
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${ODLREST}       /controller/nb/v2/neutron/ports
${OSREST}        /v2.0/ports/${PORTID}
${data}          {"port":{"network_id":"${NETID}","admin_state_up": true}}

*** Test Cases ***
Delete New Port
    [Documentation]    Delete previously created port in OpenStack
    [Tags]    Delete port OpenStack Neutron
    Log    ${data}
    ${resp}    delete request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    204
    Log    ${resp.content}
    sleep    2

Check Port Deleted
    [Documentation]    Check port deleted in OpenDaylight
    [Tags]    Check port deleted OpenDaylight
    ${resp}    get request    ODLSession    ${ODLREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.content}
    Log    ${ODLResult}
    ${resp}    get request    ODLSession    ${ODLREST}/${PORTID}
    Should be Equal As Strings    ${resp.status_code}    404

*** Keywords ***
Check Port Exists
    [Arguments]    ${portid}
    ${resp}    get request    ODLSession    ${ODLREST}/${portid}
    Should be Equal As Strings    ${resp.status_code}    200

Start Suite
    Create Session    OSSession    http://${NEUTRON}:9696    headers=${X-AUTH}
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    Check Port Exists    ${PORTID}
