*** Settings ***
Documentation       Test suite for RESTCONF topology

Library             Collections
Library             XML
Library             RequestsLibrary
Library             ../../../libraries/Common.py
Variables           ../../../variables/Variables.py

Suite Setup         Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown      Delete All Sessions


*** Variables ***
${REST_CONTEXT}     /rests/data/network-topology:network-topology/topology=flow%3A1?content=nonconfig


*** Test Cases ***
Get Nodes Count
    [Documentation]    Checks the number of switches
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    Wait Until Keyword Succeeds    60s    2s    Verify Element Count    ${REST_CONTEXT}    node    ${numnodes}

Get Links Count
    [Documentation]    Checks the number of links
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${numnodes}    Num Of Nodes    ${TOPO_TREE_DEPTH}    ${TOPO_TREE_FANOUT}
    ${numlinks}    Evaluate    (${numnodes}-1)*2
    Wait Until Keyword Succeeds    60s    2s    Verify Element Count    ${REST_CONTEXT}    link    ${numlinks}


*** Keywords ***
Verify Element Count
    [Arguments]    ${URI}    ${xpath_location}    ${expected_count}
    ${resp}    RequestsLibrary.GET On Session
    ...    session
    ...    url=${REST_CONTEXT}
    ...    headers=${ACCEPT_XML}
    ...    expected_status=200
    Log    ${resp.content}
    ${count}    Get Element Count    ${resp.content}    xpath=${xpath_location}
    Should Be Equal As Numbers    ${count}    ${expected_count}
