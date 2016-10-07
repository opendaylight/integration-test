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
Suite Setup       PrefixcountKeywords.Setup_Everything
Suite Teardown    PrefixcountKeywords.Teardown_Everything
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
Resource          ${CURDIR}/PrefixcountKeywords.robot

*** Variables ***
${COUNT}          1

*** Test Cases ***
Get Example Bgp Rib Owner
    [Documentation]    Find an odl node which is able to accept incomming connection. To this node netconf connector should be configured.
    ${rib_owner}    ${rib_candidates}=    ClusterManagement.Get_Owner_And_Successors_For_device    example-bgp-rib    org.opendaylight.mdsal.ServiceEntityType    1
    BuiltIn.Set_Suite_Variable    ${rib_owner}    ${rib_owner}
    BuiltIn.Set_Suite_Variable    ${rib_owner_node_id}    ${ODL_SYSTEM_${rib_owner}_IP}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_${rib_owner}_IP}:${RESTCONFPORT}    auth=${AUTH}

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
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    # After the netconf device is configured, odl starts downloading schemas. If the downloading will not finish within akka timeout, more tries are needed, 3 is based on a user experience.
    : FOR    ${index}    IN RANGE    0    3
    \    ${status}    ${value}=    Run Keyword And Ignore Error    PrefixcountKeywords.Configure_Netconf_Device_And_Check_Mounted    ${mapping}
    \    Exit For Loop If    '${status}' == 'PASS'
    \    Run Keyword Unless    '${status}' == 'PASS'    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    Run Keyword Unless    '${status}' == 'PASS'    Fail

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
    [Teardown]    SetupUtils.Teardown_Test_Show_Bugs_If_Test_Failed

Start_Talking_BGP_Speaker
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    PrefixcountKeywords.Start_Bgp_Peer

Wait_For_Stable_Talking_Ipv4_Topology_1
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable. This is done by checking stability of prefix count as seen from node 1.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=0    session=${CONFIGURATION_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Wait_For_Stable_Talking_Ipv4_Topology_2
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable. This is done by checking stability of prefix count as seen from node 2.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=0    session=${CONFIGURATION_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Wait_For_Stable_Talking_Ipv4_Topology_3
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable. This is done by checking stability of prefix count as seen from node 3.
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=0    session=${CONFIGURATION_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_Talking_Ipv4_Topology_Count_1
    [Documentation]    Count the routes in ${EXAMPLE_IPV4_TOPOLOGY} and fail if the count is not correct as seen from node 1.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${CONFIGURATION_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_Talking_Ipv4_Topology_Count_2
    [Documentation]    Count the routes in ${EXAMPLE_IPV4_TOPOLOGY} and fail if the count is not correct as seen from node 2.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${CONFIGURATION_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_Talking_Ipv4_Topology_Count_3
    [Documentation]    Count the routes in ${EXAMPLE_IPV4_TOPOLOGY} and fail if the count is not correct as seen from node 3.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Count    ${COUNT}    session=${CONFIGURATION_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker. Also, attempt to stop failing fast.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    FailFast.Do_Not_Fail_Fast_From_Now_On

Wait_For_Stable_Ipv4_Topology_After_Listening_1
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable again as seen from node 1.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${COUNT}    session=${CONFIGURATION_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Wait_For_Stable_Ipv4_Topology_After_Listening_2
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable again as seen from node 2.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${COUNT}    session=${CONFIGURATION_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Wait_For_Stable_Ipv4_Topology_After_Listening_3
    [Documentation]    Wait until ${EXAMPLE_IPV4_TOPOLOGY} becomes stable again as seen from node 3.
    [Tags]    critical
    PrefixCounting.Wait_For_Ipv4_Topology_Prefixes_To_Become_Stable    timeout=${bgp_filling_timeout}    period=${CHECK_PERIOD}    repetitions=${REPETITIONS}    excluded_count=${COUNT}    session=${CONFIGURATION_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_After_Listening_1
    [Documentation]    Example-ipv4-topology should be empty now as seen from node 1.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_1}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_After_Listening_2
    [Documentation]    Example-ipv4-topology should be empty now as seen from node 2.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_2}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Check_For_Empty_Ipv4_Topology_After_Listening_3
    [Documentation]    Example-ipv4-topology should be empty now as seen from node 3.
    [Tags]    critical
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    PrefixCounting.Check_Ipv4_Topology_Is_Empty    session=${CONFIGURATION_3}    topology=${EXAMPLE_IPV4_TOPOLOGY}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

Delete_Netconf_Device_Configuration
    [Documentation]    Revert the netconf configuration to the original stat
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    DEVICE_PORT=1830    DEVICE_IP=${rib_owner_node_id}    DEVICE_USER=admin    DEVICE_PASSWORD=admin
    TemplatedRequests.Delete_Templated    ${NETCONF_DEV_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}
