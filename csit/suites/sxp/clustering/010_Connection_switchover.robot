*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Variables         ${CURDIR}/../../../variables/Variables.py


*** Variables ***
${SXP_VERSION}    version4

*** Test Cases ***
Debug Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Add Connection    ${SXP_VERSION}    listener    ${ODL_SYSTEM_${i+1}_IP}    64999
    \    Add Connection    ${SXP_VERSION}    speaker    ${ODL_SYSTEM_IP}    64999    1.1.1.1    session=${session_${i+1}}
    Wait Until Keyword Succeeds    120    1    Check Cluster is Connected    ${SXP_VERSION}    listener

*** Keywords ***
Setup SXP Cluster
    [Documentation]    TODO
    ClusterManagement.ClusterManagement_Setup
    ${NUM_ODL_SYSTEM}=    Convert to Integer    ${NUM_ODL_SYSTEM}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${session}    RequestsLibrary.Create_Session    operational-${i+1}    http://${ODL_SYSTEM_${i+1}_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    \    BuiltIn.Set Suite variable    ${session_${i+1}}    ${session}
    Add Node    2.2.2.2    ip=0.0.0.0
    Wait Until Keyword Succeeds    20    1    Check Node Started    0.0.0.0
    Add Node    1.1.1.1    ip=0.0.0.0    session=${session_1}

Clean SXP Cluster
    [Documentation]    TODO
    Delete Node    2.2.2.2
    Delete Node    1.1.1.1    session=${session_1}
    Clean SXP Environment
    RequestsLibrary.Delete_All_Sessions

Check Cluster is Connected
    [Arguments]     ${version}    ${mode}    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${is_connected}    ${False}
    ${resp}    Get Connections    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    ${mode}    ${ODL_SYSTEM_${i}_IP}    ${port}    on
    \    ${is_connected}    Run Keyword If    ${follower}    Set Variable    ${ODL_SYSTEM_${i}_IP}
    Should Be True    ${is_connected}

Get Connected Follower
    [Arguments]     ${version}    ${mode}    ${port}=64999    ${session}=session
    [Documentation]    TODO
    ${service_follower}    ${EMPTY}
    ${resp}    Get Connections    session=${session}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${follower}    Find Connection    ${resp}    ${version}    ${mode}    ${ODL_SYSTEM_${i}_IP}    ${port}    on
    \    ${service_follower}    Run Keyword If    ${follower}    Set Variable    ${ODL_SYSTEM_${i}_IP}
    [return]    ${service_follower}

