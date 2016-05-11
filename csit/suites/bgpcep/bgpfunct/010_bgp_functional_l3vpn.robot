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
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Resource          ${CURDIR}/../../../libraries/KarafKeywords.robot
Resource          ${CURDIR}/../../../libraries/SSHKeywords.robot
Library           ${CURDIR}/../../../libraries/norm_json.py
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

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

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
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    ${tools_system_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${tools_system_conn_id}
    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    SSHKeywords.Virtual_Env_Create
    SSHKeywords.Virtual_Env_Install_Package      exabgp==3.4.16
    RequestsLibrary.Create_Session    ${CONFIG_SESSION}    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
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
    ${start_cmd}     BuiltIn.Set_Variable     source ${SSHKeywords__current_venv_path}; ${cmd} ${cfg_file}
    BuiltIn.Log    ${start_cmd}
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
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
    Start_Tool    ${cfg_file}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_Tools_Connection    connected=${True}

Stop_Tool
    [Documentation]    Stop the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    ${output}=    SSHLibrary.Write    deactivate
    BuiltIn.Log    ${output}
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

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
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${received_json}=    norm_json.Normalize_Json_Text    ${rcv_update}    keys_with_bits=${keys_with_bits}
    ${expected_json}=    norm_json.Normalize_Json_Text    ${exp_update}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should_Be_Equal    ${received_json}    ${expected_json}

Verify_Reported_Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verifies expected response
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${expected_rsp}=    Get_Expected_Response_From_File    ${exprspfile}
    ${expected_json}=    norm_json.Normalize_Json_Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
    ${rsp}=    RequestsLibrary.Get_Request    ${CONFIG_SESSION}    ${url}
    BuiltIn.Log    ${rsp.content}
    ${received_json}=    norm_json.Normalize_Json_Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should_Be_Equal    ${received_json}    ${expected_json}

Get_Expected_Response_From_File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${exprspfile}
    [Return]    ${expresponse}
