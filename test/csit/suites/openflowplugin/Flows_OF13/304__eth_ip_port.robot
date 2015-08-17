*** Settings ***
Documentation     Test suite for IP,Ethernet and port
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
${FILE}           ${CURDIR}/../../../variables/xmls/f5.xml
${FLOW}           128
${TABLE}          2
@{FLOWELMENTS}    dl_dst=ff:ff:ff:ff:ff:ff    table=2    dec_ttl    dl_src=00:00:00:00:23:ae    nw_src=10.1.2.0    nw_dst=20.4.0.0    in_port=0

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
    [Tags]    Switch    mpls-ttl
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
    sleep    1
    write    dpctl dump-flows -O OpenFlow13
    ${body}    OperatingSystem.Get File    ${FILE}
    ${switchoutput}    Read Until    >
    : FOR    ${flowElement}    IN    @{FLOWELMENTS}
    \    should Not Contain    ${switchoutput}    ${flowElement}
