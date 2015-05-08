*** Settings ***
Documentation     Test suite for Ethernet,QoS, ARP and Action drop
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}       /restconf/config/opendaylight-inventory:nodes
${FILE}           ${CURDIR}/../../../variables/xmls/f14.xml
${FLOW}           137
${TABLE}          2
@{FLOWELMENTS}    dl_dst=ff:ff:ff:ff:ff:ff    table=2    dl_src=00:00:fc:01:23:ae    CONTROLLER:60    arp    arp_op=1    arp_spa=192.168.4.1
...               arp_tpa=10.21.22.23    arp_tha=fe:dc:ba:98:76:54    arp_sha=12:34:56:78:98:ab

*** Test Cases ***
Add a flow - Output to physical port#
    [Documentation]    Push a flow through REST-API
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${FILE}
    Set Suite Variable    ${body}
    ${resp}    Putxml    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after adding flow config - Output to physical port#
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    get    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Verify flows after adding flow config on OVS
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    sleep    1
    write    dpctl dump-flows -O OpenFlow13
    ${body}    OperatingSystem.Get File    ${FILE}
    ${switchouput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Contain    ${switchouput}    ${flowElement}

Remove a flow - Output to physical port#
    [Documentation]    Remove a flow
    [Tags]    remove
    ${resp}    Delete    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow config - Output to physical port#
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    Get    session    ${REST_CON}/node/openflow:1/table/${TABLE}
    Should Not Contain    ${resp.content}    ${FLOW}

Verify flows after deleting flow config on OVS
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    Sleep    1
    write    dpctl dump-flows -O OpenFlow13
    ${body}    OperatingSystem.Get File    ${FILE}
    ${switchouput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Not Contain    ${switchouput}    ${flowElement}
