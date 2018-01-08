*** Settings ***
Documentation     PCEP functional HA testing with one pcep peer.
...
...               Copyright (c) 2017 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses PCC mock. It is configured to have 3 peers (all 3 nodes of odl).
...               PCEP implemented with singleton accepts only one incomming conection. PCC mock
...               logs will show that one peer will be connected and two will fail.
...               After stopping karaf which owned connection new owner should be elected and
...               this new owner should accept incomming PCC connection.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           Collections
Library           OperatingSystem
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/NexusKeywords.robot

*** Variables ***
${HOLDTIME}       180
${DIR_WITH_TEMPLATES}    ${CURDIR}/../../../variables/bgpclustering/
${TEST_LOG_LEVEL}    TRACE
@{TEST_LOG_COMPONENTS}    org.opendaylight.bgpcep.pcep    org.opendaylight.protocol.pcep

*** Test Cases ***
Get_Example_Pcep_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${pcep_owner}    ${pcep_candidates}=    Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Get_Owner_And_Successors_For_device
    ...    pcep-topology    Bgpcep    1
    BuiltIn.Set Suite variable    ${pcep_owner}
    BuiltIn.Log    ${pcep_owner}
    BuiltIn.Set Suite variable    ${pcep_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${pcep_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Log    ${living_session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${pcep_owner}

Verify_Data_Reported_1
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    ...    Expects pcep-topology not be empty/filled path-computation.
    BuiltIn.Sleep    60s
    Verify_Data_Reported

#Stop_Current_Owner_Member
#    [Documentation]    Stopping cluster node which is connected with bmp mock.
#    ClusterManagement.Stop_Single_Member    ${pcep_owner}
#    BuiltIn.Set Suite variable    ${old_pcep_owner}    ${pcep_owner}
#    BuiltIn.Set Suite variable    ${old_pcep_candidates}    ${pcep_candidates}
#    ${idx}=    Collections.Get From List    ${old_pcep_candidates}    0
#    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
#    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
#    BuiltIn.Set_Suite_Variable    ${living_node}   ${idx}
#
#Verify_New_Pcep_Owner
#    [Documentation]    Verifies if new owner of bmp-monitor is elected.
#    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Pcep_Owner_Elected    ${old_pcep_owner}    ${living_node}
#
#Verify_Data_Reported_2
#    [Documentation]    Verifies if pcep-topology reports expected data
#    ...    Expects pcep-topology not be empty/filled path-computation.
#    Verify_Data_Reported
#
#Start_Stopped_Member
#    [Documentation]    Starting stopped node
#    ClusterManagement.Start_Single_Member    ${old_pcep_owner}
#
#Verify_New_Candidate
#    [Documentation]    Verifies started node become candidate for pcep_topology
#    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Pcep_Candidate_Present    ${old_pcep_owner}    ${living_node}
#
#Verify_Data_Reported_3
#    [Documentation]    Verifies if example-bmp-monitor reported expected data
#    ...    Expects pcep-topology not be empty/filled path-computation.
#    Verify_Data_Reported

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to pcc-mock to stop it.
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    #debugging purposes
    SetupUtils.Setup_Logging_For_Debug_Purposes_On_List_Or_All    ${TEST_LOG_LEVEL}    ${TEST_LOG_COMPONENTS}
    ClusterManagement.Cluster_Setup_For_Artifact_Deployment_And_Usage
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    #Setting Pcc Name and its code for mapping for templates
    BuiltIn.Set_Suite_Variable    ${pcc_name}    pcc_${TOOLS_SYSTEM_IP}_tunnel_1
    ${code}=    Evaluate    binascii.b2a_base64('${pcc_name}')[:-1]    modules=binascii
    BuiltIn.Set_Suite_Variable    ${pcc_name_code}    ${code}
    Start_Pcc_Mock

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHLibrary.Get_File    pccmock.log
    ${cnt}=    OperatingSystem.Get_File    pccmock.log
    Log    ${cnt}
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Start_Pcc_Mock
    [Documentation]    Starts pcc mock
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --reconnect 5 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_1_IP}:4189,${ODL_SYSTEM_2_IP}:4189,${ODL_SYSTEM_3_IP}:4189 --log-level TRACE 2>&1 | tee pccmock.log
    BuiltIn.Log    ${command}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${command}
    ${output}=    SSHLibrary.Read_Until    started
    BuiltIn.Log    ${output}

Verify_Data_Reported
    [Documentation]    Verifies if the tool reported expected data
    #TEMP
    #${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    pcep:node-state -topology-id pcep-topology -node-id pcc://${TOOLS_SYSTEM_IP}
    #BuiltIn.Log    ${output}
    #/TEMP
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    CODE=${pcc_name_code}    NAME=${pcc_name}    IP_ODL=${ODL_SYSTEM_${pcep_owner}_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    TemplatedRequests.Get_As_Json_Templated    ${DIR_WITH_TEMPLATES}${/}pcep_on_state    ${mapping}    ${living_session}
    ...    verify=True

Verify_New_Pcep_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    pcep-topology    Bgpcep    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}
    BuiltIn.Set_Suite_Variable    ${pcep_owner}    ${owner}

Verify_New_Pcep_Candidate_Present
    [Arguments]    ${candidate}    ${node_to_ask}
    [Documentation]    Verifies candidate's presence.
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    pcep-topology    Bgpcep    ${node_to_ask}
    BuiltIn.Should_Contain    ${candidates}    ${candidate}
    BuiltIn.Set_Suite_Variable    ${pcep_owner}    ${owner}
