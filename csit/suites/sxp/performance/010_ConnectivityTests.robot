*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://127.0.0.1:8270/ConnectionTestLibrary    WITH NAME    ConnectionTestLibrary

*** Variables ***
${TESTED_NODE}    127.0.0.1
${PEERS_TO_TEST}     2000

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ConnectionTestLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Connectivity Test
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tConnectivity statistics.
    : FOR    ${num}    IN RANGE    0    5
    \    Setup Topology    ${PEERS_TO_TEST}
    \    ConnectionTestLibrary.Initiate Connecting    ${PEERS_TO_TEST}
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Connections Connected
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tConnected peers in measurement ${num + 1}: ${ELEMENT} peers/s.
    \    Test Clean
    ${connectivity_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage connectivity speed ${connectivity_speed} bindings/s.\n
    Should Be True    ${connectivity_speed} > 50

*** Keywords ***
Setup Topology
    [Arguments]    ${connections}    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]    TODO
    : FOR    ${num}    IN RANGE    0    ${connections}
    \    ${address}    Get Ip From Number    ${num}    2130771968
    \    Add Connection    ${version}    listener    ${address}    64999    ${TESTED_NODE}    ${PASSWORD}
    \    ConnectionTestLibrary.Add Node    ${address}    ${version}    64999    ${PASSWORD}
    \    ConnectionTestLibrary.Add Connection        ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}    ${address}

Check Connections Connected
    [Arguments]
    [Documentation]    TODO
    ${peers_connected}    ConnectionTestLibrary.Get Connected Peers
    ${total_connecting_time}    ConnectionTestLibrary.Get Connecting Time Total
    ${current_connecting_time}    ConnectionTestLibrary.Get Connecting Time Current
    #Log To Console    \tConnected Peers: ${peers_connected} after ${current_connecting_time} seconds.
    Should Not Be Equal    ${total_connecting_time}    0
    Should Be Equal    ${total_connecting_time}    ${current_connecting_time}
    ${connectivity_speed}    div    ${peers_connected}    ${total_connecting_time}
    [return]    ${connectivity_speed}

Test Clean
    [Arguments]
    [Documentation]    TODO
    ConnectionTestLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}