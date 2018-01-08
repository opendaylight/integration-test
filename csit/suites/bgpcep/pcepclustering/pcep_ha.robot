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
...               After killing karaf which owned connection new owner should be elected and
...               this new owner should accept incomming PCC connection.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Library           Collections
Library           OperatingSystem
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/RemoteBash.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/NexusKeywords.robot

*** Variables ***
${PCEP_VAR_FOLDER}    ${CURDIR}/../../../variables/pcepuser
${HOLDTIME}       180
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/empty_structure
${BMP_LOG_FILE}    bmpmock.log
${PATH_SESSION_URI}    node/pcc:%2F%2F${TOOLS_SYSTEM_IP}/path-computation-client
${PCEP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/pcepuser/

*** Test Cases ***
Get_Example_Pcep_Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${bm_owner}    ${bm_candidates}=    Wait_Until_Keyword_Succeeds    5x    2s    ClusterManagement.Get_Owner_And_Successors_For_device    pcep-topology
    ...    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${bm_owner}    ${bm_owner}
    BuiltIn.Log    ${bm_owner}
    BuiltIn.Set Suite variable    ${bm_candidates}    ${bm_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${bm_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Log    ${living_session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${bm_owner}

Start_Pcc_Mock
    [Documentation]    Starts pcc mock
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --reconnect 1 --local-address ${TOOLS_SYSTEM_IP} --remote-address ${ODL_SYSTEM_1_IP}:4189,${ODL_SYSTEM_2_IP}:4189,${ODL_SYSTEM_3_IP}:4189 --log-level TRACE 2>&1 | tee pccmock.log
    BuiltIn.Log    ${command}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${command}
    ${until_phrase}=    Set Variable    successfully established.
    ${status}    ${output}=    Run Keyword And Ignore Error    SSHLibrary.Read_Until    ${until_phrase}
    BuiltIn.Log    ${output}

Verify_Data_Reported_1
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    Verify_Data_Reported

Isolate_Current_Owner_Member
    [Documentation]    Isolating cluster node which is connected with bmp mock.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${bm_owner}
    BuiltIn.Set Suite variable    ${old_bm_owner}    ${bm_owner}
    BuiltIn.Set Suite variable    ${old_bm_candidates}    ${bm_candidates}
    ${idx}=    Collections.Get From List    ${old_bm_candidates}    0
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Verify_New_Pcep_Owner
    [Documentation]    Verifies if new owner of bmp-monitor is elected.
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_New_Pcep_Owner_Elected    ${old_bm_owner}    ${living_node}

Verify_Data_Reported_2
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    Verify_Data_Reported

Rejoin_Old_Owner_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_bm_owner}

Verify_New_Candidate
    [Documentation]    Verifies started node become candidate for bmp-monitor
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    5s    Verify_New_Pcep_Candidate_Present    ${old_bm_owner}    ${living_node}

Verify_Data_Reported_3
    [Documentation]    Verifies if example-bmp-monitor reported expected data
    Verify_Data_Reported

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to bmp-mock to stop it
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${odl1} =    SSHKeywords.Open_Connection_To_ODL_System    ip_address=${ODL_SYSTEM_1_IP}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    ${odl2} =    SSHKeywords.Open_Connection_To_ODL_System    ip_address=${ODL_SYSTEM_2_IP}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    ${odl3} =    SSHKeywords.Open_Connection_To_ODL_System    ip_address=${ODL_SYSTEM_3_IP}
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    ClusterManagement.ClusterManagement_Setup
    SSHKeywords.Open_Connection_To_Tools_System
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    pcep-pcc-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHLibrary.Get_File    pccmock.log
    ${cnt}=    OperatingSystem.Get_File    pccmock.log
    Log    ${cnt}
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Verify_Data_Reported
    [Arguments]    ${ip}=${TOOLS_SYSTEM_IP}
    [Documentation]    Verifies if the tool reported expected data
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ip}
    ${output}=    Wait Until Keyword Succeeds    6x    10s    TemplatedRequests.Get_As_Json_Templated    folder=${PCEP_VAR_FOLDER}${/}pcep_topology
    ...    mapping=${mapping}    session=${living_session}
    Log    ${output}

Verify_New_Pcep_Owner_Elected
    [Arguments]    ${old_owner}    ${node_to_ask}
    [Documentation]    Verifies new owner was elected
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    pcep-topology    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Not_Be_Equal    ${old_owner}    ${owner}

Verify_New_Pcep_Candidate_Present
    [Arguments]    ${candidate}    ${node_to_ask}
    [Documentation]    Verifies candidate's presence.
    ${owner}    ${candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    pcep-topology    org.opendaylight.mdsal.ServiceEntityType    ${node_to_ask}
    BuiltIn.Should_Contain    ${candidates}    ${candidate}

Stop_Tool
    [Documentation]    Stops the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
