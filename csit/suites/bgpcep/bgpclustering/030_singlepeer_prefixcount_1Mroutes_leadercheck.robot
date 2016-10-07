*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2015-2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses play.py as single iBGP peer which talks to
...               single controller in three node cluster configuration.
...               Test suite checks changes of the the example-ipv4-topology-<dst_id> on all nodes.
...               RIB is not examined.
...               <dst-id> is recognized during the suite run, should be the Leader of default
...               operational Shard, otherwise the scenario would fail due to
...               https://bugs.opendaylight.org/show_bug.cgi?id=5536
Suite Setup       Setup_Everything
Suite Teardown    Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
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
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer
${BGP_VARIABLES_FOLDER_OP}    ${CURDIR}/../../../variables/bgpclustering/bgp_peer_operational
${NETCONF_DEV_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-device
${NETCONF_MOUNT_FOLDER}    ${CURDIR}/../../../variables/netconf/device/full-uri-mount
${CHECK_PERIOD}    10
${COUNT}          1000000
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

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set Suite variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set Suite variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_${rib_owner}_IP}:${RESTCONFPORT}    auth=${AUTH}

Get Topology Operational Leader
    [Documentation]    Gets the operationa topology shard leader
    ${leader}    ${followers}=     ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=topology    shard_type=operational
    BuiltIn.Set Suite variable    ${topo_lead_ses}      operational-${leader}

Check_For_Empty_Ipv4_Topology_Before_Talking_1
    [Documentation]    Wait for ${EXAMPLE_IPV4_TOPOLOGY} to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    ${INITIAL_RESTCONF_TIMEOUT}    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_Before_Talking_2
    [Documentation]    Wait for ${EXAMPLE_IPV4_TOPOLOGY} to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    ${INITIAL_RESTCONF_TIMEOUT}    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_Before_Talking_3
    [Documentation]    Wait for ${EXAMPLE_IPV4_TOPOLOGY} to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    ${INITIAL_RESTCONF_TIMEOUT}    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Configure_Netconf_Device
    [Documentation]    Configures and verifies netconf device configuration. If configuration is not successful, it de-configures the device before the next attempt.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    # After the netconf device is configured, odl starts downloading schemas. If the downloading will not finish within akka timeout, more tries are needed, 3 is based on a user experience.
    : FOR    ${index}    IN RANGE    0    3
    \    ${status}    ${value}=    Run Keyword And Ignore Error    Configure Netconf Device And Check Mounted    ${mapping}
    \    Exit For Loop If    '${status}' == 'PASS'
    \    Run Keyword Unless    '${status}' == 'PASS'    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    Run Keyword Unless    '${status}' == 'PASS'    Fail

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Talking_BGP_Speaker
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer

Wait_For_Stable_Talking_Ipv4_Topology
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable. This is done by checking stability of prefix count as seen from node 1.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=0    session=${topo_lead_ses}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_Talking_Ipv4_Topology_Count
    [Documentation]    Count the routes in ${EXAMPLE_IPV4_TOPOLOGY} and fail if the count is not correct as seen from node 1.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${topo_lead_ses}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On

Wait_For_Stable_Ipv4_Topology_After_Listening
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable again as seen from node 1.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${COUNT}    session=${topo_lead_ses}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_After_Listening
    [Documentation]    Example-ipv4-topology should be empty now as seen from node 1.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${topo_lead_ses}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Netconf_Device_Configuration
    [Documentation]    Revert the netconf configuration to the original stat
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

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

Store_File_To_Workspace
    [Arguments]    ${src_file_name}    ${dst_file_name}
    [Documentation]    Store the provided file from the SSH client to workspace.
    ${files}=    SSHLibrary.List Files In Directory    .
    ${output_log}=    SSHLibrary.Execute_Command    cat ${src_file_name}
    BuiltIn.Log    ${output_log}
    Create File    ${dst_file_name}    ${output_log}

Configure Netconf Device And Check Mounted
    [Arguments]    ${mapping}
    TemplatedRequests.Put_As_Xml_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    10x    3s    TemplatedRequests.Get_As_Xml_Templated    ${NETCONF_MOUNT_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Start Bgp Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount ${COUNT} --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${rib_owner_node_id} --peerport=${ODL_BGP_PORT} --insert=${INSERT} --withdraw=${WITHDRAW} --prefill ${PREFILL} --update ${UPDATE} --${BGP_TOOL_LOG_LEVEL} --results ${RESULTS_FILE_NAME}
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen
