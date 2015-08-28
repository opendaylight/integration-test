*** Settings ***
Documentation     Test suite for metadata and mask
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py

*** Variables ***
${REST_CON}       /restconf/config/opendaylight-inventory:nodes
${FILE}           ${CURDIR}/../../../variables/xmls/f21.xml
${FLOW}           144
${TABLE}          2
@{FLOWELMENTS}    metadata=0x3039    udp6    ipv6    ipv6_dst=fe80::2acf:e9ff:fe21:6431    nw_tos=32    nw_ecn=3    tp_src=25364
...               tp_dst=8080    ipv6_src=1234:5678:9abc:def0:fdc0::/76    dec_ttl

*** Test Cases ***
Add a flow - Output to physical port#
    [Documentation]    Push a flow through REST-API
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${FILE}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}    headers=${HEADERS_XML}    data=${body}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after adding flow config - Output to physical port#
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}    headers=${ACCEPT_XML}
    Should Be Equal As Strings    ${resp.status_code}    200
    compare xml    ${body}    ${resp.content}

Verify flows after adding flow config on OVS
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    sleep    1
    write    dpctl dump-flows -O OpenFlow13
    ${body}    OperatingSystem.Get File    ${FILE}
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Contain    ${switchoutput}    ${flowElement}

Remove a flow - Output to physical port#
    [Documentation]    Remove a flow
    [Tags]    remove
    ${resp}    RequestsLibrary.Delete    session    ${REST_CON}/node/openflow:1/table/${TABLE}/flow/${FLOW}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow config - Output to physical port#
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    RequestsLibrary.Get    session    ${REST_CON}/node/openflow:1/table/${TABLE}
    Should Not Contain    ${resp.content}    ${FLOW}

Verify flows after deleting flow config on OVS
    [Documentation]    Checking Flows on switch
    [Tags]    Switch
    Sleep    1
    write    dpctl dump-flows -O OpenFlow13
    ${body}    OperatingSystem.Get File    ${FILE}
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Not Contain    ${switchoutput}    ${flowElement}
