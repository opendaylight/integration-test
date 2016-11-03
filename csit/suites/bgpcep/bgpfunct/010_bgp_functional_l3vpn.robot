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
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Test Setup        SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py    ${TOOLS_SYSTEM_IP}

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}    example-bgp-peer-app
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${BGP_L3VPN_DIR}    ${BGP_VAR_FOLDER}/l3vpn_ipv4
${DEFAUTL_EXA_CFG}    exa.cfg
${L3VPN_EXA_CFG}    bgp-l3vpn-ipv4.cfg
${L3VPN_RSPEMPTY}    ${BGP_L3VPN_DIR}/bgp-l3vpn-ipv4-empty.json
${L3VPN_RSP}      ${BGP_L3VPN_DIR}/bgp-l3vpn-ipv4.json
${L3VPN_URL}      /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-types:mpls-labeled-vpn-subsequent-address-family/bgp-vpn-ipv4:vpn-ipv4-routes
${CONFIG_SESSION}    config-session
${EXARPCSCRIPT}    ${CURDIR}/../../../../tools/exabgp_files/exarpc.py
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F
${OPENCONFIG_PEER_URI}    /restconf/config/openconfig-network-instance:network-instances/network-instance/global-bgp/openconfig-network-instance:protocols/protocol/openconfig-policy-types:BGP/bgp-example/bgp/neighbors/neighbour
${DEFAULT_BGPCEP_LOG_LEVEL}    INFO

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer. Openconfig is used for carbon and above.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}
    CompareStream.Run_Keyword_If_At_Most_Boron    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Carbon    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/openconfig_app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    CompareStream.Run_Keyword_If_At_Most_Boron    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    ompareStream.Run_Keyword_If_At_Least_Carbon    

L3vpn_Ipv4_To_Odl
    [Documentation]    Testing mpls vpn ipv4 routes reported to odl from exabgp
    [Setup]    Setup_Testcase    ${L3VPN_EXA_CFG}    ${L3VPN_URL}    ${L3VPN_RSPEMPTY}
    BuiltIn.Wait_Until_Keyword_Succeeds    15s    1s    Verify Reported Data    ${L3VPN_URL}    ${L3VPN_RSP}
    [Teardown]    Teardown_Testcase    ${L3VPN_URL}    ${L3VPN_RSPEMPTY}

L3vpn_Ipv4_From_Odl
    [Documentation]    Testing mpls vpn ipv4 routes reported from odl to exabgp
    [Setup]    Start_Tool_And_Verify_Connected    ${DEFAUTL_EXA_CFG}
    BgpRpcClient.exa_clean_update_message
    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify_Tool_Received_Update    ${BGP_L3VPN_DIR}/route/exa-expected.json
    [Teardown]    Remove_Route_And_Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    CompareStream.Run_Keyword_If_At_Most_Boron    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Carbon    TemplatedRequests.Delete_From_Uri    uri=${OPENCONFIG_PEER_URI}/${TOOLS_SYSTEM_IP}    session=${CONFIG_SESSION}    allow_404=${False}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    CompareStream.Run_Keyword_If_At_Most_Boron    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}
    CompareStream.Run_Keyword_If_At_Least_Carbon    TemplatedRequests.Delete_From_Uri    uri=${OPENCONFIG_PEER_URI}/${ODL_SYSTEM_IP}    session=${CONFIG_SESSION}    allow_404=${False}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package    exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files
    KarafKeywords.Set_Bgpcep_Log_Levels    # ${DEFAULT_BGPCEP_LOG_LEVEL} is applied by default

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHKeywords.Virtual_Env_Delete
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete_All_Sessions

Upload_Config_Files
    [Documentation]    Uploads exabgp config files and needed scripts
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${DEFAUTL_EXA_CFG}    .
    SSHLibrary.Put_File    ${BGP_L3VPN_DIR}/${L3VPN_EXA_CFG}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

Setup_Testcase
    [Arguments]    ${cfg_file}    ${url}    ${empty_response}
    [Documentation]    Verifies initial test condition and starts the tool
    Verify_Reported_Data    ${url}    ${empty_response}
    Start_Tool_And_Verify_Connected    ${cfg_file}

Start_Tool
    [Arguments]    ${cfg_file}    ${mapping}={}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    ${start_cmd}    BuiltIn.Set_Variable    ${cmd} ${cfg_file}
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Verify_Tools_Connection
    [Arguments]    ${connected}=${True}
    [Documentation]    Checks peer presence in operational datastore
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${PEER_CHECK_URL}${TOOLS_SYSTEM_IP}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}

Start_Tool_And_Verify_Connected
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool and verify its connection
    Start_Tool    ${cfg_file}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_Tools_Connection    connected=${True}

Stop_Tool
    [Documentation]    Stop the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Remove_Route_And_Stop_Tool
    [Documentation]    Removes configured route from application peer and stops the tool
    &{mapping}    BuiltIn.Create_Dictionary
    TemplatedRequests.Delete_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    Stop_Tool

Teardown_Testcase
    [Arguments]    ${url}    ${empty_response}
    [Documentation]    Testcse teardown with data verification
    Stop_Tool
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    1s    Verify_Reported_Data    ${url}    ${empty_response}

Verify_Tool_Received_Update
    [Arguments]    ${exp_update_fn}
    [Documentation]    Verification of receiving particular update message
    ${exp_update}=    Get_Expected_Response_From_File    ${exp_update_fn}
    ${rcv_update_dict}=    BgpRpcClient.exa_get_update_message    msg_only=${True}
    ${rcv_update}=    BuiltIn.Evaluate    json.dumps(${rcv_update_dict})    modules=json
    TemplatedRequests.Normalize_Jsons_And_Compare    ${exp_update}    ${rcv_update}

Verify_Reported_Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verifies expected response
    ${expected_rsp}=    Get_Expected_Response_From_File    ${exprspfile}
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${url}
    TemplatedRequests.Normalize_Jsons_And_Compare    ${expected_rsp}    ${rsp.content}

Get_Expected_Response_From_File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${exprspfile}
    [Return]    ${expresponse}
