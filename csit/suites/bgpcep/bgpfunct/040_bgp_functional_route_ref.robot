*** Settings ***
Documentation       Functional test for bgp - route refresh
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...                 This suite tests sending and receiveing route refresh message.
...                 It uses odl and exabgp as bgp peers.
...                 Sending route refresh message from odl is initiated via restconf.
...                 If route refresh is received by odl, correct advertising of routes
...                 is verified. Receiving of route refresh by odl is verified by
...                 checking appropriate message counter via odl-bgpcep-bgp-cli and
...                 restconf using BGP neighbor operational state

Library             RequestsLibrary
Library             SSHLibrary
Library             String
Library             ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource            ../../../libraries/CompareStream.robot
Resource            ../../../libraries/ExaBgpLib.robot
Resource            ../../../libraries/KarafKeywords.robot
Resource            ../../../libraries/SetupUtils.robot
Resource            ../../../libraries/SSHKeywords.robot
Resource            ../../../libraries/TemplatedRequests.robot
Resource            ../../../variables/Variables.robot

Suite Setup         Start_Suite
Suite Teardown      Stop_Suite
Test Setup          SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing


*** Variables ***
${APP_PEER_NAME}            example-bgp-peer-app
${BGP_CFG_NAME}             exa.cfg
${BGP_PEER_NAME}            example-bgp-peer
${BGP_RR_VAR_FOLDER}        ${BGP_VAR_FOLDER}/route_refresh
${BGP_VAR_FOLDER}           ${CURDIR}/../../../variables/bgpfunctional
${CONFIG_SESSION}           config-session
${DEVICE_NAME}              controller-config
${EXARPCSCRIPT}             ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${HOLDTIME}                 180
${PROTOCOL_OPENCONFIG}      ${RIB_INSTANCE}
${RIB_INSTANCE}             example-bgp-rib
${MSG_STATE_OFFSET}         24


*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    &{mapping}    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    APP_PEER_NAME=${APP_PEER_NAME}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    APP_PEER_ID=${ODL_SYSTEM_IP}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/app_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    BGP_NAME=${BGP_PEER_NAME}
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    HOLDTIME=${HOLDTIME}
    ...    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    ...    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/bgp_peer
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}

Exa_To_Send_Route_Refresh
    [Documentation]    Exabgp sends route refresh and count received updates
    [Tags]    critical
    [Setup]    Configure_Routes_And_Start_ExaBgp    ${BGP_CFG_NAME}
    BgpRpcClient.exa_clean_received_update_count
    BgpRpcClient.exa_announce    announce route-refresh ipv4 unicast
    Comment    From neon onwards there are extra BGP End-Of-RIB message
    ${update_count}    BuiltIn.Set_Variable    3
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_ExaBgp_Received_Updates    ${update_count}
    Comment    From neon onwards there are extra BGP End-Of-RIB message per address family
    ${update_count}    BuiltIn.Set_Variable    7
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    5s
    ...    Verify_Odl_Operational_State_Count
    ...    notification_count=0
    ...    update_count=${update_count}
    ...    receive_count=2
    [Teardown]    Deconfigure_Routes_And_Stop_ExaBgp

Odl_To_Send_Route_Refresh
    [Documentation]    Sends route refresh request and checks if exabgp receives it
    [Tags]    critical
    [Setup]    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${BGP_CFG_NAME}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}
    BgpRpcClient.exa_clean_received_route_refresh_count
    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated
    ...    ${BGP_VAR_FOLDER}/route_refresh
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_ExaBgp_Received_Route_Refresh    1
    Comment    From neon onwards there are extra BGP End-Of-RIB message per address family
    ${update_count}    BuiltIn.Set_Variable    9
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    5s
    ...    Verify_Odl_Operational_State_Count
    ...    notification_count=1
    ...    update_count=${update_count}
    ...    receive_count=4
    [Teardown]    ExaBgpLib.Stop_ExaBgp

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    BGP_NAME=${BGP_PEER_NAME}
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary
    ...    DEVICE_NAME=${DEVICE_NAME}
    ...    APP_PEER_NAME=${APP_PEER_NAME}
    ...    IP=${ODL_SYSTEM_IP}
    ...    BGP_RIB_OPENCONFIG=${PROTOCOL_OPENCONFIG}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}


*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}    SSHLibrary.Open Connection
    ...    ${TOOLS_SYSTEM_IP}
    ...    prompt=${DEFAULT_LINUX_PROMPT}
    ...    timeout=6s
    Builtin.Set_Suite_Variable    ${mininet_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    setuptools==44.0.0
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${BGP_CFG_NAME}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Configure_Routes_And_Start_ExaBgp
    [Documentation]    Setup keyword for exa to odl test case
    [Arguments]    ${cfg_file}
    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
    FOR    ${prefix}    IN    1.1.1.1/32    2.2.2.2/32
        &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}    APP_RIB=${app_rib}
        TemplatedRequests.Post_As_Xml_Templated
        ...    ${BGP_RR_VAR_FOLDER}/route
        ...    mapping=${mapping}
        ...    session=${CONFIG_SESSION}
    END
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cfg_file}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}
    Comment    From neon onwards there are extra BGP End-Of-RIB message per address family
    ${update_count}    BuiltIn.Set_Variable    4
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_ExaBgp_Received_Updates    ${update_count}

Deconfigure_Routes_And_Stop_ExaBgp
    [Documentation]    Teardown keyword for exa to odl test case
    ExaBgpLib.Stop_ExaBgp
    ${app_rib}    Set Variable    ${ODL_SYSTEM_IP}
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}    APP_RIB=${app_rib}
    TemplatedRequests.Delete_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_ExaBgp_Received_Updates
    [Documentation]    Gets number of received update requests and compares with given expected count
    [Arguments]    ${expcount}
    ${count_recv}    BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should Be Equal As Numbers    ${count_recv}    ${expcount}

Verify_ExaBgp_Received_Route_Refresh
    [Documentation]    Compares expected count of route request messages on exabgp side
    [Arguments]    ${expcount}
    ${count}    BgpRpcClient.exa_get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers    ${count}    ${expcount}

Verify_Odl_Operational_State_Count
    [Documentation]    Check notification and update count gained from operatial neighbor state
    ...    On versions oxygen and above, it verifies these counts also against cli output.
    [Arguments]    ${notification_count}    ${update_count}    ${receive_count}
    &{mapping}    BuiltIn.Create_Dictionary
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    ...    NOT_COUNT=${notification_count}
    ...    SEND_COUNT=${update_count}
    ...    RECV_COUNT=${receive_count}
    ${ret}    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    5s
    ...    TemplatedRequests.Get_As_Json_Templated
    ...    folder=${BGP_RR_VAR_FOLDER}/operational_state
    ...    mapping=${mapping}
    ...    session=${CONFIG_SESSION}
    ...    verify=True
    BuiltIn.Log    ${ret}
    BuiltIn.Wait_Until_Keyword_Succeeds
    ...    3x
    ...    5s
    ...    Verify_Cli_Output_Count
    ...    ${notification_count}
    ...    ${update_count}
    ...    ${receive_count}

Verify_Cli_Output_Count
    [Documentation]    Checks notification and update count from odl-bgpcep-bgp-cli.
    ...    odl-bgpcep-bgp-cli is only avaiable on versions oxygen and above.
    [Arguments]    ${notification_count}    ${update_count}    ${receive_count}
    ${output}    KarafKeywords.Safe_Issue_Command_On_Karaf_Console
    ...    bgp:operational-state -rib example-bgp-rib -neighbor ${TOOLS_SYSTEM_IP}
    BuiltIn.Log    ${output}
    &{mapping}    BuiltIn.Create_Dictionary
    ...    IP=${TOOLS_SYSTEM_IP}
    ...    NOT_COUNT=${notification_count}
    ...    SEND_COUNT=${update_count}
    ...    DIVIDER=│
    ...    RECV_COUNT=${receive_count}
    ${expstate}    TemplatedRequests.Resolve_Text_From_Template_File
    ...    folder=${BGP_RR_VAR_FOLDER}/operational_cli
    ...    file_name=update.txt
    ...    mapping=${mapping}
    String.Get Line Count    ${output}
    BuiltIn.Log    ${expstate}
    ${expected_line_count}    String.Get Line Count    ${expstate}
    FOR    ${expected_line_pos}    IN RANGE    0    ${expected_line_count-1}
        ${expected_line_offset}    BuiltIn.Evaluate    ${MSG_STATE_OFFSET} + ${expected_line_pos}
        ${output_line}    String.Get Line    ${output}    ${expected_line_offset}
        ${expected_line}    String.Get Line    ${expstate}    ${expected_line_pos}
        BuiltIn.Should Match    ${output_line}    ${expected_line}
    END
