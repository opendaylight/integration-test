*** Settings ***
Documentation     Checking packetcable:ccap resconf is working
Suite Setup       Create Session And Init Variables
Suite Teardown    Delete All Sessions
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/PacketcableVersion.robot

*** Variables ***
${CCAP_ID1}       93b7d8de-15fb-11e5-b60b-1697f925ec7b
${CCAP_ID2}       dc13b3fc-15fe-11e5-b60b-1697f925ec7b
${CCAP_IP1}       192.168.1.101
${CCAP_IP2}       192.168.1.102

*** Test Cases ***
Add CCAP
    [Documentation]    Add Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    ${Data}    OperatingSystem.Get File    ${PACKETCABLE_RESOURCE_DIR}/add_ccap.json
    ${Data}    Replace String    ${Data}    {ccapId-1}    ${CCAP_ID1}
    ${Data}    Replace String    ${Data}    {ccapIp-1}    ${CCAP_IP1}
    log    ${Data}
    log    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}
    ${resp}    RequestsLibrary.Put Request    ODLSession    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}    data=${Data}
    Should be Equal As Strings    ${resp.status_code}    200

Get CCAP
    [Documentation]    Get Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    log    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}
    ${resp}    RequestsLibrary.Get Request    ODLSession    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}
    Should be Equal As Strings    ${resp.status_code}    200

Delete CAPP
    [Documentation]    Delete Single CCAP
    [Tags]    PacketCable PCMM Reset Call
    log    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}
    ${resp}    RequestsLibrary.Delete Request    ODLSession    ${ODLREST_CCAPS}/${CCAP_TOKEN}/${CCAP_ID1}
    Should be Equal As Strings    ${resp.status_code}    200

Add Multiple.CCAPs
    [Documentation]    Add Multiple CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${Data}    OperatingSystem.Get File    ${PACKETCABLE_RESOURCE_DIR}/add_multi_ccaps.json
    ${Data}    Replace String    ${Data}    {ccapId-1}    ${CCAP_ID1}
    ${Data}    Replace String    ${Data}    {ccapIp-1}    ${CCAP_IP1}
    ${Data}    Replace String    ${Data}    {ccapId-2}    ${CCAP_ID2}
    ${Data}    Replace String    ${Data}    {ccapIp-2}    ${CCAP_IP2}
    log    ${Data}
    ${resp}    RequestsLibrary.Put Request    ODLSession    ${ODLREST_CCAPS}    data=${Data}
    Should be Equal As Strings    ${resp.status_code}    200

Get ALL.CCAPs
    [Documentation]    Get ALL CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Get Request    ODLSession    ${ODLREST_CCAPS}
    Should be Equal As Strings    ${resp.status_code}    200

Delete All.CCAPs
    [Documentation]    Delete ALL CCAPs
    [Tags]    PacketCable PCMM Reset Call
    ${resp}    RequestsLibrary.Delete Request    ODLSession    ${ODLREST_CCAPS}
    Should be Equal As Strings    ${resp.status_code}    200
