*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               For propper usage of this resource ${config_session} varaible has to be set.
...               It should point to http://<ip-addr>:${RESTCONFPORT}.
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/ClusterAdmin.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KillPythonTool.robot
Resource          ../../../libraries/PrefixCounting.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/ShardStability.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BGP_TOOL_LOG_LEVEL}    info
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_openconf    # used for configuration of bgp peer via openconfig
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer    # used for configuration of bgp peer
${BGP_VARIABLES_FOLDER_OP}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_operational
${CHECK_PERIOD}    10
${HOLDTIME}       180
${INSERT}         1
${KARAF_LOG_LEVEL}    INFO
${KARAF_BGPCEP_LOG_LEVEL}    ${KARAF_LOG_LEVEL}
${KARAF_PROTOCOL_LOG_LEVEL}    ${KARAF_BGPCEP_LOG_LEVEL}
${PREFILL}        0
${REPETITIONS}    1
${RESULTS_FILE_NAME}    bgp.csv
${TEST_DURATION_MULTIPLIER}    1
${UPDATE}         single
${WITHDRAW}       0
${INITIAL_RESTCONF_TIMEOUT}    30s
${KARAF_HOME}     ${WORKSPACE}/${BUNDLEFOLDER}
${SHARD_DEFAULT_CONFIG}    shard-default-config
${SHARD_DEFAULT_OPERATIONAL}    shard-default-operational
${EXAMPLE_IPV4_TOPOLOGY}    example-ipv4-topology
${DEVICE_NAME}    peer-controller-config
${DEVICE_CHECK_TIMEOUT}    60s
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${BGP_PEER_NAME}    example-bgp-peer
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
@{SHARD_MONITOR_LIST}    default:config    default:operational    topology:config    topology:operational    inventory:config    inventory:operational

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown    http_timeout=125
    PrefixCounting.PC_Setup
    ${indices} =    ClusterManagement.List_All_Indices
    : FOR    ${member_index}    IN    @{indices}
    \    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    ${member_index}
    \    BuiltIn.Set_Suite_Variable    ${operational_${member_index}}    ${session}
    BuiltIn.Set_Suite_Variable    ${pc_all_indices}    ${indices}
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    SSHKeywords.Flexible_Mininet_Login
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    # Calculate the timeout value based on how many routes are going to be pushed
    # TODO: Replace 35 with some formula from period and repetitions.
    ${timeout} =    BuiltIn.Evaluate    ${TEST_DURATION_MULTIPLIER} * (${COUNT} * 6.0 / 10000 + 35)
    Builtin.Set_Suite_Variable    ${bgp_filling_timeout}    ${timeout}
    Builtin.Set_Suite_Variable    ${bgp_emptying_timeout}    ${bgp_filling_timeout*3.0/4}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${KARAF_LOG_LEVEL}
    ${init_shard_details} =    ShardStability.Shards_Stability_Get_Details    ${SHARD_MONITOR_LIST}
    BuiltIn.Set_Suite_Variable    ${init_shard_details}

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    # TODO:    This keyword is not specific to prefix counting. Find a better place for it.
    # Environment issue may have dropped the SSH connection, but we do not want Teardown to fail.
    BuiltIn.Run_Keyword_And_Ignore_Error    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Start_Bgp_Peer
    [Arguments]    ${peerip}=${rib_owner_node_id}
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    # TODO:    This keyword is not specific to prefix counting. Find a better place for it.
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${peerip} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}

Start_Bgp_Peer_And_Verify_Connected
    [Arguments]    ${connection_retries}=${1}    ${peerip}=${rib_owner_node_id}
    [Documentation]    Starts the peer and verifies its connection. The verification is done by checking the presence
    ...    of the peer in the bgp rib.
    # TODO:    This keyword is not specific to prefix counting. Find a better place for it.
    : FOR    ${idx}    IN RANGE    ${connection_retries}
    \    Start_Bgp_Peer    peerip=${peerip}
    \    ${status}    ${value}=    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s
    \    ...    Verify_Bgp_Peer_Connection    ${config_session}    ${TOOLS_SYSTEM_IP}    connected=${True}
    \    BuiltIn.Run_Keyword_Unless    "${status}" == "PASS"    BGPSpeaker.Kill_BGP_Speaker
    \    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"
    BuiltIn.Fail    Unable to connect bgp peer to ODL

Verify_Bgp_Peer_Connection
    [Arguments]    ${session}    ${peer_ip}    ${connected}=${True}
    [Documentation]    Checks peer presence in operational datastore
    # TODO:    This keyword is not specific to prefix counting. Find a better place for it.
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${PEER_CHECK_URL}${peer_ip}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}

Set_Shard_Leaders_Location_And_Verify
    [Arguments]    ${requested_shard_localtion_idx}
    [Documentation]    Move default/topology config/operational shard location to local or remote node as requested
    ...    towards the given rib singleton instance location.
    ShardStability.Set_Shard_Location    ${requested_shard_localtion_idx}
    BuiltIn.Wait_Until_Keyword_Succeeds    30s    5s    ShardStability.Verify_Shard_Leader_Located_As_Expected    ${requested_shard_localtion_idx}    http_timeout=125
    ${init_shard_details} =    ShardStability.Shards_Stability_Get_Details    ${SHARD_MONITOR_LIST}
    BuiltIn.Set_Suite_Variable    ${init_shard_details}
