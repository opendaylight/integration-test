*** Settings ***
Documentation     Checking Port created in OpenStack are pushed to OpenDaylight
Suite Setup       Create Session    OSSession    http://${NEUTRON}:9696    headers=${X-AUTH}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Variables         ../../../variables/Variables.py

*** Variables ***
${ODLREST}        /controller/nb/v2/neutron/ports
${OSREST}         /v2.0/ports
${data}           {"port":{"network_id":"${NETID}","admin_state_up": true}}

*** Test Cases ***
Check OpenStack ports
    [Documentation]    Checking OpenStack Neutron for known ports
    [Tags]    Ports Neutron OpenStack
    Log    ${X-AUTH}
    ${resp}    get request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${OSResult}    To Json    ${resp.content}
    Log    ${OSResult}

Check OpenDaylight ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    [Tags]    Ports Neutron OpenDaylight
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    ${resp}    get request    ODLSession    ${ODLREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.content}
    Log    ${ODLResult}

Create New Port
    [Documentation]    Create new port in OpenStack
    [Tags]    Create port OpenStack Neutron
    Log    ${data}
    ${resp}    post request    OSSession    ${OSREST}    data=${data}
    Should be Equal As Strings    ${resp.status_code}    201
    ${result}    To JSON    ${resp.content}
    ${result}    Get From Dictionary    ${result}    port
    ${PORTID}    Get From Dictionary    ${result}    id
    Log    ${result}
    Log    ${PORTID}
    Set Global Variable    ${PORTID}
    sleep    2

Check New Port
    [Documentation]    Check new port created in OpenDaylight
    [Tags]    Check subnet OpenDaylight
    ${resp}    get request    ODLSession    ${ODLREST}/${PORTID}
    Should be Equal As Strings    ${resp.status_code}    200
