*** Settings ***
Documentation     Test suite for Statistics Manager
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           Collections
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot

*** Variables ***
${node1}          "00:00:00:00:00:00:00:01"
${node2}          "00:00:00:00:00:00:00:02"
${node3}          "00:00:00:00:00:00:00:03"
@{macaddr_list}    ${node1}    ${node2}    ${node3}
@{node_list}      openflow:1    openflow:2    openflow:3
${key}            portStatistics
${REST_CONTEXT}    /controller/nb/v2/statistics

*** Test Cases ***

get port stats
    [Documentation]    Show port stats and validate result
    [Tags]    adsal 
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/port    ${macaddr_list}
    Wait Until Keyword Succeeds    60s    2s    Check That Port Count Is Ok    ${node1}    4
    Wait Until Keyword Succeeds    60s    1s    Check That Port Count Is Ok    ${node2}    5
    Wait Until Keyword Succeeds    60s    1s    Check That Port Count Is Ok    ${node3}    5

get flow stats
    [Documentation]    Show flow stats and validate result
    [Tags]    adsal 
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/flow    ${macaddr_list}

get table stats
    [Documentation]    Show flow stats and validate result
    [Tags]    adsal 
    Wait Until Keyword Succeeds    10s    2s    Check For Elements At URI    ${REST_CONTEXT}/${CONTAINER}/table    ${macaddr_list}
