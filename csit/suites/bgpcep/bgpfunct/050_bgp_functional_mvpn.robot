*** Settings ***
Documentation     Functional test for bgp - mvpn
...
...               Copyright (c) 2018 AT&T Intellectual Property. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distbmution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests advertising mvpn routes to odl. For advertising play.py is used,
...               and particular files are stored as *.hex files. There are 7 different
...               types of routes used for auto-discovery of multicast network.
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        Run Keywords    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
# ...               AND    Verify Test Preconditions
Library           RequestsLibrary
Library           SSHLibrary
Library           String
Library           ../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/BGPcliKeywords.robot
Resource          ../../../libraries/BGPSpeaker.robot
Resource          ../../../libraries/CompareStream.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${HOLDTIME}       180
${APP_PEER_NAME}    example-bgp-peer-app
${BGP_DIR}    ${CURDIR}/../../../variables/bgpfunctional
${CONFIG_SESSION}    config-session
${MVPN_DIR}    ${CURDIR}/../../../variables/bgpfunctional/mvpn
${PLAY_SCRIPT}    ${CURDIR}/../../../../tools/fastbgp/play.py
${RIB_NAME}    example-bgp-rib
${BGP_VARIABLES_FOLDER}
# ${SS}             ${SPACE}${SPACE}${SPACE}${SPACE}
# ${PATH_ID_JSON}    ${SS}${SS}"path-id": 0,${\n}
# ${PATH_ID_XML}    ${SS}<path-id>0</path-id>${\n}

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary       IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
    ...    IP=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${MVPN_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_NAME}    PASSIVE_MODE=true
    TemplatedRequests.Put_As_Xml_Templated    ${MVPN_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Start_Bgp_Peer
    [Documentation]    Start Python speaker to connect to ODL. We need to do WUKS until odl really starts to accept incomming bgp connection. The failure happens if the incomming connection comes too quickly after configuring the peer in the previous test case.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Start Bgp Peer

Odl_To_Play_intra_as_ipmsi_ad
    [Template]    Odl_To_Play_Template
    intra_as_ipmsi_ad

Play_To_Odl_intra_as_ipmsi_ad
    [Template]    Play_To_Odl_Template
    intra_as_ipmsi_ad

Odl_To_Play_inter_as_ipmsi_ad
    [Template]    Odl_To_Play_Template
    inter_as_ipmsi_ad

Play_To_Odl_inter_as_ipmsi_ad
    [Template]    Play_To_Odl_Template
    inter_as_ipmsi_ad

Odl_To_Play_spmsi_ad
    [Template]    Odl_To_Play_Template
    spmsi_ad

Play_To_Odl_spmsi_ad
    [Template]    Play_To_Odl_Template
    spmsi_ad

Odl_To_Play_leaf_ad
    [Template]    Odl_To_Play_Template
    leaf_ad

Play_To_Odl_leaf_ad
    [Template]    Play_To_Odl_Template
    leaf_ad

Odl_To_Play_source_active_ad
    [Template]    Odl_To_Play_Template
    source_active_ad

Play_To_Odl_source_active_ad
    [Template]    Play_To_Odl_Template
    source_active_ad

Odl_To_Play_shared_tree_join
    [Template]    Odl_To_Play_Template
    shared_tree_join

Play_To_Odl_shared_tree_join
    [Template]    Play_To_Odl_Template
    shared_tree_join

Odl_To_Play_source_tree_join
    [Template]    Odl_To_Play_Template
    source_tree_join

Play_To_Odl_source_tree_join
    [Template]    Play_To_Odl_Template
    source_tree_join

Kill_Talking_BGP_Speaker
    [Documentation]    Abort the Python speaker
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    BGPSpeaker.Kill_BGP_Speaker
    BGPcliKeywords.Store_File_To_Workspace    play.py.out    mvpn_play.log

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    IP=${TOOLS_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
    TemplatedRequests.Delete_Templated    ${MVPN_DIR}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
     [Documentation]    Revert the BGP configuration to the original state: without application peer
     [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
     &{mapping}    BuiltIn.Create_Dictionary    IP=${ODL_SYSTEM_IP}    BGP_RIB=${RIB_NAME}
     TemplatedRequests.Delete_Templated    ${MVPN_DIR}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Initialize SetupUtils. Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    SSHKeywords.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    RequestsLibrary.Create Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    SSHLibrary.Put File    ${PLAY_SCRIPT}    .
    SSHKeywords.Assure_Library_Ipaddr    target_dir=.
    BuiltIn.Set_Suite_Variable    ${MVPN_CONF_URL}    /restconf/config/bgp-rib:application-rib/${ODL_SYSTEM_IP}/tables/bgp-types:ipv4-address-family/bgp-mvpn:mcast-vpn-subsequent-address-family/bgp-mvpn-ipv4:mpvn-routes
    # BuiltIn.Set_Suite_Variable    ${MVPN_ADJ_RIB}    /restconf/operational/bgp-rib:bgp-rib/rib/${RIB_NAME}/loc-rib/tables/bgp-types:ipv4-address-family/bgp-mvpn:mcast-vpn-subsequent-address-family/bgp-mvpn-ipv4:mpvn-routes
    BuiltIn.Set_Suite_Variable    ${MVPN_ADJ_RIB}    /restconf/operational/bgp-rib:bgp-rib/rib/${RIB_NAME}/peer/bgp:%2F%2F${TOOLS_SYSTEM_IP}/adj-rib-in/tables/bgp-types:ipv4-address-family/bgp-mvpn:mcast-vpn-subsequent-address-family/bgp-mvpn-ipv4:mvpn-routes

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Start_Bgp_Peer
    [Documentation]    Starts bgp peer and verifies that the peer runs.
    BGPSpeaker.Start_BGP_Speaker    --amount 0 --myip=${TOOLS_SYSTEM_IP} --myport=${BGP_TOOL_PORT} --peerip=${ODL_SYSTEM_IP} --peerport=${ODL_BGP_PORT} --debug --mvpn --wfr 1
    BGPcliKeywords.Read_And_Fail_If_Prompt_Is_Seen

Odl_To_Play_Template
    [Arguments]    ${totest}
    ${data_xml}=    OperatingSystem.Get_File    ${MVPN_DIR}/${totest}.xml
    ${data_json}=    OperatingSystem.Get_File    ${MVPN_DIR}/${totest}.json
    ${announce_hex}=    OperatingSystem.Get_File    ${MVPN_DIR}/announce_${totest}.hex
    ${withdraw_hex}=    OperatingSystem.Get_File    ${MVPN_DIR}/withdraw_${totest}.hex
    BuiltIn.Log    ${post_data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    BgpRpcClient.play_clean
    ${resp}=    RequestsLibrary.Post_Request    ${CONFIG_SESSION}    ${MVPN_CONF_URL}    data=${data_xml}    headers=${HEADERS_XML}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    204
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_CONF_URL}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${aupdate}=    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${aupdate}
    BuiltIn.Should_Be_Equal_As_Strings    ${aupdate}    ${announce_hex}
    BgpRpcClient.play_clean
    Remove_Configured_Routes
    ${wupdate}=    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Get_Update_Content
    BuiltIn.Log    ${wupdate}
    BuiltIn.Should Be Equal As Strings    ${wupdate}    ${withdraw_hex}
    [Teardown]    Remove_Configured_Routes

Play_To_Odl_Template
    [Arguments]    ${totest}
    ${data_xml}=    OperatingSystem.Get_File    ${MVPN_DIR}/${totest}.xml
    ${data_json}=    OperatingSystem.Get_File    ${MVPN_DIR}/${totest}.json
    ${announce_hex}=    OperatingSystem.Get_File    ${MVPN_DIR}/announce_${totest}.hex
    ${withdraw_hex}=    OperatingSystem.Get_File    ${MVPN_DIR}/withdraw_${totest}.hex
    ${empty_routes}=    OperatingSystem.Get_File    ${MVPN_DIR}/empty_routes.json
    # BuiltIn.Set_Suite_Variable    ${withdraw_hex}
    # BuiltIn.Set_Suite_Variable    ${empty_routes}
    BuiltIn.Log    ${data_xml}
    BuiltIn.Log    ${data_json}
    BuiltIn.Log    ${announce_hex}
    BuiltIn.Log    ${withdraw_hex}
    # BuiltIn.Log    ${empty_routes}
    BgpRpcClient.play_clean
    BgpRpcClient.play_send    ${announce_hex}
    # BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presence
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presence    ${data_json}
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    4x    2s    Loc_Rib_Presence    ${empty_routes}
    # [Teardown]    Withdraw_Route_And_Verify    ${withdraw_hex}

Verify_Test_Preconditions
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_CONF_URL}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    404
    ${empty_routes}=    OperatingSystem.Get_File    ${MVPN_DIR}/empty_routes.json
    Loc_Rib_Presence    ${empty_routes}

Remove_Configured_Routes
    [Documentation]    Removes the route if present. First GET is for debug purposes.
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_ADJ_RIB}    headers=${HEADERS}
    Log    ${rsp.content}
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_CONF_URL}    headers=${HEADERS}
    Log    ${rsp.content}
    BuiltIn.Return_From_Keyword_If    "${rsp.status_code}"=="404"
    ${resp}=    RequestsLibrary.Delete_Request    ${CONFIG_SESSION}    ${MVPN_CONF_URL}
    BuiltIn.Should_Be_Equal_As_Numbers    ${resp.status_code}    200

Withdraw_Route_And_Verify
    [Arguments]    ${withdraw_hex}
    [Documentation]    Sends withdraw update message from exabgp and verifies route removal from odl's rib
    BgpRpcClient.play_send    ${withdraw_hex}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    2s    Loc Rib Presnece    ${empty_routes}

Get_Update_Content
    [Documentation]    Gets received data from odl's peer
    ${resp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_ADJ_RIB}    headers=${HEADERS_XML}
    BuiltIn.Log    ${resp.content}
    ${update}=    BgpRpcClient.play_get
    Run Keyword And Ignore Error    BuiltIn.Should_Not_Be_Equal    ${update}    ${Empty}
    [Return]    ${update}

Loc_Rib_Presence
    #[Arguments]    ${exp_content}
    [Documentation]    Verifies if loc-rib contains expected data
    ${output}    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib    headers=${HEADERS}
    BuiltIn.Log    ${output.content}
    # TODO: TEMPLATED_REQUESTS
    ${rsp}    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${MVPN_ADJ_RIB}    headers=${HEADERS}
    BuiltIn.Log    ${rsp.content}
    Run Keyword And Ignore Error    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp_content}    ${rsp.content}
