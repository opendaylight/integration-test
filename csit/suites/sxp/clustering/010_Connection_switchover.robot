*** Settings ***
Documentation     Test suite TODO
Suite Setup       Setup SXP Cluster
Suite Teardown    Clean SXP Cluster
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        3

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    TODO
    #pass execution    SKIP
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
    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be False    ${ODL_SYSTEM_${controller_index}_IP}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Rejoin_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    120    1    Controller Sync Status Should Be True    ${ODL_SYSTEM_${controller_index}_IP}
    Wait Until Keyword Succeeds    120    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}