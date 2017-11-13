*** Settings ***
Documentation     BGP functional HA testing with one exabgp peer.
...
...               Copyright (c) 2017 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses bmp mock. It is configured to have 3 peers (all 3 nodes of odl).
...               Bgp implemented with singleton accepts only one incomming conection. Exabgp
...               logs will show that one peer will be connected and two will fail.
...               After killing karaf which owned connection new owner should be elected and
...               this new owner should accept incomming bgp connection.
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
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpclustering
${HOLDTIME}       180
${BMP_INSTANCE}    example-bmp-monitor
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/empty_structure
${BMP_LOG_FILE}    bmpmock.log
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    bmp-monitors    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Log    ${rib_owner}
    BuiltIn.Set Suite variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    BuiltIn.Set Suite variable    ${rib_candidates}    ${rib_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Log    ${living_session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${rib_owner}

Verify BMP Feature
    [Documentation]    Verifies if feature is up
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${TOOLS_SYSTEM_IP}
    BuiltIn.Wait_Until_Keyword_Succeeds    6x    10s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_FEAT_DIR}    mapping=${mapping}    session=${living_session}
    ...    verify=True

#Reconfigure_ODL_To_Accept_Connection
#    [Documentation]    Configure BGP peer module with initiate-connection set to false.
#    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
#    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
#    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer_openconf    mapping=${mapping}    session=${living_session}
#    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Bmp_Mock
    [Documentation]    Starts bmp mock
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --local_address ${TOOLS_SYSTEM_IP} --remote_address ${ODL_SYSTEM_1_IP}:12345,${ODL_SYSTEM_2_IP}:12345,${ODL_SYSTEM_3_IP}:12345 --routers_count 1 --peers_count 1 --log_level TRACE 2>&1 | tee ${BMP_LOG_FILE}
    BuiltIn.Log    ${command}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${command}
    ${until_phrase}=    Set Variable    successfully established.
    ${output}=    SSHLibrary.Read_Until    ${until_phrase}
    BuiltIn.Log    ${output}
    SSHLibrary.Get_File    ${BMP_LOG_FILE}
    ${cnt}=    OperatingSystem.Get_File    ${BMP_LOG_FILE}
    Log    ${cnt}

Verify_Data_Reported_1
    [Documentation]    Verifies if the tool reported expected data
    BuiltIn.Sleep    10s
    Verify_Data_Reported

#Stop_Current_Owner_Member
#    [Documentation]    Stopping karaf which is connected with exabgp.
#    ClusterManagement.Kill_Single_Member    ${rib_owner}
#    BuiltIn.Set Suite variable    ${old_rib_owner}    ${rib_owner}
#    BuiltIn.Set Suite variable    ${old_rib_candidates}    ${rib_candidates}
#    ${idx}=    Collections.Get From List    ${old_rib_candidates}    0
#    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
#    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
#    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Isolate_Current_Owner_Member
    [Documentation]    Isolating cluster node which is connected with exabgp.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_candidates}    ${rib_candidates}
    ${idx}=    Collections.Get From List    ${old_rib_candidates}    0
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Verify_Data_Reported_2
    [Documentation]    Verifies if the tool reported expected data
    BuiltIn.Sleep    30s
    Verify_Data_Reported

#Start_Stopped_Member
#    [Documentation]    Starting stopped node
#    ClusterManagement.Start_Single_Member    ${old_rib_owner}

Rejoin_Isolated_Member
    [Documentation]    Rejoin isolated node
    ClusterManagement.Rejoin_Member_From_List_Or_All    ${old_rib_owner}

Verify_Data_Reported_3
    [Documentation]    Verifies if the tool reported expected data
    BuiltIn.Sleep    30s
    Verify_Data_Reported

Stop_Bmp_Mock
    [Documentation]    Send ctrl+c to bmp-mock to stop it
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

#Delete_Bgp_Peer_Configuration
#    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
#    &{mapping}    Create Dictionary    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    IP=${TOOLS_SYSTEM_IP}
#    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer_openconf    mapping=${mapping}    session=${living_session}

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
#    RequestsLibrary.Create_Session    ${living_session3}    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}    auth=${AUTH}
#    RequestsLibrary.Create_Session    ${living_session2}    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}    auth=${AUTH}
#    RequestsLibrary.Create_Session    ${living_session}    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    bgp-bmp-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}
    BuiltIn.Log    ${ODL_SYSTEM_IP}
    BuiltIn.Log    ${ODL_SYSTEM_1_IP}
    BuiltIn.Log    ${ODL_SYSTEM_2_IP}
    BuiltIn.Log    ${ODL_SYSTEM_3_IP}
    BuiltIn.Log    ${TOOLS_SYSTEM_IP}

Verify_Data_Reported
    [Arguments]    ${ip}=${TOOLS_SYSTEM_IP}
    [Documentation]    Verifies if the tool reported expected data
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ip}
    ${output}=    Wait Until Keyword Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}
    ...    mapping=${mapping}    session=${living_session}    verify=True
    Log    ${output}
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ODL_SYSTEM_1_IP}
    ${output}=    Wait Until Keyword Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}
    ...    mapping=${mapping}    session=${living_session}
    Log    ${output}
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ODL_SYSTEM_2_IP}
    ${output}=    Wait Until Keyword Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}
    ...    mapping=${mapping}    session=${living_session}
    Log    ${output}
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ODL_SYSTEM_3_IP}
    ${output}=    Wait Until Keyword Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}
    ...    mapping=${mapping}    session=${living_session}
    Log    ${output}
    ${response}    RequestsLibrary.Get_Request    alias=${living_session}    uri=/restconf/operational/bmp-monitor:bmp-monitor/monitor/example-bmp-monitor    headers=${ACCEPT_JSON}
    Log    ${response.json()}

Teardown_Everything
    [Documentation]    Suite cleanup
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Stop_Tool
    [Documentation]    Stops the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}



