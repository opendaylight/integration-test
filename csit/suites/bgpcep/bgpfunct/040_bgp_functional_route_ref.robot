*** Settings ***
Documentation     Functional test for bgp.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Variables         ${CURDIR}/../../../variables/Variables.py
#Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/norm_json.py
Library           ${CURDIR}/../../../libraries/BgpRpcClient.py        ${TOOLS_SYSTEM_IP}
#Resource          ${CURDIR}/../../../libraries/BGPcliKeywords.robot

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${APP_PEER_NAME}   example-bgp-peer-app
#${CMD}            source ~/osctestenv/bin/activate; env exabgp.tcp.port=1790 exabgp --debug
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
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    APP_PEER_NAME=${APP_PEER_NAME}    RIB_INSTANCE_NAME=${RIB_INSTANCE}   APP_PEER_ID=${ODL_SYSTEM_IP}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/app_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    RIB_INSTANCE_NAME=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Xml_Templated    ${BGP_VAR_FOLDER}/bgp_peer    mapping=${mapping}    session=${CONFIG_SESSION}

Exa To Send Route Request
    [Documentation]     Exa sends route refresh and count received updates
    [Setup]    Configure Routes And Start Tool      ${BGP_CFG_NAME}
    Verify Odl Received Route Request    0
    ${count_sync}=     BgpRpcClient.exa_get_received_update_count
    BgpRpcClient.exa_clean_received_update_count
    BgpRpcClient.exa_announce     announce route-refresh ipv4 unicast
    BuiltIn.Wait Until Keyword Succeeds    5x   2s      Verify Odl Received Route Request    1
    ${count_ff}=     BgpRpcClient.exa_get_received_update_count
    BuiltIn.Should Be Equal As Numbers    ${count_sync}     ${count_ff}
    [Teardown]    Deconfigure Routes And Stop Tool

Odl To Send Route Request
    [Documentation]     Sends route requests and checks if exabgp receives it
    [Setup]    Start Tool And Verify      ${BGP_CFG_NAME}
    BgpRpcClient.exa_clean_received_route_refresh_count
    &{mapping}    Create Dictionary    BGP_PEER_IP=${TOOLS_SYSTEM_IP}
    TemplatedRequests.Post_As_Xml_Templated    ${BGP_VAR_FOLDER}/route_refresh    mapping=${mapping}    session=${CONFIG_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    5x   2s      Verify Odl Sent Route Request    1
    [Teardown]    Stop_Tool

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
Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True$
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    #...    return_rc=True
    #${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install exabgp    return_stdout=True    return_stderr=True
    #...    return_rc=True
    RequestsLibrary.Create Session   ${CONFIG_SESSION}     http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Upload Config Files

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put File    ${BGP_VAR_FOLDER}/${BGP_CFG_NAME}    .
    SSHLibrary.Put File    ${EXARPCSCRIPT}    .
    @{cfgfiles}=    SSHLibrary.List Files In Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ROUTEREFRESH/enable/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command    cat ${cfgfile}
    \    Log    ${stdout}

#Setup Testcase
#    [Arguments]    ${cfg_file}    ${url}    ${empty_response}
#    Verify Reported Data     ${url}    ${empty_response}
#    Start Tool    ${cfg_file}

Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Start_Tool_And_Verify
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    Start_Tool    ${cfg_file}
    ${status}    ${output}=    BuiltIn.Run_Keyword_And_Ignore_Error      SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}
    Return From Keyword If    '${status}' != 'PASS'     ${Empty}
    Builtin.Fail    The prompt was seen but it was not expected yet

Stop_Tool
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read Until Prompt
    BuiltIn.Log    ${output}

Configure Routes And Start Tool     
    [Arguments]     ${cfg_file}
    :FOR    ${prefix}    IN    1.1.1.1/32     2.2.2.2/32
    \    &{mapping}    Create Dictionary    PREFIX=${prefix}
    \    TemplatedRequests.Post_As_Xml_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}
    Start_Tool_And_Verify    ${cfg_file}

Deconfigure Routes And Stop Tool
    Stop_Tool
    &{mapping}    Create Dictionary    PREFIX=${prefix}
    TemplatedRequests.Delete_Templated    ${BGP_RR_VAR_FOLDER}/route    mapping=${mapping}    session=${CONFIG_SESSION}

#Verify Reported Data
#    [Arguments]    ${url}    ${exprspfile}
#    [Documentation]    Verify expected response
#    ${keys_with_bits}=    BuiltIn.Create_List    op
#    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
#    ${expected_json}=    norm_json.Normalize Json Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
#    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${url}
#    BuiltIn.Log    ${rsp.content}
#    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
#    BuiltIn.Log    ${received_json}
#    BuiltIn.Log    ${expected_json}
#    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}

#Get Expected Response From File
#    [Arguments]    ${exprspfile}
#    [Documentation]    Looks for release specific response first, then take default.
#    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpfunctional/${exprspfile}.${ODL_STREAM}
#    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
#    ${expresponse}=    OperatingSystem.Get File    ${BGP_VAR_FOLDER}/${exprspfile}
#    [Return]    ${expresponse}

Verify Odl Sent Route Request
    [Arguments]    ${expcount}
    ${count}=    BgpRpcClient.exa_get_received_route_refresh_count
    BuiltIn.Should Be Equal As Numbers     ${count}    ${expcount}

Verify Odl Received Route Request
    [Arguments]    ${expcount}
    ${rsp}=      RequestsLibrary.Get Request      ${CONFIG_SESSION}    ${JOLOKURL}
    BuiltIn.Log     ${rsp.content}
    BuiltIn.Should Be Equal As Numbers     ${rsp.status_code}     200
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['status']}     200
    #${count}=    BuiltIn.Set Variable    ${rsp.json()}['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']
    BuiltIn.Should Be Equal As Numbers     ${rsp.json()['value']['BgpSessionState']['messagesStats']['routeRefreshMsgs']['received']['count']['value']}    ${expcount}

