*** Settings ***
Documentation     Checking Network created in OVSDB are pushed to OpenDaylight
Suite Setup       Create Session    ODLSession    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${ODLREST_CAPP}    /restconf/config/packetcable:ccap
${PACKETCABLE_CONFIG_DIR}    ${CURDIR}/../../../variables/packetcable
${CCAP_ID1}       93b7d8de-15fb-11e5-b60b-1697f925ec7b
${CCAP_ID2}       dc13b3fc-15fe-11e5-b60b-1697f925ec7b
${CCAP_IP1}       192.168.1.101
${CCAP_IP2}       192.168.1.102

*** Test Cases ***
Add CCAP
    [Documentation]    Add Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    ${Data}    OperatingSystem.Get File    ${PACKETCABLE_CONFIG_DIR}/add_ccap.json
    ${Data}    Replace String    ${Data}    {ccapId-1}    ${CCAP_ID1}
    ${Data}    Replace String    ${Data}    {ccapIp-1}    ${CCAP_IP1}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST_CAPP}/ccaps/${CCAP_ID1}    data=${Data}    headers=${HEADERS}
    Should be Equal As Strings    ${resp.status_code}    200

Get CCAP
    [Documentation]    Get Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Get    ODLSession    ${ODLREST_CAPP}/ccaps/${CCAP_ID1}
    Should be Equal As Strings    ${resp.status_code}    200

Delete CAPP
    [Documentation]    Delete Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Delete    ODLSession    ${ODLREST_CAPP}/ccaps/${CCAP_ID1}
    Should be Equal As Strings    ${resp.status_code}    200

Add Multiple.CCAPs
    [Documentation]    Add Multiple CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${Data}    OperatingSystem.Get File    ${PACKETCABLE_CONFIG_DIR}/add_multi_ccaps.json
    ${Data}    Replace String    ${Data}    {ccapId-1}    ${CCAP_ID1}
    ${Data}    Replace String    ${Data}    {ccapIp-1}    ${CCAP_IP1}
    ${Data}    Replace String    ${Data}    {ccapId-2}    ${CCAP_ID2}
    ${Data}    Replace String    ${Data}    {ccapIp-2}    ${CCAP_IP2}
    log    ${Data}
    ${resp}    RequestsLibrary.Put    ODLSession    ${ODLREST_CAPP}    data=${Data}    headers=${HEADERS}
    Should be Equal As Strings    ${resp.status_code}    200

Get ALL.CCAPs
    [Documentation]    Get ALL CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Get    ODLSession    ${ODLREST_CAPP}
    Should be Equal As Strings    ${resp.status_code}    200

Delete All.CCAPs
    [Documentation]    Delete ALL CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Delete    ODLSession    ${ODLREST_CAPP}
    Should be Equal As Strings    ${resp.status_code}    200
