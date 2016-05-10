*** Settings ***
Documentation     Functional test for bgp flowspec.
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
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot
Library           ${CURDIR}/../../../libraries/norm_json.py

*** Variables ***
${HOLDTIME}       180
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpflowspec
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${EXP0}           empty-flowspec.json
${CFG1}           bgp-flowspec.cfg
${EXP1}           bgp-flowspec.json
${CFG2}           bgp-flowspec-redirect.cfg
${EXP2}           bgp-flowspec-redirect.json
${FLOWSPEC_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes

*** Test Cases ***
Check_For_Empty_Topology_Before_Talking
    [Documentation]    Sanity check bgp-flowspec:flowspec-routes is up but empty.
    [Tags]    critical
    BuiltIn.Wait Until Keyword Succeeds    60s    3s    Verify Empty Flowspec Data

Reconfigure_ODL_To_Accept_Connection
    [Documentation]    Configure BGP peer module with initiate-connection set to false.
    ${template_as_string}=    BuiltIn.Set_Variable    {'NAME': 'example-bgp-peer', 'IP': '${TOOLS_SYSTEM_IP}', 'HOLDTIME': '${HOLDTIME}', 'PEER_PORT': '${BGP_TOOL_PORT}', 'INITIATE': 'false'}
    ConfigViaRestconf.Put_Xml_Template_Folder_Config_Via_Restconf    ${BGP_VARIABLES_FOLDER}    ${template_as_string}

FlowSpec Test 1
    [Documentation]    Testing flowspec values for ${CFG1}
    [Setup]    Setup Testcase    ${CFG1}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${EXP1}
    [Teardown]    Stop_Tool

FlowSpec Test 2
    [Documentation]    Testing flowspec values for ${CFG2}
    [Setup]    Setup Testcase    ${CFG2}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${EXP2}
    [Teardown]    Stop_Tool

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    ${mininet_conn_id}=    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    prompt=${DEFAULT_LINUX_PROMPT}    timeout=6s
    Builtin.Set Suite Variable    ${mininet_conn_id}
    Utils.Flexible Mininet Login    ${TOOLS_SYSTEM_USER}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo apt-get install -y python-pip    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    sudo pip install exabgp    return_stdout=True    return_stderr=True
    ...    return_rc=True
    RequestsLibrary.Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    ConfigViaRestconf.Setup_Config_Via_Restconf
    Upload Config Files    ${CURDIR}/../../../variables/bgpflowspec/

Stop Suite
    [Documentation]    Suite teardown keyword
    ConfigViaRestconf.Teardown_Config_Via_Restconf
    SSHLibrary.Close All Connections
    RequestsLibrary.Delete All Sessions

Upload Config Files
    [Arguments]    ${dir_name}
    [Documentation]    Uploads exabgp config files
    SSHLibrary.Put Directory    ${CURDIR}/../../../variables/bgpflowspec/    .
    @{cfgfiles}=    SSHLibrary.List Files In Directory    .    *.cfg
    : FOR    ${cfgfile}    IN    @{cfgfiles}
    \    SSHLibrary.Execute Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
    \    SSHLibrary.Execute Command    sed -i -e 's/ODLIP/${ODL_SYSTEM_IP}/g' ${cfgfile}
    \    ${stdout}=    SSHLibrary.Execute Command    cat ${cfgfile}
    \    Log    ${stdout}

Setup Testcase
    [Arguments]    ${cfg_file}
    Verify Empty Flowspec Data
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
    [Documentation]    Stop the tool if still running.
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read    delay=1s
    BuiltIn.Log    ${output}
    Verify Empty Flowspec Data

Verify Empty Flowspec Data
    [Documentation]    Verify expected response.
    Verify Flowspec Data    ${EXP0}

Verify Flowspec Data
    [Arguments]    ${exprspfile}
    [Documentation]    Verify expected response
    ${keys_with_bits}=    BuiltIn.Create_List    op
    ${expected_rsp}=    Get Expected Response From File    ${exprspfile}
    ${expected_json}=    norm_json.Normalize Json Text    ${expected_rsp}    keys_with_bits=${keys_with_bits}
    ${rsp}=    RequestsLibrary.Get Request    session    ${FLOWSPEC_URL}
    BuiltIn.Log    ${rsp.content}
    ${received_json}=    norm_json.Normalize Json Text    ${rsp.content}    keys_with_bits=${keys_with_bits}
    BuiltIn.Log    ${received_json}
    BuiltIn.Log    ${expected_json}
    BuiltIn.Should Be Equal    ${received_json}    ${expected_json}

Get Expected Response From File
    [Arguments]    ${exprspfile}
    [Documentation]    Looks for release specific response first, then take default.
    ${status}    ${expresponse}=    BuiltIn.Run_Keyword_And_Ignore_Error    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpflowspec/${exprspfile}.${ODL_STREAM}
    Return From Keyword If    '${status}' == 'PASS'    ${expresponse}
    ${expresponse}=    OperatingSystem.Get File    ${CURDIR}/../../../variables/bgpflowspec/${exprspfile}
    [Return]    ${expresponse}
