*** Settings ***
Documentation     Test suite for capwap discover functionality
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt
Library           Collections
Library           ../../../libraries/CapwapLibrary.py

*** Variables ***
${DISC_WTP_REST}    /restconf/operational/capwap-impl:capwap-ac-root/

*** Test Cases ***
Get Discovered WTPs
    [Documentation]    Get the WTP Discoverd
    send discover    ${CONTROLLER}
    Wait Until Keyword Succeeds    10s    5s    Run Test Get Discovered WTP

Get Specific WTP
    [Documentation]    Get the details of specific WTP.
    send discover    ${CONTROLLER}
    Wait Until Keyword Succeeds    10s    5s    Run Test Get Specifc WTP

*** Keywords ***
Run Test Get Discovered WTP
    ${resp}    RequestsLibrary.Get    session    ${DISC_WTP_REST}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    TO JSON    ${resp.content}
    ${ac_Root}    Get From Dictionary    ${result}    capwap-ac-root
    @{wtp_discovered}    Get From Dictionary    ${ac_Root}    discovered-wtps
    ${expected_ip_addr}    get simulated wtpip    ${CONTROLLER}
    ${wtp_ip_list}    Create List    ''
    : FOR    ${wtp}    IN    @{wtp_discovered}
    \    ${wtp_ip}    Get From Dictionary    ${wtp}    ipv4-addr
    \    Append to List    ${wtp_ip_list}    ${wtp_ip}
    Log    ${wtp_ip_list}
    List Should Contain Value    ${wtp_ip_list}    ${expected_ip_addr}

Run Test Get Specifc WTP
    ${expected_ip_addr}    get simulated wtpip    ${CONTROLLER}
    ${DISC_SPECIFIC_WTP}    catenate    SEPARATOR=    ${DISC_WTP_REST}    discovered-wtps\/    ${expected_ip_addr}    \/
    Log    ${DISC_SPECIFIC_WTP}
    ${resp}    RequestsLibrary.Get    session    ${DISC_SPECIFIC_WTP}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    TO JSON    ${resp.content}
    @{wtp_discovered}    Get From Dictionary    ${result}    discovered-wtps
    ${wtp_ip_list}    Create List    ''
    : FOR    ${wtp}    IN    @{wtp_discovered}
    \    ${wtp_ip}    Get From Dictionary    ${wtp}    ipv4-addr
    \    Append to List    ${wtp_ip_list}    ${wtp_ip}
    Log    ${wtp_ip_list}
    List Should Contain Value    ${wtp_ip_list}    ${expected_ip_addr}
