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
...               Enable V4 only on controller, Enable V4 on the router, Insert v6 route on the controller
...               BGP session should not go down
...               inserted ipv6 prefix should not be present in http://\controller-ip:restconf-port/restconf/operational/bgp-rib:bgp-rib
...               catch exceptions in karaf.log
...               Enable V4+V6 on controller, Enable V4 on the router, insert v6 route on the controller
...               BGP session should not go down
...               inserted ipv6 prefix should not be present in adjrib-out of peer in http://\controller-ip:restconf-port/restconf/operational/bgp-rib:bgp-rib
...               catch exceptions in karaf.log
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot

*** Variables ***
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/ipv6
${CONFIG_SESSION}    config-session
${CONTROLLER_IPV6}    ::1
${EXABGP_ID}      1.2.3.4
${EXABGP_ID_2}    127.0.0.1
${EXABGP_CFG}     exaipv6.cfg
${EXABGP_LOG}     exaipv6.log
${EXABGP2_CFG}    exaipv4.cfg
${EXABGP2_LOG}    exaipv4.log
${IPV4_IP}        127.0.0.1
${CONTROLLER_IPV4}    ${ODL_SYSTEM_IP}
${IPV6_IP}        2607:f0d0:1002:0011:0000:0000:0000:0002
${IPV6_IP_2}      2607:f0d0:1002:11:0:0:0:2
${IPV6_IP_3}      2607:f0d0:1002:11::2
${IPV6_IP_GW}     2607:f0d0:1002:0011:0000:0000:0000:0001
${HOLDTIME}       180
${RIB_INSTANCE}    example-bgp-rib
${filter_string}    CEASE
@{message_list}    CEASE

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

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
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_2
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with ipv6 address without "::" shortened version.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_2
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_2
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_2
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_3
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with full text ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Filled_3
    [Documentation]    Verifies that example-ipv6-topology is filled after configuring the peer for the third time.
    [Tags]    critical
    Verify_Rib_Status_Filled

Delete_Bgp_Peer_Configuration_3
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_3
    [Documentation]    Verifies that example-ipv6-topology is empty after final deconfiguration.
    [Tags]    critical
    Verify_Rib_Status_Empty

Stop_All_Exabgps
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP_LOG}    ${EXABGP_LOG}
    ExaBgpLib.Stop_ExaBgp

Reconfigure_ODL_To_Accept_Connections_4
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV4_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/rib_state    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgp_2
    [Documentation]    Start exabgp and Verify BGP connection
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP2_CFG} > ${EXABGP2_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    127.0.0.1

Inject_Ipv6_Route_1
    [Documentation]    Inject the Ipv6 route from controller
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6_route_injection    mapping=${mapping}    session=${CONFIG_SESSION}

Check_Ipv6_Prefix_In_Bgp_Rib_1
    [Documentation]    Check for the presence of Ipv6 Prefix in the BGP RIB
    &{mapping}    Create Dictionary    IP=${CONTROLLER_IPV4}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/bgp_rib    session=${CONFIG_SESSION}    mapping=${mapping}

Karaf_Log_Exceptions_Checks_1
    [Documentation]    Check for Exceptions in the karaf log
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${False}

Delete_Bgp_Peer_Configuration_4
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV4_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/rib_state    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6_route_injection    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_4
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Reconfigure_ODL_To_Accept_Connections_5
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV4_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/rib_state    mapping=${mapping}    session=${CONFIG_SESSION}

Inject_Ipv6_Route_2
    [Documentation]    Inject the Ipv6 route from controller
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6_route_injection    mapping=${mapping}    session=${CONFIG_SESSION}

Check_Ipv6_Prefix_In_Bgp_Rib_2
    [Documentation]    Check for the presence of Ipv6 Prefix in the BGP RIB
    &{mapping}    Create Dictionary    IP=${CONTROLLER_IPV4}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/bgp_rib    session=${CONFIG_SESSION}    mapping=${mapping}

Karaf_Log_Exceptions_Checks_2
    [Documentation]    Check for Exceptions in the karaf log
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${False}

Delete_Bgp_Peer_Configuration_delete_ipv6_route_injected
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV4_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/rib_state    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_5
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the first time.
    [Tags]    critical
    Verify_Rib_Status_Empty

Stop_All_Exabgps_2
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP2_LOG}    ${EXABGP2_LOG}
    ExaBgpLib.Stop_ExaBgp

Reconfigure_ODL_To_Accept_Connections_6
    [Documentation]    Configure BGP peer modules with initiate-connection set to false with short ipv6 address.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/graceful_restart    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgp_3
    [Documentation]    Start exabgp with
    [Tags]    critical
    ${cmd}    BuiltIn.Set_Variable    ${EXABGP_CFG} > ${EXABGP_LOG}
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Stop_All_Exabgps_3
    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP_LOG}    ${EXABGP_LOG}
    ExaBgpLib.Stop_ExaBgp
    Sleep    40s

Karaf_Log_Exceptions_Checks_3
    [Documentation]    Check for Exceptions in the karaf log
    KarafKeywords.Fail If Exceptions Found During Test    ${SUITE_NAME}.${TEST_NAME}    fail=${False}
    #KarafKeywords.Check Karaf Log Has Messages    ${filter_string}    @{message_list}
#Start_Exabgp_4
#    [Documentation]    Start exabgp with
#    [Tags]    critical
#    ${cmd}    BuiltIn.Set_Variable    ${EXABGP_CFG} > ${EXABGP_LOG}
#    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cmd}    ${CONFIG_SESSION}    ${EXABGP_ID}

Delete_Bgp_Peer_Configuration_5
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    ...    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/graceful_restart    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology_Empty_6
    [Documentation]    Verifies that example-ipv6-topology is empty after deconfiguring peer for the second time.
    [Tags]    critical
    Verify_Rib_Status_Empty
#Stop_All_Exabgps_4
#    [Documentation]    Save exabgp logs as exaipv6.log, and stop exabgp with ctrl-c bash signal
#    BGPcliKeywords.Store_File_To_Workspace    ${EXABGP_LOG}    ${EXABGP_LOG}
#    ExaBgpLib.Stop_ExaBgp

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    Configure_Ipv6_Network
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    setuptools==44.0.0
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Upload_Config_Files_exabgp_ipv4

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Configure_Ipv6_Network
    [Documentation]    Reconfigures basic network settings on controller
    SSHLibrary.Execute_Command    sudo sh -c 'echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6ADDR=${IPV6_IP}" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    SSHLibrary.Execute_Command    sudo sh -c 'echo "IPV6_DEFAULTGW=${IPV6_IP_GW}" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    SSHLibrary.Execute_Command    sudo /etc/init.d/network restart

Verify_Rib_Status_Empty
    [Documentation]    Verifies that example-ipv6-topology is empty
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6_topology_empty    session=${CONFIG_SESSION}    verify=True

Verify_Rib_Status_Filled
    [Documentation]    Verifies that example-ipv6-topology is filled with ipv6 route
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6_topology_filled    session=${CONFIG_SESSION}    verify=True

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP_CFG}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${IPV6_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${CONTROLLER_IPV6}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/${EXABGP_ID}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Upload_Config_Files_exabgp_ipv4
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${EXABGP2_CFG}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *ipv4.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/127.0.0.1/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTERID/127.0.0.1/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END
