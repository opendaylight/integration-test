*** Settings ***
Documentation     Test suite for RESTCONF FRM
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/openflowplugin/Variables.robot

*** Variables ***
${BODY2}          <flow xmlns="urn:opendaylight:flow:inventory"><priority>2</priority><flow-name>Foo</flow-name><match><ethernet-match><ethernet-type><type>2048</type></ethernet-type></ethernet-match><ipv4-destination>10.0.20.1/32</ipv4-destination></match><id>152</id><table_id>0</table_id><instructions><instruction><order>0</order><apply-actions><action><order>0</order><output-action><output-node-connector>openflow:1:1</output-node-connector></output-action></action></apply-actions></instruction></instructions></flow>

*** Test Cases ***
Add a flow - Output to physical port#
    [Documentation]    Push a flow through REST-API
    ${resp}    RequestsLibrary.Put Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=0/flow=152    headers=${HEADERS_XML}    data=${BODY2}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"

Verify after adding flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=0?content=config
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.text}    152

Verify after adding flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}=    Create List    10.0.20.1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${RFC8040_NODES_API}/node=openflow%3A1/table=0/flow=152?content=nonconfig    ${elements}

Remove a flow - Output to physical port#
    [Documentation]    Remove a flow
    ${resp}    RequestsLibrary.Delete Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=0/flow=152
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_NODES_API}/node=openflow%3A1/table=0?content=config
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.text}    152
    #    Standing bug #368 - This has been fixed

Verify after deleting flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}=    Create List    10.0.20.1
    Wait Until Keyword Succeeds    10s    2s    Check For Elements Not At URI    ${RFC8040_NODES_API}/node=openflow%3A1/table=0?content=nonconfig    ${elements}
