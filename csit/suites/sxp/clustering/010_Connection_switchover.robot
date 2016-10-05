*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Library           ./Sxp.py
Resource          ./SxpLib.robot
Resource          ../../../ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    \    Isolate SXP Controller    ${controller_index}

Isolation of random follower Test
    [Documentation]    TODO
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Any Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Isolate SXP Controller
    [Arguments]    ${controller_index}
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be False    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Sync Status Should Be True    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

# robot -v ODL_STREAM:boron -v ODL_SYSTEM_IP:192.168.50.14 -v ODL_SYSTEM_1_IP:192.168.50.11 -v ODL_SYSTEM_2_IP:192.168.50.12 -v ODL_SYSTEM_3_IP:192.168.50.13 -v NUM_ODL_SYSTEM:3 -v ODL_SYSTEM_USER:vagrant -v ODL_SYSTEM_PASSWORD:vagrant -v USER_HOME:/home/vagrant ./010_Connection_switchover.robot