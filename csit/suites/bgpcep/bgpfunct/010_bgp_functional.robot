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
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ${CURDIR}/../../../libraries/Utils.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Library           ${CURDIR}/../../../libraries/norm_json.py

*** Variables ***
${HOLDTIME}       180
${DEVICE_NAME}    controller-config
${BGP_PEER_NAME}    example-bgp-peer
${RIB_INSTANCE}    example-bgp-rib
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${L3VPN_RSPEMPTY}           bgp-l3vpn-ipv4-empty.json
${L3VPN_CFG}           bgp-l3vpn-ipv4.cfg
${L3VPN_RSP}           bgp-l3vpn-ipv4.json
${L3VPN_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-types:mpls-labeled-vpn-subsequent-address-family/bgp-vpn-ipv4:vpn-ipv4-routes
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpfunctional/
${CONFIG_SESSION}      config-session

*** Test Cases ***
Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Put_As_Json_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

L3vpn Ipv4 Test
    [Documentation]    Testing mpls vpn ipv4 for ${L3VPN_CFG}
    [Setup]    Setup Testcase    ${L3VPN_CFG}   ${L3VPN_URL}    ${L3VPN_RSPEMPTY}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Reported Data   ${L3VPN_URL}      ${L3VPN_RSP}
    [Teardown]    Stop_Tool   ${L3VPN_URL}    ${L3VPN_RSPEMPTY}

Delete_Bgp_Peer_Configuration
    [Documentation]    Revert the BGP configuration to the original state: without any configured peers.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    &{mapping}    Create Dictionary    DEVICE_NAME=${DEVICE_NAME}    BGP_NAME=${BGP_PEER_NAME}    IP=${TOOLS_SYSTEM_IP}    HOLDTIME=${HOLDTIME}    PEER_PORT=${BGP_TOOL_PORT}
    ...    INITIATE=false    BGP_RIB=${RIB_INSTANCE}
    TemplatedRequests.Delete_Templated    ${BGP_VARIABLES_FOLDER}    mapping=${mapping}    session=${CONFIG_SESSION}

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
    Upload Config Files    ${BGP_VARIABLES_FOLDER}

Stop Suite
    [Documentation]    Suite teardown keyword
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Arguments]    ${dir_name}
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put Directory    ${CURDIR}/../../../variables/bgpfunctional/    .
    @{cfgfiles}=    SSHLibrary.List Files In Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command    cat ${cfgfile}
    \    Log    ${stdout}

Setup Testcase
    [Arguments]    ${cfg_file}    ${url}    ${empty_response}
    Verify Reported Data     ${url}    ${empty_response}
    Start Tool    ${cfg_file}

Start_Tool
    [Arguments]    ${cfg_file}
    [Documentation]    Start the tool ${cmd} ${cfg_file}
    BuiltIn.Log    ${cmd} ${cfg_file}
    ${output}=    SSHLibrary.Write    ${cmd} ${cfg_file}
    BuiltIn.Log    ${output}

Wait_Until_Tool_Finish
    [Arguments]    ${timeout}
    [Documentation]    Wait ${timeout} for the tool exit.
    BuiltIn.Wait Until Keyword Succeeds    ${timeout}    1s    SSHLibrary.Read Until Prompt

Stop_Tool
    [Arguments]    ${url}    ${emptyrspfile}
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}
    Verify Reported Data    ${url}    ${emptyrspfile}

Verify Reported Data
    [Arguments]    ${url}    ${exprspfile}
    [Documentation]    Verify expected response
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
    ${expected_json}=    norm_json.Normalize Json Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
    ${rsp}=    RequestsLibrary.Get Request    ${CONFIG_SESSION}    ${url}
    BuiltIn.Log    ${rsp.content}
    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}

Get Expected Response From File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpfunctional/${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${BGP_VARIABLES_FOLDER}/${exprspfile}
    [Return]    ${expresponse}
