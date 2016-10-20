*** Settings ***
Documentation     Robot keyword library (Resource) for handling the ExaBgp tool.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library assumes that a SSH connection exists (and is switched to)
...               to a Linux machine (usualy TOOLS_SYSTEM) where the ExaBgp should be run.
Library           SSHLibrary
Resource          ${CURDIR}/Utils.robot

*** Variables ***
${CMD}            env exabgp.tcp.port=1790 exabgp --debug
${PEER_CHECK_URL}    /restconf/operational/bgp-rib:bgp-rib/rib/example-bgp-rib/peer/bgp:%2F%2F

*** Keywords ***
Start_ExaBgp
    [Arguments]    ${cfg_file}
    [Documentation]    Start the ExaBgp
    ${start_cmd}    BuiltIn.Set_Variable    ${CMD} ${cfg_file}
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Stop_ExaBgp
    [Documentation]    Stop the tool by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    Utils.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Start_ExaBgp_And_Verify_Connected
    [Arguments]    ${cfg_file}    ${session}    ${exabgp_ip}
    [Documentation]    Start the tool and verify its connection
    Start_ExaBgp    ${cfg_file}
    BuiltIn.Wait_Until_Keyword_Succeeds    3x    3s    Verify_ExaBgps_Connection    ${session}    ${exabgp_ip}     connected=${True}


Verify_ExaBgps_Connection
    [Arguments]    ${session}    ${exabgp_ip}    ${connected}=${True}    
    [Documentation]    Checks peer presence in operational datastore
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.Get Request    ${session}    ${PEER_CHECK_URL}${exabgp_ip}
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}
