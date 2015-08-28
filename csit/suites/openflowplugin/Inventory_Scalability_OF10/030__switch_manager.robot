*** Settings ***
Documentation     Test suite for Switch Manager
Suite Setup       Create Session    ${ODL_CONTROLLER_SESSION}    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/SwitchManager.py
Variables         ../../../variables/Variables.py
Library           ../../../libraries/Topologynew.py

*** Variables ***
${REST_CONTEXT}    /controller/nb/v2/switchmanager

*** Test Cases ***
List all nodes
    [Documentation]    List all nodes and their properties in the network.
    [Tags]    adsal
    Log    ${TOPO_TREE_LEVEL}
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/nodes
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    ${jsondata}=    To JSON    ${resp.content}
    ${nodes}    Extract All Nodes    ${jsondata}
    List Should Contain Sublist    ${nodes}    ${topo_nodes}

Check root node connectors
    [Documentation]    List node connectors and verify all connectors are there
    [Tags]    adsal
    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/node/OF/00:00:00:00:00:00:00:01
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200    Response    status code error
    ${TOPO_TREE_FANOUT}    Convert To Integer    ${TOPO_TREE_FANOUT}
    Check conn loop    ${TOPO_TREE_FANOUT}    1    ${resp.content}

Check node i connectors
    [Documentation]    List node connectors and verify all connectors are there
    [Tags]    adsal
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})    1
    Wait Until Keyword Succeeds    30s    2s    Check Every Nodes Connectors    ${topo_nodes}

*** Keywords ***
Check Every Nodes Connectors
    [Arguments]    ${topo_nodes}
    : FOR    ${ITEM}    IN    @{topo_nodes}
    \    ${IND}    Get From Dictionary    ${ITEM}    id
    \    ${resp}    RequestsLibrary.Get    ${ODL_CONTROLLER_SESSION}    ${REST_CONTEXT}/default/node/OF/${IND}
    \    Log    ${resp.content}
    \    Should Be Equal As Strings    ${resp.status_code}    200
    \    Check conn loop    ${TOPO_TREE_FANOUT+1}    ${IND}    ${resp.content}

Check conn loop
    [Arguments]    ${arg}    ${outerind}    ${content}
    : FOR    ${var}    IN RANGE    0    ${arg+1}
    \    Should Contain    ${content}    "id":"${var}"
