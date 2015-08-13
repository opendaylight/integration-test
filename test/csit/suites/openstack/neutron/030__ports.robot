*** Settings ***
Documentation     Checking Port created in OpenStack are pushed to OpenDaylight
Suite Setup       Create Session    OSSession    http://${OPENSTACK}:9696    headers=${X-AUTH}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
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
    ${resp}    get    OSSession    ${OSREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${OSResult}    To Json    ${resp.content}
    Set Suite Variable    ${OSResult}
    Log    ${OSResult}

Check OpenDaylight ports
    [Documentation]    Checking OpenDaylight Neutron API for Known Ports
    [Tags]    Ports Neutron OpenDaylight
    Create Session    ODLSession    http://${CONTROLLER}:${PORT}    headers=${HEADERS}    auth=${AUTH}
    ${resp}    get    ODLSession    ${ODLREST}
    Should be Equal As Strings    ${resp.status_code}    200
    ${ODLResult}    To Json    ${resp.content}
    Set Suite Variable    ${ODLResult}
    Log    ${ODLResult}

Create New Port
    [Documentation]    Create new port in OpenStack
    [Tags]    Create port OpenStack Neutron
    Log    ${data}
    ${resp}    post    OSSession    ${OSREST}    data=${data}
    Should be Equal As Strings    ${resp.status_code}    201
    ${result}    To JSON    ${resp.content}
    ${result}    Get From Dictionary    ${result}    port
    ${PORTID}    Get From Dictionary    ${result}    id
    Log    ${result}
    Log    ${PORTID}
    Set Global Variable    ${PORTID}
    sleep    2

Check New Port
    [Documentation]    Check new subnet created in OpenDaylight
    [Tags]    Check subnet OpenDaylight
    ${resp}    get    ODLSession    ${ODLREST}/${PORTID}
    Should be Equal As Strings    ${resp.status_code}    200
