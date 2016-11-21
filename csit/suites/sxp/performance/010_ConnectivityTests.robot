*** Settings ***
Documentation     Test suite measuring connectivity speed.
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Test Clean
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote    http://${ODL_SYSTEM_IP}:8270/ConnectionTestLibrary    WITH NAME    ConnectionTestLibrary
Library           Remote    http://${ODL_SYSTEM_IP}:8270/ExportTestLibrary    WITH NAME    ExportLibrary

*** Variables ***
${TEST_SAMPLES}    5

*** Test Cases ***
Connectivity Test
    [Documentation]    Test covering speed of connecting to remote peers without TCP-MD5
    Check Connectivity    50    40    30

Connectivity TCP-MD5 Test
    [Documentation]    Test covering speed of connecting to remote peers with TCP-MD5
    Check Connectivity    50    40    30    passwd

*** Keywords ***
Setup Topology
    [Arguments]    ${connections}    ${PASSWORD}    ${version}
    [Documentation]    Adds connections to local and remote nodes
    : FOR    ${num}    IN RANGE    0    ${connections}
    \    ${address}    Get Ip From Number    ${num}    2130771968
    \    Add Connection    ${version}    listener    ${address}    64999    password=${PASSWORD}
    \    ExportLibrary.Add Node    ${address}    ${version}    64999    ${PASSWORD}
    \    ExportLibrary.Add Connection    ${version}    speaker    ${ODL_SYSTEM_IP}    64999    ${PASSWORD}
    \    ...    ${address}

Check Connectivity
    [Arguments]    ${peers}    ${min_peers}    ${min_speed}    ${PASSWORD}=${EMPTY}    ${version}=version4
    [Documentation]    Starts SXP nodes and checks if peers are already connected, this is repeated N times
    @{ITEMS}    Create List
    : FOR    ${num}    IN RANGE    0    ${TEST_SAMPLES}
    \    Setup Topology    ${peers}    ${PASSWORD}    ${version}
    \    ExportLibrary.Start Nodes
    \    ${ELEMENT}    Wait Until Keyword Succeeds    120    1    Check Connections Connected
    \    Append To List    ${ITEMS}    ${ELEMENT}
    \    Test Clean
    ${connectivity_speed}    Get Average Of Items    ${ITEMS}
    Log    Average connectivity speed ${connectivity_speed} connection/s.
    Should Be True    ${connectivity_speed} > ${min_speed}

Check Connections Connected
    [Documentation]    Checking if Peers were connected and return connectivity speed
    ${peers_connected}    ConnectionTestLibrary.Get Connected Peers
    ${connect_time}    ConnectionTestLibrary.Get Connect Time
    Should Not Be Equal As Numbers    ${connect_time}    0
    ${connectivity_speed}    Evaluate    ${peers_connected}/${connect_time}
    [Return]    ${connectivity_speed}

Test Clean
    ConnectionTestLibrary.Clean Library
    Clean Connections
