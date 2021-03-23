*** Settings ***
Documentation     BGP performance of ingesting from 1 iBGP peer, data change counter is NOT used.
...
...               Copyright (c) 2015-2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses play.py as single iBGP peer which talks to
...               single controller in three node cluster configuration.
...               Test suite checks changes of the the example-ipv4-topology on all nodes.
...               RIB is not examined.
...
...               singlepeer_pc_shm_300kroutes_longevity.robot:
...               pc - prefix counting
...               shm - shard monitoring (during the process of prefix advertizing)
Suite Setup       PrefixcountKeywords.Setup_Everything
Suite Teardown    PrefixcountKeywords.Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Default Tags      critical
Library           SSHLibrary    timeout=10s
Resource          ${CURDIR}/../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/BGPSpeaker.robot
Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot
Resource          ${CURDIR}/../../../libraries/KillPythonTool.robot
Resource          ${CURDIR}/../../../libraries/PrefixCounting.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ClusterManagement.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/WaitForFailure.robot
Resource          ${CURDIR}/PrefixcountKeywords.robot

*** Variables ***
${COUNT}          300000
# TODO: change back to 24h when releng has more granular steps to kill VMs than days; now 23h=82800s
${LONGEVITY_TEST_DURATION_IN_SECS}    10800

*** Test Cases ***
Configure_Prefixes_Longevity
    [Documentation]    Configure bgp peer, repeat the test scenario for 24h and deconfigure it.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    PrefixcountKeywords.Set_Shard_Leaders_Location_And_Verify    ${rib_owner}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${INITIAL_RESTCONF_TIMEOUT}    1s    Check_For_Empty_Ipv4_Topology_On_All_Nodes
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    Check_For_Empty_Ipv4_Topology_On_All_Nodes
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${rib_owner}
    BuiltIn.Set_Suite_Variable    ${config_session}    ${session}
    # TODO: Either define BGP_VARIABLES_FOLDER in this file, or create a Resource with the definition and wrapping keywords
    # Wait for 3s, just to make sure example-bgp-rib-service-group is up and running
    BuiltIn.Sleep    3s
    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${session}
    WaitForFailure.Verify_Keyword_Does_Not_Fail_Within_Timeout    ${LONGEVITY_TEST_DURATION_IN_SECS}    1s    Test_Scenario    ${rib_owner}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${session}

*** Keywords ***
Test_Scenario
    [Arguments]    ${rib_owner_id}
    [Documentation]    Connect bgp peer, advertize prefixes and disconnect. Check correct count of prefixes on odl.
    PrefixcountKeywords.Start_Bgp_Peer_And_Verify_Connected    connection_retries=${3}    peerip=${ODL_SYSTEM_${rib_owner_id}_IP}
    Wait_For_Stable_Talking_Ipv4_Topology_On_All_Nodes    excluded_count=0
    Check_Talking_Ipv4_Topology_Count_On_All_Nodes
    BGPSpeaker.Kill_BGP_Speaker
    Wait_For_Stable_Talking_Ipv4_Topology_On_All_Nodes    excluded_count=${COUNT}
    Check_For_Empty_Ipv4_Topology_On_All_Nodes

Check_For_Empty_Ipv4_Topology_On_All_Nodes
    [Documentation]    Check the topology is empty on all 3 nodes.
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${operational_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${operational_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${operational_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Wait_For_Stable_Talking_Ipv4_Topology_On_All_Nodes
    [Arguments]    ${excluded_count}
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable. This is done by checking stability of prefix count.
    # TODO: Make the keyword accept member_index_list (or at least session_list) to monitor at once, so that robot can fail faster.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${excluded_count}    session=${operational_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    ...    shards_list=${SHARD_MONITOR_LIST}    shards_details=${init_shard_details}
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${excluded_count}    session=${operational_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    ...    shards_list=${SHARD_MONITOR_LIST}    shards_details=${init_shard_details}
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${excluded_count}    session=${operational_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    ...    shards_list=${SHARD_MONITOR_LIST}    shards_details=${init_shard_details}

Check_Talking_Ipv4_Topology_Count_On_All_Nodes
    [Documentation]    Count the routes in ${EXAMPLE_IPV4_TOPOLOGY} on all nodes and fail if the count is not correct.
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${operational_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${operational_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${operational_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}
