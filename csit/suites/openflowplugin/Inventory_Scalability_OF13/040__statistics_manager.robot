*** Settings ***
Documentation     Test suite for Statistics Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Library           ../../../libraries/Topologynew.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${nodeprefix}     openflow:
${key}            portStatistics
${REST_CONTEXT}    /controller/nb/v2/statistics

*** Test Cases ***
get port stats
    [Documentation]    Show port stats and validate result
    [Tags]    adsal
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})    1
    @{node_list}    Create Nodes List    ${topo_nodes}
    Wait Until Keyword Succeeds    70s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/port    ${node_list}

get flow stats
    [Documentation]    Show flow stats and validate result
    [Tags]    adsal
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})
    @{node_list}    Create Nodes List    ${topo_nodes}
    Wait Until Keyword Succeeds    70s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/flow    ${node_list}

get table stats
    [Documentation]    Show flow stats and validate result
    [Tags]    adsal
    ${topo_nodes}    Get Nodes From Tree Topo    (${TOPO_TREE_DEPTH},${TOPO_TREE_FANOUT})
    @{node_list}    Create Nodes List    ${topo_nodes}
    Wait Until Keyword Succeeds    70s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/table    ${node_list}

*** Keywords ***
Check For Correct Number Of Nodes At URI
    [Arguments]    ${uri}    ${topo_nodes}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}/${uri}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Contain X Times    ${resp.content}    "00:00:00:00:00:00:00:01"    ${TOPO_TREE_FANOUT+2}
    : FOR    ${ITEM}    IN    @{topo_nodes}
    \    ${IND}    Get From Dictionary    ${ITEM}    id
    \    Should Contain X Times    ${resp.content}    "${IND}"    ${TOPO_TREE_FANOUT+3}

Check For All Nodes At URI
    [Arguments]    ${uri}    ${topo_nodes}
    ${resp}    RequestsLibrary.Get    session    ${REST_CONTEXT}/${CONTAINER}/${uri}
    Log    ${resp.content}
    Should Be Equal As Strings    ${resp.status_code}    200
    : FOR    ${ITEM}    IN    @{topo_nodes}
    \    ${IND}    Get From Dictionary    ${ITEM}    id
    \    Should Contain    ${resp.content}    "${IND}"

Create Nodes List
    [Arguments]    ${topo_dict}
    ##init list
    @{node_list}=    Create List
    : FOR    ${ITEM}    IN    @{topo_dict}
    \    ${IND}    Get From Dictionary    ${ITEM}    id
    \    Append To List    ${node_list}    ${IND}
    [Return]    @{node_list}
