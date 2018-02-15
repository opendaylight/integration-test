*** Settings ***
Documentation     Functional test for bgp routing policies
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite uses 7 peers: app peer, 2x rr-client, 2x ebgp, 2x ibgp
...               Tests results on full RIB
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
#Resource          ../../../libraries/CompareStream.robot
#Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${EXABGP_KILL_COMMAND}    ps axf | grep exabgp | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${POLICIES_VAR}    ${CURDIR}/../../../variables/bgppolicies
${CMD}    env exabgp.tcp.port=1790 exabgp --debug
${FIRST_PEER_IP}    127.0.0.1
${MULTIPLICITY}    6
@{PEER_TYPES}    ibgp_peer    ibgp_peer    ebgp_peer    ebgp_peer    rr_client_peer    rr_client_peer
@{NUMBERS}    1    2    3    4    5    6
${OPENCONFIG_RIB_URI}    /restconf/config/openconfig-network-instance:network-instances/network-instance/global-bgp/openconfig-network-instance:protocols/protocol/openconfig-policy-types:BGP/example-bgp-rib
${HOLDTIME}       180
#${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${BGP_RR_VAR_FOLDER}    ${BGP_VAR_FOLDER}/route_refresh
#${BGP_CFG_NAME}    exa.cfg
${CONFIG_SESSION}    config-session
#${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    &{mapping}    BuiltIn.Create_Dictionary    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ...    IP=${ODL_SYSTEM_IP}    AMOUNT=0
    #TemplatedRequests.Put_As_Xml_Templated    ${POLICIES_VAR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    #TemplatedRequests.Post_As_Xml_Templated    ${POLICIES_VAR}/app_peer_route    mapping=${mapping}    session=${CONFIG_SESSION}
    TemplatedRequests.Put_As_Xml_Templated    ${POLICIES_VAR}/pathselection    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connections
    [Documentation]    Configure BGP peer modules with initiate-connection set to false.
    : FOR    ${index}    ${peer_type}    IN ZIP    ${NUMBERS}    ${PEER_TYPES}
    \    ${peer_name} =    BuiltIn.Set_Variable    ${BGP_PEER_NAME}-${index}
#    \    ${peer_ip} =    BuiltIn.Evaluate    str(ipaddr.IPAddress('${FIRST_PEER_IP}') + ${index} - 1)    modules=ipaddr
    \    &{mapping}    Create Dictionary    BGP_NAME=${peer_name}    IP=127.0.0.${index}    HOLDTIME=${HOLDTIME}
    \    ...    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false    BGP_RIB=${RIB_INSTANCE}    PASSIVE_MODE=true    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    \    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    \    TemplatedRequests.Put_As_Xml_Templated    ${POLICIES_VAR}/allpath/${peer_type}    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Exabgps
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    : FOR    ${index}    IN    ${NUMBERS}
    \    ${start_cmd}    BuiltIn.Set_Variable    ${CMD} exabgp${index}.cfg > exa${index}_allpath.log &
    \    BuiltIn.Log    ${start_cmd}
    \    ${output}    SSHLibrary.Write    ${start_cmd}
    \    BuiltIn.Log    ${output}

Verify_Rib_Status
    BuiltIn.Sleep    10s
    ${output}    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    #${output}    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/topology_state    session=${CONFIG_SESSION}
    #BuiltIn.Log    ${output}
    ${output}    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/rib_state    session=${CONFIG_SESSION}
    BuiltIn.Log    ${output}


Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    : FOR    ${index}    ${peer_type}    IN ZIP    ${NUMBERS}    ${PEER_TYPES}
    \    &{mapping}    BuiltIn.Create_Dictionary    BGP_NAME=${BGP_PEER_NAME}    IP=127.0.0.${index}    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    \    TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/allpath/${peer_type}    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    APP_PEER_NAME=${APP_PEER_NAME}    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    AMOUNT=0
    #TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    #TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/app_peer_route    mapping=${mapping}    session=${CONFIG_SESSION}
    #TemplatedRequests.Delete_Templated    ${POLICIES_VAR}/pathselection    mapping=${mapping}    session=${CONFIG_SESSION}

Stop_All_Peers
    [Documentation]    Send command to kill all exabgp processes running on controller
    ExaBgpLib.Stop_All_ExaBgps
    : FOR    ${index}    IN    ${NUMBERS}
    \    BGPcliKeywords.Store_File_To_Workspace    exa${index}_allpath.log    exa${index}_allpath.log

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${conn_id}=    SSHLibrary.Open Connection    ${ODL_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=10s
    Builtin.Set_Suite_Variable    ${conn_id}
    SSHKeywords.Flexible_Controller_Login
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    Store_Rib_Configuration

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    TemplatedRequests.Put_As_Xml_To_Uri    ${OPENCONFIG_RIB_URI}    ${rib_old}    session=${CONFIG_SESSION}
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Store_Rib_Configuration
    [Documentation]    Stores rib configuration
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}
    ${rib_old}=    TemplatedRequests.Get_As_Xml_Templated    ${POLICIES_VAR}/pathselection    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Set_Suite_Variable    ${rib_old}

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    : FOR    ${index}    IN    ${NUMBERS}
    \    SSHLibrary.Put_File    ${POLICIES_VAR}/exabgp_configs/exabgp${index}.cfg    .
    #SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    #\    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/send\\/receive/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}
