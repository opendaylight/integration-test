*** Settings ***
Documentation     BMP functional HA testing with one BMP mock.
...
...               Copyright (c) 2017 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses BMP mock. It is configured to have 3 peers (all 3 nodes of odl).
...               BMP implemented with singleton accepts only one incomming conection. BMP mock
...               logs will show that one peer will be connected and two will fail.
...               After stopping karaf which owned connection new owner should be elected and
...               this new owner should accept incomming BMP connection.
...               TODO: Add similar keywords from all bgpclustering-ha tests into same libraries
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           Collections
Library           OperatingSystem
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/NexusKeywords.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${BMP_LOG_FILE}    bmpmock.stop.log
${CONFIG_SESSION}    session

*** Test Cases ***
Get_Example_Bm_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection.
    ${bm_owner}    ${bm_candidates}=    Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Get_Owner_And_Successors_For_Device    bmp-monitors
    ...    Bgpcep    1
    BuiltIn.Set Suite variable    ${bm_owner}
    BuiltIn.Log    ${bm_owner}
    BuiltIn.Log    ${ODL_SYSTEM_${bm_owner}_IP}
    BuiltIn.Set Suite variable    ${bm_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${bm_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Log    ${living_session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${bm_owner}

Verify_Data_Reported_1
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    BgpOperations.Bmp_Monitor_Postcondition    ${living_session}

Stop_Current_Owner_Member
    [Documentation]    Stop cluster node which is connected with bmp mock.
    ClusterManagement.Stop_Single_Member    ${bm_owner}
    BuiltIn.Set Suite variable    ${old_bm_owner}    ${bm_owner}
    BuiltIn.Set Suite variable    ${old_bm_candidates}    ${bm_candidates}
    ${idx}=    Collections.Get From List    ${old_bm_candidates}    0
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Verify_New_Bm_Owner
    [Documentation]    Verifies if new owner of bmp-monitor is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Bm_Owner_Elected    ${old_bm_owner}    ${living_node}

Verify_Data_Reported_2
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    BgpOperations.Bmp_Monitor_Postcondition    ${living_session}

Start_Old_Owner_Member
    [Documentation]    Restart old owner node with bin/start
    ClusterManagement.Start_Single_Member    ${old_bm_owner}

Verify_New_Candidate
    [Documentation]    Verifies started node become candidate for bmp-monitor
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Bm_Candidate_Present    ${old_bm_owner}    ${living_node}

Verify_Data_Reported_3
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    BgpOperations.Bmp_Monitor_Postcondition    ${living_session}

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to bmp-mock to stop it
    BGPcliKeywords.Stop_Console_Tool_And_Wait_Until_Prompt

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    bgp-bmp-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    BgpOperations.Bmp_Monitor_Precondition    ${CONFIG_SESSION}
    Start_Bmp_Mock

Teardown_Everything
    [Documentation]    Suite cleanup
    BGPcliKeywords.Store_File_To_Workspace    ${BMP_LOG_FILE}    ${BMP_LOG_FILE}
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Start_Bmp_Mock
    [Documentation]    Starts bmp mock
    ${command}=    BuiltIn.Set_Variable    -jar ${filename} --local_address ${TOOLS_SYSTEM_IP} --remote_address ${ODL_SYSTEM_1_IP}:12345,${ODL_SYSTEM_2_IP}:12345,${ODL_SYSTEM_3_IP}:12345 --routers_count 1 --peers_count 1 --log_level INFO 2>&1 | tee ${BMP_LOG_FILE}
    BGPcliKeywords.Start_Java_Tool_And_Verify_Connection    ${command}    successfully established.

Verify_New_Bm_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    bmp-monitors    Bgpcep    ${node_to_ask}
    BuiltIn.Log    ${owner}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

Verify_New_Bm_Candidate_Present
    [Arguments]    ${candidate}    ${node_to_ask}
    [Documentation]    Verifies candidate's presence.
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    bmp-monitors    Bgpcep    ${node_to_ask}
    BuiltIn.Log    ${owner}
    BuiltIn.Should_Contain    ${candidates}    ${candidate}
