*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start_Suite
Suite Teardown    Stop_Suite
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
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
${EXARPCSCRIPT}    ${CURDIR}/../../../scripts/exarpc.py
${JOLOKURL}       /jolokia/read/org.opendaylight.controller:instanceName=${BGP_PEER_NAME},type=RuntimeBean,moduleFactoryName=bgp-peer

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configures bgp application peer
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}    APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configures BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

L3vpn_Ipv4_To_Odl
    [Documentation]    Testing mpls vpn ipv4 routes reported to odl from exabgp
    [Setup]    Setup Testcase    ${L3VPN_EXA_CFG}    ${L3VPN_URL}    ${L3VPN_RSPEMPTY}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Reported Data    ${L3VPN_URL}    ${L3VPN_RSP}
    [Teardown]    Teardown Testcase    ${L3VPN_URL}    ${L3VPN_RSPEMPTY}

L3vpn_Ipv4_From_Odl
    [Documentation]    Testing mpls vpn ipv4 routes reported from odl to exabgp
    [Setup]    Start_Tool_And_Verify_Started    ${DEFAUTL_EXA_CFG}
    BgpRpcClient.exa_clean_update_message
    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x    2s    Verify Tool Received Update    ${BGP_L3VPN_DIR}/route/exa-expected.json
    [Teardown]    Remove_Route_And_Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    BuiltIn.Log_To_Console     ${stdout}
    BuiltIn.Log_To_Console     ${stderr}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    BuiltIn.Log_To_Console     ${stdout}
    BuiltIn.Log_To_Console     ${stderr}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo pip install exabgp    return_stdout=True    return_stderr=True
    ...    return_rc=True
    BuiltIn.Log_To_Console     ${stdout}
    BuiltIn.Log_To_Console     ${stderr}
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
    Start_Tool_And_Verify_Started    ${cfg_file}

Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Starts the tool with given config file
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Start_Tool_And_Verify_Started
    [Arguments]    ${cfg_file}
    [Documentation]    Starts the tool and verifies started
    Start_Tool    ${cfg_file}
    ${status}    ${output}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}
    BuiltIn.Log_To_Console    ${output}
    Return From Keyword If    '${status}' != 'PASS'    ${Empty}
    Builtin.Fail    The prompt was seen but it was not expected yet

Stop_Tool
    [Documentation]    Stops the tool by sending ctrl+c
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Remove_Route_And_Stop_Tool
    [Documentation]    Removes configured route from application peer and stops the tool
    &{mapping}    Create Dictionary
    TemplatedRequests.Delete_Templated    ${BGP_L3VPN_DIR}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    Stop_Tool

Teardown_Testcase
    [Arguments]    ${url}    ${empty_response}
    [Documentation]    Testcse teardown with data verification
    Stop_Tool
    Verify Reported Data    ${url}    ${empty_response}

Verify_Tool_Received_Update
    [Arguments]    ${exp_update_fn}
    ${exp_update}=    Get_Expected_Response_From_File    ${exp_update_fn}
    ${rcv_update1}=    BgpRpcClient.exa_get_update_message    msg_only=${True}
    ${rcv_update}=    BuiltIn.Evaluate    json.dumps(${rcv_update1})    modules=json
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
