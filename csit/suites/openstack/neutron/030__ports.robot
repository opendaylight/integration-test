*** Settings ***
Documentation     Checking Port created in OpenStack are pushed to OpenDaylight
Suite Setup       Create Session    OSSession    ${NEUTRONURL}    headers=${X-AUTH}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot

*** Variables ***
${OSREST}         /v2.0/ports
${data}           {"port":{"network_id":"${NETID}","admin_state_up": true}}

*** Test Cases ***
Check OpenStack ports
    [Documentation]    Checking OpenStack Neutron for known ports
    [Tags]    Ports Neutron OpenStack
    Log    ${X-AUTH}
    ${resp}    get request    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${OSResult}    To Json    ${resp.text}
    Log    ${OSResult}

Check OpenDaylight ports
    [Documentation]    Checking OpenDaylight Neutron API for known ports
    [Tags]    Ports Neutron OpenDaylight
    Create Session    ODLSession    http://${ODL_SYSTEM_IP}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    ${resp}    get request    ODLSession    ${NEUTRON_PORTS_API}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.text}
    Log    ${ODLResult}

Create New Port
    [Documentation]    Create new port in OpenStack
    [Tags]    Create port OpenStack Neutron
    Log    ${data}
    ${resp}    post request    OSSession    ${OSREST}    data=${data}
    Should be Equal As Strings    ${resp.status_code}    201
    ${result}    To JSON    ${resp.text}
    ${result}    Get From Dictionary    ${result}    port
    ${PORTID}    Get From Dictionary    ${result}    id
    Log    ${result}
    Log    ${PORTID}
    Set Global Variable    ${PORTID}
    sleep    2

Check New Port
    [Documentation]    Check new port created in OpenDaylight
    [Tags]    Check port OpenDaylight
    ${resp}    get request    ODLSession    ${NEUTRON_PORTS_API}/${PORTID}
    Should be Equal As Strings    ${resp.status_code}    200
