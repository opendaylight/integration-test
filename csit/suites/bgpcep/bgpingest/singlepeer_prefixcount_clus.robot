*** Settings ***
Documentation     BGP ingerst prefix counting performance suite with clustered odl and
...               one play.py peer.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses play.py. Odl is configured to have 1 peer via openconfig api.
...               The owner of example-bgp-rib is needed to know which cluster member should
...               be used to connect to.
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot

*** Variables ***
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/openconfig_bgp_peer
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib
${BGP_TOOL_LOG_LEVEL}    info
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${CHECK_PERIOD}    1
${CHECK_PERIOD_PREFIX_COUNT}    ${CHECK_PERIOD}
${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    ${CHECK_PERIOD_PREFIX_COUNT}
${COUNT}          1000000
${COUNT_PREFIX_COUNT}    ${COUNT}
${COUNT_PREFIX_COUNT_SINGLE}    ${COUNT_PREFIX_COUNT}
${HOLDTIME}       180
${HOLDTIME_PREFIX_COUNT}    ${HOLDTIME}
${HOLDTIME_PREFIX_COUNT_SINGLE}    ${HOLDTIME_PREFIX_COUNT}
${INSERT}         1
${PREFILL}        0
${REPETITIONS}    1
${REPETITIONS_PREFIX_COUNT}    ${REPETITIONS}
${REPETITIONS_PREFIX_COUNT_SINGLE}    ${REPETITIONS_PREFIX_COUNT}
${RESULTS_FILE_NAME}    bgp.csv
${TEST_DURATION_MULTIPLIER}    1
${TEST_DURATION_MULTIPLIER_PREFIX_COUNT}    ${TEST_DURATION_MULTIPLIER}
${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_SINGLE}    ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT}
${UPDATE}         single
${WITHDRAW}       0
${PREFCOUNT_SESSION}    prefcount_session

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node bgp peer should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set_Suite_Variable    ${rib_owner_node_ip}    ${ODL_SYSTEM_${rib_owner}_IP}
    BuiltIn.Set_Suite_Variable    ${rib_candidates}    ${rib_candidates}
    ${session}=    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${living_session}    ${session}
    BuiltIn.Set_Suite_Variable    ${living_node}    ${rib_owner}
    RequestsLibrary.Create_Session    ${PREFCOUNT_SESSION}    http://${rib_owner_node_ip}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Talking_BGP_Speaker
    [Documentation]    Start Python speaker to connect to ODL.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Start_Tool

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until example-ipv4-topology becomes stable. This is done by checking stability of prefix count.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=0    session=${PREFCOUNT_SESSION}

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in example-ipv4-topology and fail if the count is not correct.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT_PREFIX_COUNT_SINGLE}    session=${PREFCOUNT_SESSION}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Store_Results_For_Talking_BGP_Speaker
    [Documentation]    Store results for plotting
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    performance-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    totals-${RESULTS_FILE_NAME}    prefixcount-talking-totals-${RESULTS_FILE_NAME}
    Store_File_To_Workspace    performance-${RESULTS_FILE_NAME}    prefixcount-talking-performance-${RESULTS_FILE_NAME}

Wait_For_Stable_Ipv4_Topology_After_Talking
    [Documentation]    Wait until example-ipv4-topology becomes stable again.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD_PREFIX_COUNT_SINGLE}    repetitions=${REPETITIONS_PREFIX_COUNT_SINGLE}    excluded_count=${COUNT_PREFIX_COUNT_SINGLE}    session=${PREFCOUNT_SESSION}

Check_For_Empty_Ipv4_Topology_After_Talking
    [Documentation]    Example-ipv4-topology should be empty now.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${PREFCOUNT_SESSION}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
    &{mapping}    Create Dictionary    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${living_session}

*** Keywords ***
Setup_Everything
    [Documentation]    Initial setup
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER_PREFIX_COUNT_SINGLE} * (${COUNT_PREFIX_COUNT_SINGLE} * 9.0 / 10000 + 20)
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}

Teardown_Everything
    [Documentation]    Suite cleanup
    SSHKeywords.Virtual_Env_Delete
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Start_Tool
    [Documentation]    Starts the tool
    SSHLibrary.Set_Client_Configuration    timeout=2s
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT_PREFIX_COUNT_SINGLE} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${rib_owner_node_ip} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}
    ${status}    ${result} =    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    2x    1s    Verify_Tools_Connection
    ...    ${living_session}
    BuiltIn.Log    ${status}
    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"
    BGPSpeaker.Dump_BGP_Speaker_Logs
    BGPSpeaker.Kill_BGP_Speaker
    BuiltIn.Fail    "Bgp speaker not connected which was not expected"

Store_File_To_Workspace
    [Arguments]    ${src_file_name}    ${dst_file_name}
    [Documentation]    Store the provided file from the SSH client to workspace.
    ${files}=    SSHLibrary.List Files In Directory    .
    ${output_log}=    SSHLibrary.Execute_Command    cat ${src_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${dst_file_name}    ${output_log}

Verify_Tools_Connection
    [Arguments]    ${session}    ${connected}=${True}
    [Documentation]    Checks peer presence in operational datastore
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${PEER_CHECK_URL}${TOOLS_SYSTEM_IP}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}
