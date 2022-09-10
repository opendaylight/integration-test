*** Settings ***
Documentation       Test suite for RESTCONF topology

Library             Collections
Library             XML
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py
Resource            ../../../variables/openflowplugin/Variables.robot

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      Delete All Sessions


*** Test Cases ***
Get Nodes Count
    [Documentation]    Checks the number of switches
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Wait Until Keyword Succeeds
    ...    60s
    ...    2s
    ...    Verify Element Count
    ...    ${RFC8040_OPERATIONAL_TOPO_FLOW1_API}
    ...    node
    ...    ${numnodes}

Get Links Count
    [Documentation]    Checks the number of links
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    ${numlinks}    Evaluate    (${numnodes}-1)*2
    Wait Until Keyword Succeeds
    ...    60s
    ...    2s
    ...    Verify Element Count
    ...    ${RFC8040_OPERATIONAL_TOPO_FLOW1_API}
    ...    link
    ...    ${numlinks}


*** Keywords ***
Verify Element Count
    [Arguments]    ${URI}    ${xpath_location}    ${expected_count}
    ${resp}    RequestsLibrary.Get Request    session    ${RFC8040_OPERATIONAL_TOPO_FLOW1_API}    headers=${ACCEPT_XML}
    Log    ${resp.text}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${count}    Get Element Count    ${resp.text}    xpath=${xpath_location}
    Should Be Equal As Numbers    ${count}    ${expected_count}
