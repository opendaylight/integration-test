*** Settings ***
Documentation     Test suite for OpenFlow meter
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../variables/openflowplugin/Variables.robot
Resource          ../../../libraries/Utils.robot

*** Variables ***
${REST_CONTEXT}    ${RFC8040_NODES_API}/node=openflow%3A1
${METER}          ${CURDIR}/../../../variables/xmls/m4.xml
${FLOW}           ${CURDIR}/../../../variables/xmls/f51.xml
${METER_NAME}     Foo
${FLOW_NAME}      forward

*** Test Cases ***
Get list of nodes
    [Documentation]    Get the inventory to make sure openflow:1 comes up
    ${node_list}=    Create List    openflow:1
    Wait Until Keyword Succeeds    3s    1s    Check For Elements At URI    ${REST_CONTEXT}?${RFC8040_OPERATIONAL_CONTENT}    ${node_list}

Add a meter
    [Documentation]    Add a meter using RESTCONF
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${METER}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CONTEXT}/meter=1    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"

Verify after adding meter config
    [Documentation]    Get the meter stat in config
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/meter=1?${RFC8040_CONFIG_CONTENT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${METER_NAME}

Verify after adding meter operational
    [Documentation]    Get the meter stat in operational
    ${elements}=    Create List    meter-statistics    meter-kbps    flow-count    packet-in-count    byte-in-count
    ...    meter-band-stats    meter-band-headers
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${REST_CONTEXT}/meter=1?${RFC8040_OPERATIONAL_CONTENT}    ${elements}

Add a flow that includes a meter
    [Documentation]    Push a flow through RESTCONF
    [Tags]    Push
    ${body}    OperatingSystem.Get File    ${FLOW}
    Set Suite Variable    ${body}
    ${resp}    RequestsLibrary.Put Request    session    ${REST_CONTEXT}/flow-node-inventory:table=0/flow=2    headers=${HEADERS_XML}    data=${body}
    Log    ${resp.content}
    BuiltIn.Should_Match    "${resp.status_code}"    "20?"

Verify after adding flow config
    [Documentation]    Verify the flow
    [Tags]    Get
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/flow-node-inventory:table=0/flow=2?${RFC8040_CONFIG_CONTENT}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain    ${resp.content}    ${FLOW_NAME}

Verify after adding flow operational
    [Documentation]    Verify the flow
    ${elements}=    Create List    meter-id    flow
    Wait Until Keyword Succeeds    6s    2s    Check For Elements At URI    ${REST_CONTEXT}/flow-node-inventory:table=0/flow=2?${RFC8040_OPERATIONAL_CONTENT}    ${elements}

Remove the flow
    [Documentation]    Remove the flow
    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CONTEXT}/flow-node-inventory:table=0/flow=2
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting flow
    [Documentation]    Verify the flow removal
    [Tags]    Get
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/flow-node-inventory:table=0/flow=2?${RFC8040_CONFIG_CONTENT}
    Should Not Contain    ${resp.content}    ${FLOW_NAME}

Delete the meter
    [Documentation]    Remove the meter
    [Tags]    Delete
    ${resp}    RequestsLibrary.Delete Request    session    ${REST_CONTEXT}/meter=1
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200

Verify after deleting meter
    [Documentation]    Verify the flow removal
    [Tags]    Get
    ${resp}    RequestsLibrary.Get Request    session    ${REST_CONTEXT}/meter=1?${RFC8040_CONFIG_CONTENT}
    Should Not Contain    ${resp.content}    ${METER_NAME}
