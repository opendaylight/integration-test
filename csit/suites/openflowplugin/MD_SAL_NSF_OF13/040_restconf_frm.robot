*** Settings ***
Documentation     Test suite for RESTCONF FRM
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${BODY1}          <flow xmlns="urn:opendaylight:flow:inventory"><priority>2</priority><flow-name>Foo</flow-name><match><ethernet-match><ethernet-type><type>2048</type></ethernet-type></ethernet-match><ipv4-destination>10.0.10.1/32</ipv4-destination></match><id>139</id><table_id>2</table_id><instructions><instruction><order>0</order><apply-actions><action><order>0</order><dec-nw-ttl/></action></apply-actions></instruction></instructions></flow>
${BODY2}          <flow xmlns="urn:opendaylight:flow:inventory"><priority>2</priority><flow-name>Foo</flow-name><match><ethernet-match><ethernet-type><type>2048</type></ethernet-type></ethernet-match><ipv4-destination>10.0.20.1/32</ipv4-destination></match><id>139</id><table_id>2</table_id><instructions><instruction><order>0</order><apply-actions><action><order>0</order><output-action><output-node-connector>1</output-node-connector><max-length>60</max-length></output-action></action></apply-actions></instruction></instructions></flow>

*** Test Cases ***
Add a flow - Sending IPv4 Dest Address and Eth type
    [Documentation]    Push a flow through REST-API
    ${resp}    RequestsLibrary.Put Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2/flow=139    headers=${HEADERS_XML}    data=${BODY1}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"

Verify after adding flow config - Sending IPv4 Dest Address and Eth type
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2?content=config
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.text}    139

Verify after adding flow operational - Sending IPv4 Dest Address and Eth type
    [Documentation]    Verify the flow
    ${elements}=    Create List    10.0.10.1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A1/table=2/flow=139?content=nonconfig    ${elements}

Modify a flow - Output to physical port#
    [Documentation]    Push a flow through REST-API
    ${resp}    RequestsLibrary.Put Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2/flow=139    headers=${HEADERS_XML}    data=${BODY2}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after modifying flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2?content=config
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.text}    10.0.20.1

Verify after modifying flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}=    Create List    10.0.20.1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A1/table=2/flow=139?content=nonconfig    ${elements}

Remove a flow - Output to physical port#
    [Documentation]    Remove a flow
    ${resp}    RequestsLibrary.Delete Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2/flow=139
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=2?content=config
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.text}    139

Verify after deleting flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}=    Create List    10.0.20.1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_NODES_API}/node=openflow%3A1/table=2?content=nonconfig    ${elements}
