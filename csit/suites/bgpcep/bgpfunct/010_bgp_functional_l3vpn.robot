*** Settings ***
Documentation     Functional test suite for bgp - l3vpn-ipv4
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests advertising and receiveing routes with l3vpn content.
...               It uses odl and exabgp as bgp peers. Routes advertized from odl
...               are configured via application peer. Routes advertised from exabgp is
...               statically configured in exabgp config file.
...
...               For fluorine and further, instead of exabgp, play.py is used. When sending
...               routes from odl to peer, first route containg route-target argument have to
...               be send from peer to odl, so odl can identify this peer. Than it sends l3vpn
...               route containg this argument to odl app peer, and we check that app peer
...               advertizes this route back to the peer.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BgpOperations.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/ExaBgpLib.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${BGP_L3VPN_DIR}    ${BGP_VAR_FOLDER}/l3vpn_ipv4
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${CONFIG_SESSION}    config-session
${DEFAULT_BGPCEP_LOG_LEVEL}    INFO
${DEFAULT_EXA_CFG}    exa.cfg
${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${HOLDTIME}       180
${L3VPN_EXA_CFG}    bgp-l3vpn-ipv4.cfg
${L3VPN_EXP}      exa_expected
${L3VPN_RSP}      bgp_l3vpn_ipv4
${L3VPN_RSPEMPTY}    bgp_l3vpn_ipv4_empty
${L3VPN_RSP_PATH}    bgp_l3vpn_ipv4_path
${OLD_AS_PATH}    \n"as-path": {},
${NEW_AS_PATH}    ${EMPTY}
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_INSTANCE}    example-bgp-rib
${RT_CONSTRAIN_DIR}    ${CURDIR}/../../../variables/bgpfunctional/rt_constrain

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    &{mapping}    BuiltIn.Create_Dictionary    BGP_RIB=${RIB_INSTANCE}    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB=${RIB_INSTANCE}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}    INITIATE=false
    ...    BGP_RIB_OPENCONFIG=${RIB_INSTANCE}    PASSIVE_MODE=true
    CompareStream.Run_Keyword_If_At_Least_Fluorine    TemplatedRequests.Put_As_Xml_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

L3vpn_Ipv4_To_Odl
    [Documentation]    Testing mpls vpn ipv4 routes reported to odl from exabgp
    [Setup]    Setup_Testcase    ${L3VPN_EXA_CFG}
    ${L3VPN_RESPONSE}    CompareStream.Set_Variable_If_At_Least_Fluorine    ${L3VPN_RSP_PATH}    ${L3VPN_RSP}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    1s    Verify_Reported_Data    ${L3VPN_RESPONSE}
    [Teardown]    Teardown_Simple

Start_Play
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    "Only run on Fluorine and later"
    SSHLibrary.Put_File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    SSHLibrary.Read
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start_Bgp_Peer

Play_To_Odl_rt_constrain_type_0
    [Documentation]    This keyword sends route-target route containg route-target argument so odl
    ...    can identify this peer as appropriate for advertizement when it recieves such route.
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    "Only run on Fluorine and later"
    BgpOperations.Play_To_Odl_Non_Removal_Template    rt_constrain_type_0    ${RT_CONSTRAIN_DIR}

Odl_To_Play_l3vpn
    [Documentation]    Send l3vpn route to app peer, and than checks that app peer advertizes this route.
    CompareStream.Run_Keyword_If_At_Least_Fluorine    BuiltIn.Pass_Execution    "Only run on less than Fluorine"
    Setup_Testcase    ${DEFAULT_EXA_CFG}
    L3vpn_Ipv4_To_App
    [Teardown]    CompareStream.Run_Keyword_If_Less_Than_Fluorine    Teardowm_With_Remove_Route

Odl_To_Play_l3vpn_rt_arg
    [Documentation]    Same as TC before but fluorine and further this l3vpn route also needs to contain route-target argument.
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    "Only run on Fluorine and later"
    BgpOperations.Odl_To_Play_Template    l3vpn_rt_arg    ${RT_CONSTRAIN_DIR}    False

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    CompareStream.Run_Keyword_If_Less_Than_Fluorine    BuiltIn.Pass_Execution    "Only run on Fluorine and later"
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    010_l3vpn_play.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${RT_CONSTRAIN_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${RT_CONSTRAIN_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id} =    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    SSHKeywords.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    setuptools==44.0.0
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    ${AS_PATH} =    CompareStream.Set_Variable_If_At_Least_Neon    ${NEW_AS_PATH}    ${OLD_AS_PATH}
    BuiltIn.Set_Suite_Variable    ${AS_PATH}

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Documentation]    Uploads exabgp config files and needed scripts
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${DEFAULT_EXA_CFG}    .
    SSHLibrary.Put_File    ${BGP_L3VPN_DIR}/${L3VPN_EXA_CFG}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END

Setup_Testcase
    [Arguments]    ${cfg_file}
    [Documentation]    Verifies initial test condition and starts the exabgp
    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Verify_Empty_Reported_Data
    ExaBgpLib.Start_ExaBgp_And_Verify_Connected    ${cfg_file}    ${CONFIG_SESSION}    ${TOOLS_SYSTEM_IP}    connection_retries=${3}

Teardowm_With_Remove_Route
    [Documentation]    Removes configured route from application peer and stops the exabgp
    &{mapping}    BuiltIn.Create_Dictionary    APP_PEER_IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Delete_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    Teardown_Simple

Teardown_Simple
    [Documentation]    Testcse teardown with data verification
    ExaBgpLib.Stop_ExaBgp
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Verify_Empty_Reported_Data

Verify_ExaBgp_Received_Update
    [Arguments]    ${exp_update_fn}
    [Documentation]    Verification of receiving particular update message
    ${exp_update} =    TemplatedRequests.Resolve_Text_From_Template_File    ${BGP_L3VPN_DIR}${/}${exp_update_fn}    data.json
    ${rcv_update_dict} =    BgpRpcClient.exa_get_update_message    msg_only=${True}
    ${rcv_update} =    BuiltIn.Evaluate    json.dumps(${rcv_update_dict})    modules=json
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp_update}    ${rcv_update}

Verify_Empty_Reported_Data
    [Documentation]    Verfiy empty data response
    CompareStream.Run_Keyword_If_At_Most_Fluorine    TemplatedRequests.Get_As_Json_Templated    ${BGP_L3VPN_DIR}${/}${L3VPN_RSPEMPTY}    session=${CONFIG_SESSION}    verify=True
    CompareStream.Run_Keyword_If_At_Least_Neon    Verify_Empty_Data_Neon

Verify_Reported_Data
    [Arguments]    ${exprspdir}
    [Documentation]    Verifies expected response
    &{mapping}    BuiltIn.Create_Dictionary    AS_PATH=${AS_PATH}
    TemplatedRequests.Get_As_Json_Templated    ${BGP_L3VPN_DIR}${/}${exprspdir}    mapping=${mapping}    session=${CONFIG_SESSION}    verify=True

Start_Bgp_Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --allf --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

L3vpn_Ipv4_To_App
    [Documentation]    Testing mpls vpn ipv4 routes reported to odl from exabgp
    BgpRpcClient.exa_clean_update_message
    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}    APP_PEER_IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_ExaBgp_Received_Update    ${L3VPN_EXP}

Verify_Empty_Data_Neon
    [Documentation]    Verify empty data on neon
    TemplatedRequests.Get_As_Json_Templated    ${BGP_L3VPN_DIR}${/}empty_route    session=${CONFIG_SESSION}    verify=True
