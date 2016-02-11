*** Settings ***
Documentation     Functional test for bgp flowspec.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           RequestsLibrary
Library           SSHLibrary
Variables         ../../../variables/Variables.py
Variables         ${CURDIR}/../../../variables/bgpuser/variables.py    ${TOOLS_SYSTEM_IP}
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/ConfigViaRestconf.robot

*** Variables ***
#${ACTUAL_RESPONSES_FOLDER}    ${TEMPDIR}/actual
#${EXPECTED_RESPONSES_FOLDER}    ${TEMPDIR}/expected
${HOLDTIME}       180
${BGP_VARIABLES_FOLDER}    ${CURDIR}/../../../variables/bgpflowspec
${cmd}            env exabgp.tcp.port=1790 exabgp --debug
${exp0}           empty-flowspec.json
${cfg1}           bgp-flowspec.cfg
${exp1}           bgp-flowspec.json
${cfg2}           bgp-flowspec-redirect.cfg
${exp2}           bgp-flowspec-redirect.json
${flowspecurl}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/loc-rib/tables/bgp-types:ipv4-address-family/bgp-flowspec:flowspec-subsequent-address-family/bgp-flowspec:flowspec-routes

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
    [Documentation]    Testing flowspec values for ${cfg1}
    [Setup]    Setup Testcase    ${cfg1}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${exp1}
    [Teardown]    Stop_Tool

FlowSpec Test 2
    [Documentation]    Testing flowspec values for ${cfg2}
    [Setup]    Setup Testcase    ${cfg2}
    BuiltIn.Wait Until Keyword Succeeds    15s    1s    Verify Flowspec Data    ${exp2}
    [Teardown]    Stop_Tool

*** Keywords ***
Start Suite
    [Documentation]    Suite setup keyword
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
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
    #RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_TOPO_API}    auth=${AUTH}
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
    Verify Flowspec Data    ${exp0}

Verify Flowspec Data
    [Arguments]    ${exprspfile}
    [Documentation]    Verify expected response
    ${rsp}=    RequestsLibrary.Get    session    ${flowspecurl}    #headers=${ACCEPT_XML}
    Log    ${rsp.content}
    ${json_text}=    OperatingSystem.Get file    ${CURDIR}/../../../variables/bgpflowspec/${exprspfile}
    Log    ${json_text}
    ${flowspec_json}=    BuiltIn.Evaluate    json.loads('''${json_text}''')    modules=json
    Log    ${flowspec_json}
    Should Be Equal    ${rsp.json()}    ${flowspec_json}
    #Wait_For_Topology_To_Change_To
    #    [Arguments]    ${json_topology}    ${filename}    ${timeout}=10s    ${refresh}=1s
    #    [Documentation]    Normalize the expected json topology and save it to ${EXPECTED_RESPONSES_FOLDER}.
    #    ...    Wait until Compare_Topology matches. ${ACTUAL_RESPONSES_FOLDER} will hold its last result.
    #    ${topology_normalized}=    Normalize_And_Save_Expected_Json    ${json_topology}    ${filename}    ${EXPECTED_RESPONSES_FOLDER}
    #    BuiltIn.Wait_Until_Keyword_Succeeds    ${timeout}    ${refresh}    Compare_Topology    ${topology_normalized}    ${filename}
    #Normalize_And_Save_Expected_Json
    #    [Arguments]    ${json_text}    ${filename}    ${directory}
    #    [Documentation]    Normalize given json using hsf_json library. Log and save the result to given filename under given directory.
    #    ${json_normalized}=    hsf_json.Hsf_Json    ${json_text}
    #    BuiltIn.Log    ${json_normalized}
    #    OperatingSystem.Create_File    ${directory}${/}${filename}    ${json_normalized}
    #    # TODO: Should we prepend .json to the filename? When we detect it is not already prepended?
    #    [Return]    ${json_normalized}
    #Compare_Topology
    #    [Arguments]    ${expected_normalized}    ${filename}
    #    [Documentation]    Get current example-ipv4-topology as json, normalize it, save to ${ACTUAL_RESPONSES_FOLDER}.
    #    ...    Check that status code is 200, check that normalized jsons match exactly.
    #    ${rrr}=    RequestsLibrary.Get    session    ${flowspecurl}    #headers=${ACCEPT_XML}
    #    Log    ${rrr.content}
    #    ${response}=    RequestsLibrary.Get Request    operational    topology/example-ipv4-topology
    #    BuiltIn.Log    ${response.status_code}
    #    BuiltIn.Log    ${response.text}
    #    ${actual_normalized}=    Normalize_And_Save_Expected_Json    ${response.text}    ${filename}    ${ACTUAL_RESPONSES_FOLDER}
    #    BuiltIn.Should_Be_Equal_As_Strings    ${response.status_code}    200
    #    BuiltIn.Should_Be_Equal    ${actual_normalized}    ${expected_normalized}
