*** Settings ***
Documentation     Functional test for bgp routing policies
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
#Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${EXABGP_KILL_COMMAND}    ps axf | grep exabgp | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${POLICIES_VAR}    ${CURDIR}/../../../variables/bgppolicies
${CMD}    env exabgp.tcp.port=1790 exabgp --debug
${FIRST_PEER_IP}    127.0.0.1
${MULTIPLICITY}    6
@{PEER_TYPES}    ibgp_peer    ibgp_peer    ebgp_peer    ebgp_peer    rr_client_peer    rr_client_peer
@{NUMBERS}    1    2    3    4    5    6

${HOLDTIME}       180
#${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
#${BGP_RR_VAR_FOLDER}    ${BGP_VAR_FOLDER}/route_refresh
#${BGP_CFG_NAME}    exa.cfg
${CONFIG_SESSION}    config-session
#${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${IPV6_IP}    2607:f0d0:1002:11:0:0:0:2
${IPV6_IP_2}    2607:f0d0:1002:11::2
${IPV6_IP_3}    2607:f0d0:1002:0011:0000:0000:0000:0002

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgp
    ${start_cmd}    BuiltIn.Set_Variable    ${CMD} exaipv6.cfg > exa1.log
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Verify_Ipv6_Topology
    Verify_Rib_Status

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology2
    Verify_Rib_Status

Reconfigure_ODL_To_Accept_Connections2
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology3
    Verify_Rib_Status

Delete_Bgp_Peer_Configuration2
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_2}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology4
    Verify_Rib_Status

Reconfigure_ODL_To_Accept_Connections3
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology5
    Verify_Rib_Status

Delete_Bgp_Peer_Configuratio3
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    Create Dictionary    IP=${IPV6_IP_3}    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/ipv6/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Ipv6_Topology6
    Verify_Rib_Status

Stop_All_Exabgps
    Run Keyword And Ignore Error    BGPcliKeywords.Store_File_To_Workspace    exa1.log    exa1.log
    ExaBgpLib.Stop_ExaBgp

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    ${output}    SSHLibrary.Write    ip addr show
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    cat /etc/sysconfig/network-scripts/ifcfg-eth0
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    sudo sh -c 'echo "NETWORKING_IPV6=yes" >> /etc/sysconfig/network'
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    sudo sh -c 'echo "IPV6INIT=yes" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
#    ${output}    SSHLibrary.Write    sudo sh -c 'echo "IPV6ADDR=1234::1" >> /etc/sysconfig/network-scripts/ifcfg-lo'
#    BuiltIn.Log    ${output}
#    ${stdout}    SSHLibrary.Read_Until_Prompt
#    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    sudo sh -c 'echo "IPV6ADDR=2607:f0d0:1002:0011:0000:0000:0000:0002" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    sudo sh -c 'echo "IPV6_DEFAULTGW=2607:f0d0:1002:0011:0000:0000:0000:0001" >> /etc/sysconfig/network-scripts/ifcfg-eth0'
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    sudo /etc/init.d/network restart
    BuiltIn.Log    ${output}
    BuiltIn.Sleep    30s
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    cat /etc/sysconfig/network-scripts/ifcfg-eth0
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    cat /etc/sysconfig/network-scripts/ifcfg-lo
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    cat /etc/sysconfig/network
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    ${output}    SSHLibrary.Write    netstat -pnatu
    BuiltIn.Log    ${output}
    ${stdout}    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${stdout}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Verify_Rib_Status
    BuiltIn.Sleep    10s
    ${output}    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    ${output}    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6/rib_state    session=${CONFIG_SESSION}
    BuiltIn.Log    ${output}
    ${output}    TemplatedRequests.Get_As_Json_Templated    ${BGP_VAR_FOLDER}/ipv6/ipv6_topology    session=${CONFIG_SESSION}
    #...    verify=True
    BuiltIn.Log    ${output}

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/exaipv6.cfg    .
    #SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    #\    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}
