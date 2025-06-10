*** Settings ***
Documentation       Functional test for ipv6 connection with bgp.
...
...                 Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 This suite tests simple connection between one ibgp peer (exabgp) and Odl.
...                 Peer is configured with ipv6, and exabgp connectes to odl via ipv6.
...                 Exabgp sends one ipv6 unicast route, which presence is verified in
...                 example-ipv6-topology. Tests this connection multiple times, with
...                 different ipv6 accepted formats, e.g. (::1, 0:0:0:0:0:0:0:1, full text)
...                 This suite also tests a combination of afi-safis on odl and exabgp.
...                 ipv6 route injection is carried out from odl to the ibgp peer without
...                 ipv6 family enabled on the peer device and checked for exceptions

Library             RequestsLibrary
Library             SSHLibrary
Resource            ../../../libraries/BGPcliKeywords.robot
Resource            ../../../libraries/ExaBgpLib.robot
Resource            ../../../libraries/SetupUtils.robot
Resource            ../../../libraries/SSHKeywords.robot
Resource            ../../../libraries/TemplatedRequests.robot
Resource            ../../../libraries/Utils.robot
Resource            ../../../variables/Variables.robot
Resource            ../../../libraries/KarafKeywords.robot

Suite Setup         Start_Suite
Suite Teardown      Stop_Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${BGP_VAR_FOLDER}           ${CURDIR}/../../../variables/bgpfunctional/ipv6
${CONFIG_SESSION}           config-session
${CONTROLLER_IPV6}          ::1
${EXABGP_ID}                1.2.3.4
${EXABGP_ID_2}              127.0.0.1
${EXABGP_CFG}               exaipv6.cfg
${EXABGP_LOG}               exaipv6.log
${EXABGP2_CFG}              exaipv4.cfg
${EXABGP2_LOG}              exaipv4.log
${EXABGP3_CFG}              exabgp_graceful_restart.cfg
${EXABGP3_LOG}              exabgp_graceful_restart.log
${EXABGP4_CFG}              exa4.cfg
${EXABGP4_LOG}              exa4.log
${IPV4_IP}                  127.0.0.1
${CONTROLLER_IPV4}          ${ODL_SYSTEM_IP}
${IPV6_IP}                  2607:f0d0:1002:0011:0000:0000:0000:0002
${IPV6_IP_2}                2607:f0d0:1002:11:0:0:0:2
${IPV6_IP_3}                2607:f0d0:1002:11::2
${IPV6_IP_GW}               2607:f0d0:1002:0011:0000:0000:0000:0001
${IPV6_PREFIX_LENGTH}       64
${HOLDTIME}                 180
${RIB_INSTANCE}             example-bgp-rib


*** Test Cases ***
Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Start_Exabgp
    [Documentation]    Start exabgp with
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP_CFG} > ${EXABGP_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Verify_Ipv6_Topology_Filled
    [Documentation]    Verifies that example-ipv6-topology is filled after starting exabgp.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_2
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with ipv6 address without "::" shortened version.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP_2}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_2
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_2
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP_2}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_2
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_3
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with full text ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP_3}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_3
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the third time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_3
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP_3}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_3
    [Documentation]    Verifies that example-ipv6-topology is empty after final deconfiguration.
    [Tags]    critical
    Verify_Rib_Status_Empty

Stop_All_Exabgps
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP_LOG}    ${EXABGP_LOG}
    ExaBgpLib.Stop_ExaBgp

Configure_App_Peer
    [Documentation]    Configures bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/application_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connections_4
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${IPV4_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_neighbor_rib
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}
    RequestsLibrary.Create Session
    ...    session
    ...    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}
    ...    auth=${AUTH}
    ...    headers=${HEADERS}
    ...    timeout=5

Start_Exabgp_2
    [Documentation]    Start exabgp and Verify BGP connection
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP2_CFG} > ${EXABGP2_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    127.0.0.1

Inject_Ipv6_Route_1
    [Documentation]    Inject the Ipv6 route from controller
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_route_injection
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Check_Ipv6_Prefix_In_Bgp_Rib_1
    [Documentation]    Check for the presence of Ipv6 Prefix in the BGP RIB
    &{mapping}    Create Dictionary
    ...    IP=${CONTROLLER_IPV4}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    5x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_rib
    ...    session=${CONFIG_SESSION}
    ...    mapping=${mapping}

Delete_Injected_Ipv6_Routes_1
    [Documentation]    Delete the injected IPV6 routes
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_route_injection
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${True}

Delete_Bgp_Peer_Configuration_4
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV4_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_neighbor_rib
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_4
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_5
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${IPV4_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Inject_Ipv6_Route_2
    [Documentation]    Inject the Ipv6 route from controller
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_route_injection
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Check_Ipv6_Prefix_In_Bgp_Rib_2
    [Documentation]    Check for the presence of Ipv6 Prefix in the BGP RIB
    &{mapping}    Create Dictionary
    ...    IP=${CONTROLLER_IPV4}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    5x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_rib
    ...    session=${CONFIG_SESSION}
    ...    mapping=${mapping}

Delete_Injected_Ipv6_Routes_2
    [Documentation]    Delete the injected IPV6 routes
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_route_injection
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${True}

Delete_App_Peer
    [Documentation]    Deletes bgp application peer.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary
    ...    IP=127.0.0.12
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated
    ...    ${BGP_VAR_FOLDER}/application_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Delete_Bgp_Peer_Configuration_5
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV4_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_5
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Stop_All_Exabgps_2
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP2_LOG}    ${EXABGP2_LOG}
    ExaBgpLib.Stop_ExaBgp
    ${Log_Content}    OperatingSystem.Get File    ${EXABGP2_LOG}
    Log    ${Log_Content}

Reconfigure_ODL_To_Accept_Connections_6
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/graceful_restart
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Start_Exabgp_3
    [Documentation]    Start exabgp with
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP3_CFG} > ${EXABGP3_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Stop_All_Exabgps_3
    [Documentation]    Save exabgp logs as exabgp_graceful_restart.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP3_LOG}    ${EXABGP3_LOG}
    ExaBgpLib.Stop_ExaBgp
    Sleep    40s
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${True}

Start_Exabgp_4
    [Documentation]    Start exabgp with
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP3_CFG} > ${EXABGP3_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Delete_Bgp_Peer_Configuration_6
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated
    ...    ${BGP_VAR_FOLDER}/graceful_restart
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Stop_All_Exabgps_4
    [Documentation]    Save exabgp logs as exabgp_graceful_restart.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP3_LOG}    ${EXABGP3_LOG}
    ExaBgpLib.Stop_ExaBgp

Reconfigure_ODL_To_Accept_Connections_7
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    [Tags]    exclude
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Start_Exabgp_5
    [Documentation]    Start exabgp with
    [Tags]    exclude
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP4_CFG} > ${EXABGP4_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Delete_Bgp_Peer_Configuration_7
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Tags]    exclude
    &{mapping}    Create Dictionary
    ...    IP=${IPV6_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Stop_All_Exabgps_5
    [Documentation]    Save exabgp logs as exabgp_graceful_restart.log, and stop exabgp with ctrl-c bash signal
    [Tags]    exclude
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP4_LOG}    ${EXABGP4_LOG}
    ExaBgpLib.Stop_ExaBgp


*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    Configure_Ipv6_Network
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    setuptools==44.0.0
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.2.4
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Upload_Config_Files_exabgp_ipv4
    Upload_Config_Files_exabgp_graceful_restart
    Upload_Config_Files_Exabgp_AS_Value_Reconfigured

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions
    BuiltIn.Run Keyword And Ignore Error    ExaBgpLib.Stop_ExaBgp

Configure_Ipv6_Network
    [Documentation]    Reconfigures basic network settings on controller
    ${main_net_interface}=    SSHLibrary.Execute_Command    ip route | grep '^default' | awk '{print $5}'
    SSHLibrary.Execute_Command    sudo ip -6 addr add ${IPV6_IP}/${IPV6_PREFIX_LENGTH} dev ${main_net_interface}
    SSHLibrary.Execute_Command    sudo ip -6 route add default via ${IPV6_IP_GW}
    ${stdout}    SSHLibrary.Execute_Command    sudo ip -6 addr show
    Log    ${stdout}
    ${stdout}    SSHLibrary.Execute_Command    sudo ip -6 route show
    Log    ${stdout}

Verify_Rib_Status_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    5x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_topology_empty
    ...    session=${CONFIG_SESSION}
    ...    verify=True

Verify_Rib_Status_Filled
    [Documentation]    Verifies that example-ipv6-topology is filled with ipv6 route
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    5x
    ...    2s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    ${BGP_VAR_FOLDER}/ipv6_topology_filled
    ...    session=${CONFIG_SESSION}
    ...    verify=True

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP_CFG}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${IPV6_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${CONTROLLER_IPV6}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/${EXABGP_ID}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Upload_Config_Files_exabgp_ipv4
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP2_CFG}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *ipv4.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/127.0.0.1/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/127.0.0.1/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Upload_Config_Files_exabgp_graceful_restart
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP3_CFG}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *restart.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${IPV6_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${CONTROLLER_IPV6}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/${EXABGP_ID}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Upload_Config_Files_Exabgp_AS_Value_Reconfigured
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP4_CFG}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *exa4.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${IPV6_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${CONTROLLER_IPV6}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/${EXABGP_ID}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END
