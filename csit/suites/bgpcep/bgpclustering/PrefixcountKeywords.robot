*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/FailFast.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot

*** Variables ***
${BGP_TOOL_LOG_LEVEL}    info
${BGP_PEER_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/openconfig_bgp_peer    # used for configuration of bgp peer via openconfig
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer    # used for configuration of bgp peer vie netconf connector
${BGP_VARIABLES_FOLDER_OP}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_operational
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${NETCONF_MOUNT_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-mount
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
${CONFIG_SESSION}    config-session
${CONFIGURATION_1}    operational-1
${CONFIGURATION_2}    operational-2
${CONFIGURATION_3}    operational-3
${EXAMPLE_IPV4_TOPOLOGY}    example-ipv4-topology
${DEVICE_NAME}    peer-controller-config
${DEVICE_CHECK_TIMEOUT}    60s
${RIB_INSTANCE}    example-bgp-rib
${BGP_PEER_NAME}    example-bgp-peer

*** Keywords ***
Setup_Everything
    [Documentation]    Setup imported resources, SSH-login to tools system,
    ...    create HTTP session, put Python tool to tools system.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ClusterManagement.ClusterManagement_Setup
    RequestsLibrary.Create_Session    ${CONFIGURATION_1}    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    ${CONFIGURATION_2}    http://${ODL_SYSTEM_2_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    ${CONFIGURATION_3}    http://${ODL_SYSTEM_3_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    PrefixCounting.PC_Setup
    SSHLibrary.Set_Default_Configuration    prompt=${TOOLS_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}
    Utils.Flexible_Mininet_Login
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

Teardown_Everything
    [Documentation]    Make sure Python tool was killed and tear down imported Resources.
    # Environment issue may have dropped the SSH connection, but we do not want Teardown to fail.
    BuiltIn.Run_Keyword_And_Ignore_Error    KillPythonTool.Search_And_Kill_Remote_Python    'play\.py'
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Configure_Netconf_Device_And_Check_Mounted
    [Arguments]    ${mapping}
    [Documentation]    Configures netconf device
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_MOUNT_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${rib_owner_node_id} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen
