*** Settings ***
Documentation     Functional test for ipv6 connection with bgp.
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests simple connection between one ibgp peer (exabgp) and Odl.
...               Peer is configured with ipv6, and exabgp connectes to odl via ipv6.
...               Exabgp sends one ipv6 unicast route, which presence is verified in
...               example-ipv6-topology. Tests this connection multiple times, with
...               different ipv6 accepted formats, e.g. (::1, 0:0:0:0:0:0:0:1, full text)
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/BGPcliKeywords.robot

*** Variables ***
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${HOLDTIME}       180
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${CONFIG_SESSION}    config-session
${CONTROLLER_IPV6}    ::1
${IPV6_IP}        2607:f0d0:1002:11::2
${IPV6_IP_2}      2607:f0d0:1002:11:0:0:0:2
${IPV6_IP_3}      2607:f0d0:1002:0011:0000:0000:0000:0002

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgp
    [Documentation]    Start exabgp with
    ${start_cmd}    BuiltIn.Set_Variable    ${CMD} exaipv6.cfg > exaipv6.log
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}    SSHKeywords.Execute_Command_Passes    ${start_cmd}
    BuiltIn.Log    ${output}

Verify_Ipv6_Topology_Filled
    [Documentation]    Verifies that example-ipv6-topology is filled after starting exabgp.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_2
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with ipv6 address without "::" shortened version.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_2
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_2
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_2
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_3
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with full text ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_3
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the third time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_3
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_3
    [Documentation]    Verifies that example-ipv6-topology is empty after final deconfiguration.
    [Tags]    critical
    Verify_Rib_Status_Empty

Stop_All_Exabgps
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    exaipv6.log    exaipv6.log
    ExaBgpLib.Stop_ExaBgp

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    Configure_Ipv6_Network
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Configure_Ipv6_Network
    [Documentation]    Reconfigures basic network settings on controller
    SSHLibrary.Execute_Command    sudo sh -c 'echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6ADDR=2607:f0d0:1002:0011:0000:0000:0000:0002" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6_DEFAULTGW=2607:f0d0:1002:0011:0000:0000:0000:0001" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    ${output}    SSHLibrary.Execute_Command    sudo /etc/init.d/network restart
    BuiltIn.Log    ${output}

Verify_Rib_Status_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6/ipv6_topology_empty    session=${CONFIG_SESSION}    verify=True

Verify_Rib_Status_Filled
    [Documentation]    Verifies that example-ipv6-topology is filled with ipv6 route
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6/ipv6_topology_filled    session=${CONFIG_SESSION}    verify=True

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/exaipv6.cfg    .
    #SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${IPV6_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${CONTROLLER_IPV6}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}
