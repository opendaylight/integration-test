*** Settings ***
Documentation     Basic tests for iBGP peers.
...
...               Copyright (c) 2015-2018 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               Test suite performs basic iBGP functional test cases for
...               BGP peers in different roles (iBGP, iBGP RR-client):
...
...               Test Case 1: Two iBGP RR-client peers introduce prefixes
...               Expected result: controller forwards updates towards both peers
...
...               Test Case 2: Two iBGP peers: one RR client and one non-client introduces prefixes
...               Expected result: controller forwards updates towards both peers
...
...               Test Case 3: Two iBGP RR non-client peers introduce prefixes
...               Expected result: controller does not forward any update towards peers
...
...               Test Case 4: Two iBGP(play.py) RR-client peers configured, first of them configured
...               with route-reflector-cluster-id, second inherits it's cluster-id from global config.
...               Each of them introduces 3 prefixes.
...               Expected result: controller forwards updates towards both peers and each of their
...               adj-rib-in contains routes. First peer should contain default cluster-id and
...               second cluster-id from first peers configuration.
...
...               For polices see: https://wiki.opendaylight.org/view/BGP_LS_PCEP:BGP
Suite Setup       Setup_Everything
Suite Teardown    BgpOperations.Teardown_Everything
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Test Teardown     FailFast.Start_Failing_Fast_If_This_Failed
Library           OperatingSystem
Library           RequestsLibrary
Library           DateTime
Variables         ../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}    ${ODL_STREAM}
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/FailFast.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/CompareStream.robot

*** Variables ***
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpuser/
${HOLDTIME}       180
${BGP_PEER_LOG_LEVEL}    debug
${ODL_LOG_LEVEL}    INFO
${ODL_BGP_LOG_LEVEL}    DEFAULT
${DEVICE_NAME}    controller-config
${BGP_PEER1_IP}    127.0.0.1
${BGP_PEER2_IP}    127.0.0.2
${BGP_PEER1_FIRST_PREFIX_IP}    8.1.0.0
${BGP_PEER2_FIRST_PREFIX_IP}    8.2.0.0
${PREFIX_LEN}     28
${BGP_PEER1_PREFIX_LEN}    ${PREFIX_LEN}
${BGP_PEER2_PREFIX_LEN}    ${PREFIX_LEN}
${PREFIX_COUNT}    3
${BGP_PEER1_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER2_PREFIX_COUNT}    ${PREFIX_COUNT}
${BGP_PEER1_LOG_FILE}    bgp_peer1.log
${BGP_PEER2_LOG_FILE}    bgp_peer2.log
${BGP_PEER1_COMMAND}    python play.py --firstprefix ${BGP_PEER1_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER1_PREFIX_LEN} --amount ${BGP_PEER1_PREFIX_COUNT} --myip=${BGP_PEER1_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER1_LOG_FILE}
${BGP_PEER2_COMMAND}    python play.py --firstprefix ${BGP_PEER2_FIRST_PREFIX_IP} --prefixlen ${BGP_PEER2_PREFIX_LEN} --amount ${BGP_PEER2_PREFIX_COUNT} --myip=${BGP_PEER2_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --${BGP_PEER_LOG_LEVEL} --logfile ${BGP_PEER2_LOG_FILE}
${BGP_PEER1_OPTIONS}    &>${BGP_PEER1_LOG_FILE}
${BGP_PEER2_OPTIONS}    &>${BGP_PEER2_LOG_FILE}
${DEFAULT_LOG_CHECK_TIMEOUT}    20s
${DEFAULT_LOG_CHECK_PERIOD}    1s
${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    10s
${DEFAULT_TOPOLOGY_CHECK_PERIOD}    1s
${CONFIG_SESSION}    session
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}

*** Test Cases ***
TC1_Configure_Two_iBGP_Route_Reflector_Client_Peers
    [Documentation]    Configure two iBGP peers as routing reflector clients.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC1_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC1_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC1_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0

TC1_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0

TC1_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc1_${BGP_PEER1_LOG_FILE}

TC1_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1

TC1_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc1_${BGP_PEER2_LOG_FILE}

TC_1_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC1_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC2_Configure_One_iBGP_Route_Reflector_Client_And_One_iBGP_Non_Client
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=rr-client    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=ibgp    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=false
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC2_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC2_BGP_Peer1_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER2_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    nlri_prefix_received: ${BGP_PEER2_FIRST_PREFIX_IP}/${BGP_PEER2_PREFIX_LEN}    1
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    withdrawn_prefix_received:    0

TC2_BGP_Peer2_Check_Log_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    nlri_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    0

TC2_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc2_${BGP_PEER1_LOG_FILE}

TC2_BGP_Peer2_Check_Log_For_Withdrawn_Prefixes
    [Documentation]    Check incomming updates for withdrawn routes
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received:    ${BGP_PEER1_PREFIX_COUNT}
    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    withdrawn_prefix_received: ${BGP_PEER1_FIRST_PREFIX_IP}/${BGP_PEER1_PREFIX_LEN}    1

TC2_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc2_${BGP_PEER2_LOG_FILE}

TC_2_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC2_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC3_Configure_Two_iBGP_Non_Client_Peers
    [Documentation]    Configure iBGP peers: 1st one as RR client, 2nd one as RR non-client.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=ibgp    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=false
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    PEER_ROLE=ibgp    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    RR_CLIENT=false
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC3_Connect_BGP_Peer1
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC3_Connect_BGP_Peer2
    [Documentation]    Connect BGP peer
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER2_COMMAND}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC3_BGP_Peer1_Check_Log_For_No_Updates
    [Documentation]    Check for no updates received by iBGP peer No. 1
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_LOG_CHECK_TIMEOUT}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER1_LOG_FILE}    total_received_update_message_counter: 0    2

TC3_Disconnect_BGP_Peer1
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc3_${BGP_PEER1_LOG_FILE}

TC3_BGP_Peer2_Check_Log_For_No_Updates
    [Documentation]    Consequent check for no updates received by iBGP peer No. 2
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    ${log_check_timeout}=    DateTime.Convert_Time    ${DEFAULT_LOG_CHECK_TIMEOUT}    result_format=number
    BuiltIn.Wait_Until_Keyword_Succeeds    ${log_check_timeout*2}    ${DEFAULT_LOG_CHECK_PERIOD}    BGPCliKeywords.Check_File_For_Word_Count    ${BGP_PEER2_LOG_FILE}    total_received_update_message_counter: 0    4

TC3_Disconnect_BGP_Peer2
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc3_${BGP_PEER2_LOG_FILE}

TC_3_Check_for_Empty_IPv4_Topology
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC3_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer1    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    NAME=example-bgp-peer2    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC4_Configure_Two_iBGP_RR_Clients_With_Cluster_Id
    [Documentation]    Configure two iBGP peers as routing reflector clients with cluster-id argument.
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER1_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}cluster_id/ibgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER2_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    RR_CLIENT=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

TC4_Connect_BGP_Peers
    [Documentation]    Connect BGP peers, each set to send 3 prefixes.
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    SSHLibrary.Switch Connection    bgp_peer1_console
    BuiltIn.Set_Suite_Variable    ${peer1_cluster_id}    127.0.0.4
    BuiltIn.Set_Suite_Variable    ${default_cluster_id}    192.0.2.2
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER1_COMMAND} --cluster=${peer1_cluster_id}    ${BGP_PEER1_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER1_FIRST_PREFIX_IP}/${PREFIX_LEN}"}
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Start_Console_Tool    ${BGP_PEER2_COMMAND} --cluster=${BGP_PEER2_IP}    ${BGP_PEER2_OPTIONS}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Content    {"prefix":"${BGP_PEER2_FIRST_PREFIX_IP}/${PREFIX_LEN}"}

TC4_BGP_Peer1_Check_Rib_Out_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes and respective cluster-ids
    ...    on first peer which should contain default-cluster id from global config reflected
    ...    from the second peer equal to router-id.
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PEER_NUMBER=2    CLUSTER_ID=${BGP_PEER2_IP}    DEFAULT_ID=${default_cluster_id}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}cluster_id/peer_rib_out    mapping=${mapping}    session=${CONFIG_SESSION}
    ...    verify=True

TC4_BGP_Peer2_Check_Rib_Out_For_Introduced_Prefixes
    [Documentation]    Check incomming updates for new routes and respective cluster-ids
    ...    in second peer which has local route-reflector-cluster-id
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PEER_NUMBER=1    CLUSTER_ID=${BGP_PEER1_IP}    DEFAULT_ID=${peer1_cluster_id}
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    TemplatedRequests.Get_As_Json_Templated    ${BGP_VARIABLES_FOLDER}${/}cluster_id/peer_rib_out    mapping=${mapping}    session=${CONFIG_SESSION}
    ....    verify=True

TC4_Disconnect_BGP_Peers
    [Documentation]    Stop BGP peer & store logs
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    SSHLibrary.Switch Connection    bgp_peer1_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER1_LOG_FILE}    tc4_${BGP_PEER1_LOG_FILE}
    SSHLibrary.Switch Connection    bgp_peer2_console
    BGPCliKeywords.Stop_Console_Tool
    BGPCliKeywords.Store_File_To_Workspace    ${BGP_PEER2_LOG_FILE}    tc4_${BGP_PEER2_LOG_FILE}

TC4_Check_for_Empty_IPv4_Topology
    [Documentation]    Checks for empty topology after
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    BuiltIn.Wait_Until_Keyword_Succeeds    ${DEFAULT_TOPOLOGY_CHECK_TIMEOUT}    ${DEFAULT_TOPOLOGY_CHECK_PERIOD}    BgpOperations.Check_Example_IPv4_Topology_Does_Not_Contain    prefix

TC4_Delete_BGP_Peers_Configuration
    [Documentation]    Delete all previously configured BGP peers.
    [Tags]    critical
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    Test case valid for version fluorine and above.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER1_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}cluster_id/ibgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${BGP_PEER2_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}${/}ibgp_peers    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Setup_Everything
    [Documentation]    Initialize SetupUtils. SSH-login to mininet machine, create HTTP session,
    ...    prepare directories for responses, put Python tool to mininet machine, setup imported resources.
    # TODO: Choose keywords used by more than one test suite to be placed in a common place.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    SSHLibrary.Set_Default_Configuration    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer1_console
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Open_Connection    ${ODL_SYSTEM_IP}    alias=bgp_peer2_console
    SSHKeywords.Flexible_Controller_Login
    SSHKeywords.Require_Python
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Put_File    ${CURDIR}/../../../../tools/fastbgp/play.py
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_LOG_LEVEL}
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.bgpcep
    KarafKeywords.Execute_Controller_Karaf_Command_On_Background    log:set ${ODL_BGP_LOG_LEVEL} org.opendaylight.protocol
