*** Settings ***
Documentation     Robot keyword library (Resource) for handling the GoBgp tool.
...           
...               Copyright (c) 2020 Lumina Networks and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...           
...               This library assumes that a SSH connection exists (and is switched to)
...               to a Linux machine (usualy TOOLS_SYSTEM) where the GoBgp should be run.
...           
Library           Process
Library           SSHLibrary
Resource          ${CURDIR}/BGPcliKeywords.robot
Resource          ${CURDIR}/RemoteBash.robot
Resource          ${CURDIR}/SSHKeywords.robot

*** Variables ***
${GOBGP_KILL_COMMAND}    ps axf | grep gobgp | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${GOBGP_EXECUTION_COMMAND}    /home/jenkins/gobgpd -l debug -f
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F

*** Keywords ***
Start_GoBgp
    [Arguments]    ${cfg_file}
    [Documentation]    Dump the start command into prompt. It assumes that no gobgp is running. For verified
    ...    start use Start_GoBgp_And_Verify_Connected keyword.
    ${start_cmd}    BuiltIn.Set Variable    ${GOBGP_EXECUTION_COMMAND} /home/jenkins/${cfg_file}
    BuiltIn.Log    ${start_cmd}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Stop_GoBgp
    [Documentation]    Stops the GoBgp by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}

Stop_All_GoBgps
    [Documentation]    Sends kill command to stop all Gobgps running
    ${output}    SSHLibrary.Read
    BuiltIn.Log    ${output}
    ${output}    SSHLibrary.Write    ${GOBGP_KILL_COMMAND}
    BuiltIn.Log    ${output}

Start_GoBgp_And_Verify_Connected
    [Arguments]    ${cfg_file}    ${session}    ${gobgp_ip}    ${connection_retries}=${3}
    [Documentation]    Starts the GoBgp and verifies its connection. The verification is done by checking the presence
    ...    of the peer in the bgp rib. [Gobgp at times might take more time, hence the loop]
    Start_GoBgp    ${cfg_file}
    ${status}    ${value}=    BuiltIn.Run_Keyword_And_Ignore_Error    BuiltIn.Wait_Until_Keyword_Succeeds    ${connection_retries}x    15s
    ...    Verify_GoBgps_Connection    ${session}    ${gobgp_ip}    connected=${True}
    BuiltIn.Run_Keyword_Unless    "${status}" == "PASS"    Stop_GoBgp
    BuiltIn.Return_From_Keyword_If    "${status}" == "PASS"

Verify_GoBgps_Connection
    [Arguments]    ${session}    ${gobgp_ip}=${TOOLS_SYSTEM_IP}    ${connected}=${True}
    [Documentation]    Checks peer presence in operational datastore
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${ALLOWED_STATUS_CODES}    ${DELETED_STATUS_CODES}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${PEER_CHECK_URL}${gobgp_ip}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}
