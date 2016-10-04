*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SetupUtils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${SXP_VERSION}    version4
#robot -v ODL_STREAM:boron -v ODL_SYSTEM_IP:10.0.2.15 -v ODL_SYSTEM_1_IP:192.168.50.11 -v ODL_SYSTEM_2_IP:192.168.50.12 -v ODL_SYSTEM_3_IP:192.168.50.13 -v NUM_ODL_SYSTEM:3 -v ODL_SYSTEM_USER:vagrant -v ODL_SYSTEM_PASSWORD:vagrant -v ODL_SYSTEM_PROMPT:$ ./010_Connection_switchover.robot

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    2
    \    ${active_follower}    Get Connected Follower    ${SXP_VERSION}    listener    2.2.2.2
    \    Isolate_Member_From_List_Or_All    ${active_follower}
    \    log to console    \nIsolated ${active_follower}
    \    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be False    ${ODL_SYSTEM_${active_follower}_IP}
    \    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${SXP_VERSION}    listener
    \    ...    2.2.2.2
    \    Rejoin_Member_From_List_Or_All
    \    log to console    \nRejoined all
    \    Flush_Iptables_From_List_Or_All
    \    log to console    \nFlush IPtables all
    \    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be True    ${ODL_SYSTEM_${active_follower}_IP}
    \    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${SXP_VERSION}    listener
    \    ...    2.2.2.2

Isolation of SXP noservice follower Test
    [Documentation]    TODO
    pass execution    SKIP
    : FOR    ${i}    IN RANGE    0    2
    \    ${active_follower}    Get Disconnected Follower    ${SXP_VERSION}    listener    2.2.2.2

Isolation of random follower Test
    [Documentation]    TODO
    pass execution    SKIP
    : FOR    ${i}    IN RANGE    0    2
    \    ${active_follower}    Get Any Follower

*** Keywords ***
Setup SXP Cluster
    [Documentation]    TODO
    ClusterManagement.ClusterManagement_Setup
    Create Controller Sessions
    Setup SXP Session
    Add Node    2.2.2.2    ip=0.0.0.0
    Wait Until Keyword Succeeds    20    1    Check Node Started    2.2.2.2
    ${follower}    Get Any Follower
    Add Node    1.1.1.1    ip=0.0.0.0    session=controller${follower}
    Add Connection    ${SXP_VERSION}    speaker    192.168.50.1    64999    1.1.1.1    session=controller${follower}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    ${SXP_VERSION}    listener    ${ODL_SYSTEM_${i+1}_IP}    64999    2.2.2.2
    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${SXP_VERSION}    listener    2.2.2.2

Clean SXP Cluster
    [Documentation]    TODO
    Delete Node    2.2.2.2
    ${active_follower}    Get Connected Follower    ${SXP_VERSION}    listener    2.2.2.2
    Delete Node    1.1.1.1    session=controller${active_follower}
    Rejoin_Member_From_List_Or_All
    Flush_Iptables_From_List_Or_All
    RequestsLibrary.Delete_All_Sessions

Check Cluster is Connected
    [Arguments]    ${version}    ${mode}    ${node}    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${is_connected}    Set variable    ${False}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    ${mode}    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${is_connected}    Run Keyword If    ${follower}    Set Variable    ${True}
    \    ...    ELSE    Set Variable    ${is_connected}
    Should Be True    ${is_connected}

Get Connected Follower
    [Arguments]    ${version}    ${mode}    ${node}    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${service_follower}    Set variable    ${EMPTY}
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    ${mode}    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    ${service_follower}    Run Keyword If    ${follower}    Set Variable    ${i+1}
    \    ...    ELSE    Set Variable    ${service_follower}
    [Return]    ${service_follower}

Get Disconnected Follower
    [Arguments]    ${version}    ${mode}    ${node}    ${port}=64999    ${session}=session
    [Documentation]    TODO
    @{disconnected_followers}    Create List
    ${resp}    Get Connections    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    ${mode}    ${ODL_SYSTEM_${i+1}_IP}
    \    ...    ${port}    on
    \    Run Keyword If    not ${follower}    Append To List    ${disconnected_followers}    ${i+1}
    ${disconected_follower}    Evaluate    __import__('random').choice(@{disconnected_followers})
    [Return]    ${disconected_follower}

Get Any Follower
    [Documentation]    TODO
    ${disconected_follower}    Evaluate    __import__('random').choice( range(1, ${NUM_ODL_SYSTEM}))
    [Return]    ${disconected_follower}
