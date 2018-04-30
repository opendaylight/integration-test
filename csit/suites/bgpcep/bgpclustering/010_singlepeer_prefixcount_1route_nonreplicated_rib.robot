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
...               Test suite checks changes of the the example-ipv4-topology default operational
...               shard leader only. Less stress for cluster is expected as if followers were
...               triggered for that.
Suite Setup       PrefixcountKeywords.Setup_Everything
Suite Teardown    PrefixcountKeywords.Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Fast_Failing
Test Teardown     SetupUtils.Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/KillPythonTool.robot
Resource          ../../../libraries/PrefixCounting.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot
Resource          PrefixcountKeywords.robot

*** Variables ***
${COUNT}          1

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set_Suite_Variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    ${rib_owner}
    BuiltIn.Set_Suite_Variable    ${config_session}    ${session}

Get Topology Operational Leader
    [Documentation]    Gets the operational topology shard leader
    ${leader}    ${followers}=    ClusterManagement.Get_Leader_And_Followers_For_Shard    shard_name=topology    shard_type=operational
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    ${leader}
    BuiltIn.Set_Suite_Variable    ${topo_lead_ses}    ${session}

Check_For_Empty_Ipv4_Topology_Before_Talking
    [Documentation]    Wait for ${EXAMPLE_IPV4_TOPOLOGY} to come up and empty. Give large timeout for case when BGP boots slower than restconf.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    ${INITIAL_RESTCONF_TIMEOUT}    1s    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${topo_lead_ses}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module in passive mode (not initiating connection)
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${config_session}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Talking_BGP_Speaker
    [Documentation]    Start Python speaker to connect to ODL.
    PrefixcountKeywords.Start_Bgp_Peer_And_Verify_Connected    connection_retries=${3}

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
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers
    &{mapping}    Create Dictionary    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${BGP_PEER_FOLDER}    mapping=${mapping}    session=${config_session}
