*** Settings ***
Documentation       Robot keyword library (Resource) for handling the ExaBgp tool.
...
...                 Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This library assumes that a SSH connection exists (and is switched to)
...                 to a Linux machine (usualy TOOLS_SYSTEM) where the ExaBgp should be run.
...
...                 TODO: RemoteBash.robot contains logic which could be reused here.

Library             RequestsLibrary
Library             SSHLibrary
Resource            ${CURDIR}/SSHKeywords.robot
Resource            ${CURDIR}/RemoteBash.robot
Resource            ${CURDIR}/BGPcliKeywords.robot


*** Variables ***
${EXABGP_KILL_COMMAND}      ps axf | grep exabgp | grep -v grep | awk '{print \"kill -9 \" $1}' | sh
${CMD}                      env exabgp.tcp.port=1790 exabgp --debug


*** Keywords ***
Start_ExaBgp
    [Documentation]    Dump the start command into prompt. It assumes that no exabgp is running. For verified
    ...    start use Start_ExaBgp_And_Verify_Connected keyword.
    [Arguments]    ${cfg_file}
    ${start_cmd}=    BuiltIn.Set_Variable    ${CMD} ${cfg_file}
    BuiltIn.Log    ${start_cmd}
    SSHKeywords.Virtual_Env_Activate_On_Current_Session    log_output=${True}
    ${output}=    SSHLibrary.Execute_Command    ip a
    BuiltIn.Log    ${output}
    ${output}=    SSHLibrary.Write    ${start_cmd}
    BuiltIn.Log    ${output}

Stop_ExaBgp
    [Documentation]    Stops the ExaBgp by sending ctrl+c
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    RemoteBash.Write_Bare_Ctrl_C
    ${output}=    SSHLibrary.Read_Until_Prompt
    BuiltIn.Log    ${output}
    SSHKeywords.Virtual_Env_Deactivate_On_Current_Session    log_output=${True}

Stop_All_ExaBgps
    [Documentation]    Sends kill command to stop all exabgps running
    ${output}=    SSHLibrary.Read
    BuiltIn.Log    ${output}
    ${output}=    SSHLibrary.Write    ${EXABGP_KILL_COMMAND}
    BuiltIn.Log    ${output}

Start_ExaBgp_And_Verify_Connected
    [Documentation]    Starts the ExaBgp and verifies its connection. The verification is done by checking the presence
    ...    of the peer in the bgp rib.
    [Arguments]    ${cfg_file}    ${session}    ${exabgp_ip}    ${connection_retries}=${3}
    FOR    ${idx}    IN RANGE    ${connection_retries}
        Start_ExaBgp    ${cfg_file}
        ${status}    ${value}=    BuiltIn.Run_Keyword_And_Ignore_Error
        ...    BuiltIn.Wait_Until_Keyword_Succeeds
        ...    3x
        ...    3s
        ...    Verify_ExaBgps_Connection
        ...    ${session}
        ...    ${exabgp_ip}
        ...    connected=${True}
        IF    "${status}" != "PASS"    Stop_ExaBgp
        IF    "${status}" == "PASS"    RETURN
    END
    BuiltIn.Fail    Unable to connect ExaBgp to ODL

Verify_ExaBgps_Connection
    [Documentation]    Checks peer presence in operational datastore
    [Arguments]    ${session}    ${exabgp_ip}=${TOOLS_SYSTEM_IP}    ${connected}=${True}
    ${peer_check_url}=    BuiltIn.Set_Variable    ${REST_API}/bgp-rib:bgp-rib/rib=example-bgp-rib/peer=bgp:%2F%2F
    ${exp_status_code}=    BuiltIn.Set_Variable_If    ${connected}    ${200}    ${404}
    ${rsp}=    RequestsLibrary.GET On Session
    ...    ${session}
    ...    url=${peer_check_url}${exabgp_ip}?content=nonconfig
    ...    expected_status=anything
    BuiltIn.Log    ${rsp.content}
    BuiltIn.Should_Be_Equal_As_Numbers    ${exp_status_code}    ${rsp.status_code}

Upload_ExaBgp_Cluster_Config_Files
    [Documentation]    Uploads exabgp config files.
    [Arguments]    ${bgp_var_folder}    ${cfg_file}
    SSHLibrary.Put_File    ${bgp_var_folder}/${cfg_file}    .
    @{cfgfiles}=    SSHLibrary.List_Files_In_Directory    .    *.cfg
    FOR    ${cfgfile}    IN    @{cfgfiles}
        SSHLibrary.Execute_Command    sed -i -e 's/EXABGPIP/${TOOLS_SYSTEM_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP1/${ODL_SYSTEM_1_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP2/${ODL_SYSTEM_2_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ODLIP3/${ODL_SYSTEM_3_IP}/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ROUTEREFRESH/disable/g' ${cfgfile}
        SSHLibrary.Execute_Command    sed -i -e 's/ADDPATH/disable/g' ${cfgfile}
        ${stdout}=    SSHLibrary.Execute_Command    cat ${cfgfile}
        Log    ${stdout}
    END
