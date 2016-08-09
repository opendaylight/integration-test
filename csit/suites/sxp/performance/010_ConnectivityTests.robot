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

*** Test Cases ***
Remote Library Test
    [Documentation]    TODO
    ${resp}    ConnectionTestLibrary.Library Echo
    Should Not Be Equal    ${resp}    ${EMPTY}
    Log To Console    \n${resp}

Connectivity Test
    [Documentation]    TODO
    Check Connectivity    600    500    50

Connectivity TCP-MD5 Test
    [Documentation]    TODO
    Check Connectivity    150    100    50    passwd

*** Keywords ***
Setup Topology
    [Arguments]    ${connections}    ${PASSWORD}    ${version}
    [Documentation]    TODO
    : FOR    ${num}    IN RANGE    0    ${connections}
    \    ${address}    Get Ip From Number    ${num}    2130771968
    \    Add Connection    ${version}    listener    ${address}    64999    ${TESTED_NODE}
    \    ...    ${PASSWORD}
    \    ConnectionTestLibrary.Add Node    ${address}    ${version}    64999    ${PASSWORD}
    \    ConnectionTestLibrary.Add Connection    ${version}    speaker    ${TESTED_NODE}    64999    ${PASSWORD}
    \    ...    ${address}

Check Connectivity
    [Arguments]    ${peers}    ${min_peers}    ${min_speed}    ${PASSWORD}=${EMPTY}    ${version}=version4
    [Documentation]    TODO
    @{ITEMS}    Create List
    Log To Console    \n\tConnectivity statistics.
    : FOR    ${num}    IN RANGE    0    5
    \    Setup Topology    ${peers}    ${PASSWORD}    ${version}
    \    ConnectionTestLibrary.Initiate Connecting    ${min_peers}
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Connections Connected
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Log To Console    \tConnected peers in measurement ${num + 1}: ${ELEMENT} peers/s.
    \    Test Clean
    ${connectivity_speed}    Get Average Of Items    ${ITEMS}
    Log To Console    \n\tAverage connectivity speed ${connectivity_speed} connection/s.\n
    Should Be True    ${connectivity_speed} > ${min_speed}

Check Connections Connected
    [Documentation]    TODO
    ${peers_connected}    ConnectionTestLibrary.Get Connected Peers
    ${total_connecting_time}    ConnectionTestLibrary.Get Connecting Time Total
    ${current_connecting_time}    ConnectionTestLibrary.Get Connecting Time Current
    Should Not Be Equal    ${total_connecting_time}    0
    Should Be Equal    ${total_connecting_time}    ${current_connecting_time}
    ${connectivity_speed}    div    ${peers_connected}    ${total_connecting_time}
    [Return]    ${connectivity_speed}

Test Clean
    [Documentation]    TODO
    ConnectionTestLibrary.Clean Library
    Clean Connections    ${TESTED_NODE}
