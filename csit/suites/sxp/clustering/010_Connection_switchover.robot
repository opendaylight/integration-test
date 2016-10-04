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

*** Test Cases ***
Debug Test
    [Documentation]    TODO
    Check SXP Device Owner    sxp    1    2


*** Keywords ***
Setup SXP Cluster
    [Documentation]    TODO
    ClusterManagement.ClusterManagement_Setup
    Create Controller Sessions
    ${NUM_ODL_SYSTEM}=    Convert to Integer    ${NUM_ODL_SYSTEM}
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    ${session}    RequestsLibrary.Create_Session    operational-${i+1}    http://${ODL_SYSTEM_${i+1}_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    \    BuiltIn.Set Suite variable    ${session_${i+1}}    ${session}

Clean SXP Cluster
    [Documentation]    TODO
    RequestsLibrary.Delete_All_Sessions

Check SXP Device Owner
    [Arguments]    ${device}    ${controller_index}    ${expected_owner}    ${expected_candidate_list}=${EMPTY}
    [Documentation]    TODO
    ${owner}    ${successor_list}    ClusterManagement.Verify_Owner_And_Successors_For_Device    device_name=${device}    device_type=openflow    member_index=${controller_index}    candidate_list=${expected_candidate_list}
    Should Be Equal    ${owner}    ${expected_owner}