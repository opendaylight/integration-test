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
...               Tests results on RIB
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/CompareStream.robot
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${EXABGP_KILL_COMMAND}    ps axf | grep exabgp | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${POLICIES_VAR}    ${CURDIR}/../../../variables/bgppolicies

${HOLDTIME}       180
#${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${PROTOCOL_OPENCONFIG}    ${RIB_INSTANCE}
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${BGP_RR_VAR_FOLDER}    ${BGP_VAR_FOLDER}/route_refresh
#${BGP_CFG_NAME}    exa.cfg
${CONFIG_SESSION}    config-session
#${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    &{mapping}    BuiltIn.Create_Dictionary    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection_1
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_NAME=${BGP_PEER_NAME}    IP=127.0.0.2    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection_2
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_NAME=${BGP_PEER_NAME}    IP=127.0.0.3    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

#Exa_To_Send_Route_Refresh
#    [Documentation]    Exabgp sends route refresh and count received updates
#    [Setup]    Configure_Routes_And_Start_ExaBgp    ${BGP_CFG_NAME}
#    BgpRpcClient.exa_clean_received_update_count
#    BgpRpcClient.exa_announce    announce route-refresh ipv4 unicast
#    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_ExaBgp_Received_Updates    ${nr_configured_routes}
#    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    Verify_Odl_Received_Updates    ${nr_configured_routes}
#    [Teardown]    Deconfigure_Routes_And_Stop_ExaBgp

Start_Exabgps
    ExaBgpLib.Start_ExaBgp_In_Background    ${POLICIES_VAR}/exabgp1.cfg
    ExaBgpLib.Start_ExaBgp_In_Background    ${POLICIES_VAR}/exabgp2.cfg

#Odl_To_Send_Route_Refresh
#    [Documentation]    Sends route refresh request and checks if exabgp receives it
#    [Setup]    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${BGP_CFG_NAME}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}
#    BgpRpcClient.exa_clean_received_route_refresh_count
#    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
#    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/route_refresh    mapping=${mapping}    session=${CONFIG_SESSION}
#    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_ExaBgp_Received_Route_Refresh    1
#    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    Verify_Odl_Received_Route_Refresh    1
#    [Teardown]    ExaBgpLib.Stop_ExaBgp

Verify_Rib_Status
    ${status}    ${output}    Run Keyword And Ignore Error    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib
    BuiltIn.Log    ${output}
    ${output}    TemplatedRequests.Get_As_Json_Templated    ${POLICIES_VAR}/topology_state    session=${CONFIG_SESSION}
    BuiltIn.Log    ${output}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_NAME=${BGP_PEER_NAME}    IP=127.0.0.2    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    &{mapping}    BuiltIn.Create_Dictionary    BGP_NAME=${BGP_PEER_NAME}    IP=127.0.0.3    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    APP_PEER_NAME=${APP_PEER_NAME}    IP=${ODL_SYSTEM_IP}    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Stop_All_Peers
    ExaBgpLib.Stop_All_ExaBgps

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${mininet_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==4.0.5
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    ${output} =    SSHKeywords.Run_Keyword_Preserve_Connection    Utils.Run_Command_On_Controller    ${member_ip}    ${command}
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${POLICIES_VAR}/exabgp1.cfg    .
    SSHLibrary.Put_File    ${POLICIES_VAR}/exabgp2.cfg    .
    #SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

#Configure_Routes_And_Start_ExaBgp
#    [Arguments]    ${cfg_file}
#    [Documentation]    Setup keyword for exa to odl test case
#    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
#    : FOR    ${prefix}    IN    1.1.1.1/32    2.2.2.2/32
#    \    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}    APP_RIB=${app_rib}
#    \    TemplatedRequests.Post_As_Xml_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}
#    BuiltIn.Set_Suite_Variable    ${nr_configured_routes}    2
#    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cfg_file}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}
#    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_ExaBgp_Received_Updates    ${nr_configured_routes}

#Deconfigure_Routes_And_Stop_ExaBgp
#    [Documentation]    Teardown keyword for exa to odl test case
#    ExaBgpLib.Stop_ExaBgp
#    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
#    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}    APP_RIB=${app_rib}
#    TemplatedRequests.Delete_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_ExaBgp_Received_Updates
    [Arguments]    ${expcount}
    [Documentation]    Gets number of received update requests and compares with given expected count
    [Tags]    critical
    ${count_recv}=    BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should Be Equal As Numbers    ${count_recv}    ${expcount}

Verify_Odl_Received_Updates
    [Arguments]    ${expcount}
    [Documentation]    Compares sent information with given expected count using restconf
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    COUNT=${expcount}
    ${ret}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_RR_VAR_FOLDER}/operational_updates    mapping=${mapping}
    ...    session=${CONFIG_SESSION}    verify=True
    CompareStream.Run_Keyword_If_At_Least_Oxygen    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    Verify_Odl_Received_Updates_Cli    ${expcount}

Verify_Odl_Received_Updates_Cli
    [Arguments]    ${expcount}
    [Documentation]    Compares sent information with given expected count using odl-bgpcep-bgp-cli
    [Tags]    critical
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor ${TOOLS_SYSTEM_IP}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    COUNT=${expcount}
    ${expstate}    TemplatedRequests.Resolve_Text_From_Template_File    folder=${BGP_RR_VAR_FOLDER}/operational_cli/    file_name=update.txt    mapping=${mapping}
    ${expstate_ipv4}    TemplatedRequests.Resolve_Text_From_Template_File    folder=${BGP_RR_VAR_FOLDER}/operational_cli/    file_name=update_ipv4.txt    mapping=${mapping}
    BuiltIn.Should_Contain    ${output}    ${expstate}
    BuiltIn.Should_Contain    ${output}    ${expstate_ipv4}

Verify_ExaBgp_Received_Route_Refresh
    [Arguments]    ${expcount}
    [Documentation]    Compares expected count of route request messages on exabgp side
    [Tags]    critical
    ${count}=    BgpRpcClient.exa_get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers    ${count}    ${expcount}

Verify_Odl_Received_Route_Refresh
    [Arguments]    ${expcount}
    [Documentation]    Compares expected count of messages on odl using restconf
    [Tags]    critical
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    COUNT=${expcount}
    ${ret}=    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    TemplatedRequests.Get_As_Json_Templated    folder=${BGP_RR_VAR_FOLDER}/operational_route_refresh    mapping=${mapping}
    ...    session=${CONFIG_SESSION}    verify=True
    CompareStream.Run_Keyword_If_At_Least_Oxygen    BuiltIn.Wait_Until_Keyword_Succeeds    3x    5s    Verify_Odl_Received_Route_Refresh_Cli    ${expcount}

Verify_Odl_Received_Route_Refresh_Cli
    [Arguments]    ${expcount}
    [Documentation]    Compares expected count of messages on odl using odl-bgpcep-bgp-cli
    [Tags]    critical
    ${output}=    KarafKeywords.Safe_Issue_Command_On_Karaf_Console    bgp:operational-state -rib example-bgp-rib -neighbor ${TOOLS_SYSTEM_IP}
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    COUNT=${expcount}
    ${expstate}    TemplatedRequests.Resolve_Text_From_Template_File    folder=${BGP_RR_VAR_FOLDER}/operational_cli/    file_name=route_refresh.txt    mapping=${mapping}
    BuiltIn.Should_Contain    ${output}    ${expstate}
