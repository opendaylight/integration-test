*** Settings ***
Documentation     Test suite for Topology Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           ../../../libraries/RequestsLibrary.py
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topologynew.py
Variables         ../../../variables/Variables.py

*** Variables ***
${nodeprefix}     openflow:
${REST_CONTEXT}    /controller/nb/v2/topology

*** Test Cases ***
Get Topology
    [Documentation]    Get Topology and validate the result.
    [Tags]    adsal
    ${TOPO_TREE_DEPTH}    Convert To Integer    ${TOPO_TREE_DEPTH}
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    ${leaflist}    Get Ids Of Leaf Nodes    ${TOPO_TREE_FANOUT}    ${TOPO_TREE_DEPTH}
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})    1
    Wait Until Keyword Succeeds    30s    2s    Check Link Counts For Each Node    ${topo_nodes}    ${leaflist}

*** Keywords ***
Check Link Counts For Each Node
    [Arguments]    ${topo_nodes}    ${leaflist}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain X Times    ${resp.content}    "00:00:00:00:00:00:00:01"    ${TOPO_TREE_FANOUT*2}
    : FOR    ${ITEM}    IN    @{topo_nodes}
    \    ${IND}    Get From Dictionary    ${ITEM}    id
    \    ${linkcnt}    Num Of Links For Node    ${IND}    ${leaflist}    ${TOPO_TREE_FANOUT}
    \    Should Contain X Times    ${resp.content}    "${IND}"    ${linkcnt*2}
