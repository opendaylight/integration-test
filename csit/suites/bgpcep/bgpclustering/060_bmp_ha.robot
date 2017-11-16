*** Settings ***
Documentation     BGP functional HA testing with one exabgp peer.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses exabgp. It is configured to have 3 peers (all 3 nodes of odl).
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
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/RemoteBash.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../libraries/NexusKeywords.robot

*** Variables ***
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpclustering
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_openconf
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib
${CONFIG_SESSION}    node1
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/filled_structure
${BGP_BMP_FEAT_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic/empty_structure
${BMP_LOG_FILE}    bmpmock.log

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    BuiltIn.Set Suite variable    ${rib_candidates}    ${rib_candidates}
    ${session}=    Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${rib_owner}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Bmp_Mock
    [Documentation]    Starts bmp mock
    ${command}=    NexusKeywords.Compose_Full_Java_Command    -jar ${filename} --local_address ${TOOLS_SYSTEM_IP} -ra ${ODL_SYSTEM_1_IP}:12345,${ODL_SYSTEM_2_IP}:12345,${ODL_SYSTEM_3_IP}:12345 --routers_count 1 --peers_count 1 --log_level TRACE 2>&1 | tee ${BMP_LOG_FILE}
    BuiltIn.Log    ${command}
    SSHLibrary.Set_Client_Configuration    timeout=30s
    SSHLibrary.Write    ${command}
    ${until_phrase}=    Set Variable    successfully established.
    SSHLibrary.Read_Until    ${until_phrase}

Verify_Data_Reported_1
    [Documentation]    Verifies if the tool reported expected data
    Verify_Data_Reported

Verify_Data_Reported_2
    [Documentation]    Verifies if the tool reported expected data
    Verify_Data_Reported    session_verify=node2

Verify_Data_Reported_3
    [Documentation]    Verifies if the tool reported expected data
    Verify_Data_Reported    session_verify=node3

Stop_Current_Owner_Member
    [Documentation]    Stopping karaf which is connected with exabgp.
    Kill_Single_Member    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${old_rib_candidates}    ${rib_candidates}
    ${idx}=    Collections.Get From List    ${old_rib_candidates}    0
    ${session}=    Resolve_Http_Session_For_Member    member_index=${idx}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${idx}

Stop_Bmp_Mock
    [Documentation]    Sends ctrl-c to karaf
    Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
    &{mapping}    Create Dictionary    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    NexusKeywords.Initialize_Artifact_Deployment_And_Usage
    RequestsLibrary.Create_Session    node2    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    RequestsLibrary.Create_Session    node3    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    RequestsLibrary.Create_Session    node1    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}
    ${name}=    NexusKeywords.Deploy_Test_Tool    bgpcep    bgp-bmp-mock
    BuiltIn.Set_Suite_Variable    ${filename}    ${name}

Verify_Data_Reported
    [Arguments]    ${ip}=${TOOLS_SYSTEM_IP}    ${session_verify}=${CONFIG_SESSION}
    [Documentation]    Verifies if the tool reported expected data
    &{mapping}    BuiltIn.Create_Dictionary    TOOL_IP=${ip}
    ${output}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_BMP_DIR}    mapping=${mapping}    session=${session_verify}
    ...    verify=True
    BuiltIn.Log    ${output}

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
