*** Settings ***
Documentation       Test suite for RESTCONF FRM

Library             Collections
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py
Resource            ../../../libraries/Utils.robot
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      Delete All Sessions


*** Variables ***
${BODY2}
...         <flow xmlns="urn:opendaylight:flow:inventory"><priority>2</priority><flow-name>Foo</flow-name><match><ethernet-match><ethernet-type><type>2048</type></ethernet-type></ethernet-match><ipv4-destination>10.0.20.1/32</ipv4-destination></match><id>152</id><table_id>0</table_id><instructions><instruction><order>0</order><apply-actions><action><order>0</order><output-action><output-node-connector>openflow:1:1</output-node-connector></output-action></action></apply-actions></instruction></instructions></flow>


*** Test Cases ***
Add a flow - Output to physical port#
    [Documentation]    Push a flow through REST-API
    ${resp}    RequestsLibrary.PUT On Session
    ...    session
    ...    url=${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0/flow=152
    ...    headers=${HEADERS_XML}
    ...    data=${BODY2}

Verify after adding flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.GET On Session
    ...    session
    ...    url=${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0?content=config
    ...    expected_status=200
    Should Contain    ${resp.text}    152

Verify after adding flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}    Create List    10.0.20.1
    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    Check For Elements At URI
    ...    ${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0/flow=152?content=nonconfig
    ...    ${elements}

Remove a flow - Output to physical port#
    [Documentation]    Remove a flow
    ${resp}    RequestsLibrary.DELETE On Session
    ...    session
    ...    url=${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0/flow=152
    ...    expected_status=204

Verify after deleting flow config - Output to physical port#
    [Documentation]    Verify the flow
    ${resp}    RequestsLibrary.GET On Session
    ...    session
    ...    url=${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0?content=config
    ...    expected_status=200
    Should Not Contain    ${resp.text}    152
    #    Standing bug #368 - This has been fixed

Verify after deleting flow operational - Output to physical port#
    [Documentation]    Verify the flow
    ${elements}    Create List    10.0.20.1
    Wait Until Keyword Succeeds
    ...    10s
    ...    2s
    ...    Check For Elements Not At URI
    ...    ${RFC8040_NODES_API}/node=openflow%3A1/flow-node-inventory:table=0?content=nonconfig
    ...    ${elements}
