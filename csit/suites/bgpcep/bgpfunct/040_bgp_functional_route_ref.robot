*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...               This suite tests sending and receiveing route request message.
...               It uses exabgp odl and exabgpa as bgp peers.
...               Sending route request message from odl is initiated via restconf.
...               If route request received by odl also correct advertising of routes
...               is verified.
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
${APP_PEER_NAME}   example-bgp-peer-app
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${BGP_VAR_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional
${BGP_RR_VAR_FOLDER}       ${BGP_VAR_FOLDER}/route_refresh
${BGP_CFG_NAME}     exa.cfg
${CONFIG_SESSION}      config-session
${EXARPCSCRIPT}    ${CURDIR}/../../../scripts/exarpc.py
${JOLOKURL}    /jolokia/read/org.opendaylight.controller:instanceName=${BGP_PEER_NAME},type=RuntimeBean,moduleFactoryName=bgp-peer

*** Test Cases ***
Configure_App_Peer
    [Documentation]    Configure bgp application peer
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}   APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Exa_To_Send_Route_Request
    [Documentation]     Exabgp sends route refresh and count received updates
    [Setup]    Configure_Routes_And_Start_Tool      ${BGP_CFG_NAME}
    Verify_Odl_Received_Route_Request    0
    ${count_sync}=     BgpRpcClient.exa_get_received_update_count
    BgpRpcClient.exa_clean_received_update_count
    BgpRpcClient.exa_announce     announce route-refresh ipv4 unicast
    BuiltIn.Wait_Until_Keyword_Succeeds    5x   2s      Verify_Odl_Received_Route_Request    1
    ${count_ff}=     BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should_Be_Equal_As_Numbers    ${count_sync}     ${count_ff}
    [Teardown]    Deconfigure_Routes_And_Stop_Tool

Odl_To_Send_Route_Request
    [Documentation]     Sends route requests and checks if exabgp receives it
    [Setup]    Start_Tool_And_Verify_Started      ${BGP_CFG_NAME}
    BgpRpcClient.exa_clean_received_route_refresh_count
    &{mapping}    BuiltIn.Create_Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/route_refresh    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait_Until_Keyword_Succeeds    5x   2s      Verify_Odl_Sent_Route_Request    1
    [Teardown]    Stop_Tool

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Deconfigure_App_Peer
    [Documentation]    Revert the BGP configuration to the original state: without application peer
    &{mapping}    BuiltIn.Create_Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}
    TemplatedRequests.Delete_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

*** Keywords ***
Start_Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set_Suite_Variable    ${mininet_conn_id}
    Utils.Flexible_Mininet_Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True$
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    #...    return_rc=True
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute_Command    sudo pip install exabgp    return_stdout=True    return_stderr=True
    #...    return_rc=True
    RequestsLibrary.Create_Session   ${CONFIG_SESSION}     http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload_Config_Files

Stop_Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close_All_Connections
    RequestsLibrary.Delete All Sessions

Upload_Config_Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put_File    ${BGP_VAR_FOLDER}/${BGP_CFG_NAME}    .
    SSHLibrary.Put_File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
    \    SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
    \    Log    ${stdout}

Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool with given config file
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Start_Tool_And_Verify_Started
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool and verifies started
    Start_Tool    ${cfg_file}
    ${status}    ${output}=    BuiltIn.Run_Keyword_And_Ignore_Error    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}
    Return From Keyword If    '${status}' != 'PASS'    ${Empty}
    Builtin.Fail    The prompt was seen but it was not expected yet

Stop_Tool
    [Documentation]    Stop the tool by sending ctrl+c
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Configure_Routes_And_Start_Tool     
    [Arguments]     ${cfg_file}
    [Documentation]      Setup keyword for exa to odl test case
    :FOR    ${prefix}    IN    1.1.1.1/32     2.2.2.2/32
    \    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}
    \    TemplatedRequests.Post_As_Xml_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    Start_Tool_And_Verify_Started    ${cfg_file}

Deconfigure_Routes_And_Stop_Tool
    [Documentation]     Teardown keyword for exa to odl test case
    Stop_Tool
    &{mapping}    BuiltIn.Create_Dictionary    PREFIX=${prefix}
    TemplatedRequests.Delete_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}

Verify_Odl_Sent_Route_Request
    [Arguments]    ${expcount}
    [Documentation]     Compares expected count of route request messages on exabgp side
    ${count}=    BgpRpcClient.exa_get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers     ${count}    ${expcount}

Verify_Odl_Received_Route_Request
    [Documentation]     Gets numebr of received route requests and compares with given expected count
    [Arguments]    ${expcount}
    ${rsp}=      RequestsLibrary.Get_Request      ${CONFIG_SESSION}    ${JOLOKURL}
    BuiltIn.Log     ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers     ${rsp.status_code}     200
    BuiltIn.Should_Be_Equal_As_Numbers     ${rsp.json()['status']}     200
    BuiltIn.Should_Be_Equal_As_Numbers     ${rsp.json()['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']['value']}    ${expcount}

