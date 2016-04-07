*** Settings ***
Documentation
Library           SSHLibrary
Library           ${CURDIR}/VsctlListParser.py
Library           Collections

*** Variables ***
${SH_BR_CMD}      ovs-vsctl list Bridge
${SH_CNTL_CMD}     ovs-vsctl list Controller
${ovs_switch_data}       ${None}
${lprompt}         mininet>
${lcmd_prefix}     sh

*** Keywords ***
Initialize If Shell Used
    [Arguments]     ${prompt}      ${cmd_prefix}
    BuiltIn.Set Suite variable   ${lprompt}     ${prompt}
    BuiltIn.Set Suite variable   ${lcmd_prefix}     ${cmd_prefix}

Get Ovsdb Data
    [Arguments]     ${prompt}=mininet>
    [Documentation]    Gets ovs data and parse them.
    SSHLibrary.Write    ${lcmd_prefix} ${SH_BR_CMD}
    ${brstdout}=  SSHLibrary.Read_Until     ${lprompt}
    Log    ${brstdout}
    SSHLibrary.Write    ${lcmd_prefix} ${SH_CNTL_CMD}
    ${cntlstdout}=  SSHLibrary.Read_Until    ${lprompt}
    Log    ${cntlstdout}
    ${data}    ${bridegs}     ${controllers}=     VsctlListParser.Parse    ${brstdout}      ${cntlstdout}
    BuiltIn.Log    ${data}
    BuiltIn.Set Suite Variable   ${ovs_switch_data}      ${data}
    BuiltIn.Return From Keyword     ${data}

Get Controllers Uuid
    [Arguments]    ${switch}    ${controller}     ${update_data}=${False}
    [Documentation]    Returns controllers uuid
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls}=    Collections.Get From Dictionary      ${bridge}    controller  
    ${cntl}=    Collections.Get From Dictionary      ${cntls}    ${controller} 
    ${uuid}=     Collections.Get From Dictionary      ${cntl}    _uuid
    BuiltIn.Return From Keyword     ${uuid}

Execute OvsVsctl Show Command
    [Documentation]    Executes ovs-vsctl show command
    SSHLibrary.Write    ${lcmd_prefix} ovs-vsctl show
    ${output}=  SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}

Disconnect Switch From Controller And Verify
    [Arguments]    ${switch}    ${controller}     ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid   ${switch}    ${controller}
    ${cmd}=   BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6654"
    SSHLibrary.Write    ${cmd}
    ${output}=  SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    BuiltIn.Wait Until Keyword Succeeds    6s    2s    Should Be Disconnected    ${switch}    ${controller}    update_data=${True}
    Execute OvsVsctl Show Command

Reconnect Switch To Controller And Verify
    [Arguments]    ${switch}    ${controller}      ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid   ${switch}    ${controller}
    ${cmd}=   BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6653"
    SSHLibrary.Write    ${cmd}
    ${output}=  SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    BuiltIn.Wait Until Keyword Succeeds    6s    2s    Should Be Connected    ${switch}    ${controller}     update_data=${True}
    Execute OvsVsctl Show Command

Should Be Connected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data  
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls}=    Collections.Get From Dictionary      ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary      ${cntls}    ${controller}
    ${connected}=     Collections.Get From Dictionary      ${cntl}    is_connected
    BuiltIn.Should Be True     ${connected}

Should Be Disconnected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data  
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls}=    Collections.Get From Dictionary      ${bridge}    controller  
    ${cntl}=    Collections.Get From Dictionary      ${cntls}    ${controller} 
    ${connected}=     Collections.Get From Dictionary      ${cntl}    is_connected
    BuiltIn.Should Be Equal     ${connected}    ${False}

Should Be Master
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Verifies the master role
    ${role}   Get Node Role    ${switch}    ${controller}     update_data=${update_data}
    BuiltIn.Should Be Equal   ${role}    master


Should Be Slave
    [Arguments]    ${switch}    ${controller}     ${update_data}=${False}
    [Documentation]    Verifies the slave role
    ${role}   Get Node Role    ${switch}    ${controller}     update_data=${update_data}
    BuiltIn.Should Be Equal   ${role}    slave
    

Get Node Role
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Returns the controllers role
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data  
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls}=    Collections.Get From Dictionary      ${bridge}    controller  
    ${cntl}=    Collections.Get From Dictionary      ${cntls}    ${controller} 
    ${role}=     Collections.Get From Dictionary      ${cntl}    role
    Return From Keyword     ${role}

Get Master Node
    [Arguments]    ${switch}    ${update_data}=${False}
    [Documentation]    Gets controller which is a master
    ${master}=     BuiltIn.Set Variable    ${None}
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary     ${bridge}   controller
    ${cntls_items}=    Collections.Get Dictionary Items     ${cntls_dict}
    :FOR    ${key}    ${value}    IN    @{cntls_items}
    \    Log    ${key} : ${value}
    \    ${role}=    Collections.Get From Dictionary    ${value}     role
    \    Run Keyword If   "${role}"=="master"   BuiltIn.Should Be Equal    ${master}    ${None}
    \    ${master}=   BuiltIn.Set Variable If  "${role}"=="master"   ${key}    ${master}
    BuiltIn.Should Not Be Equal    ${master}    ${None}
    Return From Keyword     ${master}
    
Get Follower Nodes
    [Arguments]    ${switch}    ${update_data}=${False}
    [Documentation]    Gets followers nodes
    ${followers}=     BuiltIn.Create List
    Run Keyword If   ${update_data}==${True}  Get Ovsdb Data
    ${bridge}=     Collections.Get From Dictionary      ${ovs_switch_data}     ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary     ${bridge}   controller
    ${cntls_items}=    Collections.Get Dictionary Items     ${cntls_dict}
    :FOR    ${key}    ${value}    IN    @{cntls_items}
    \    Log    ${key} : ${value}
    \    ${role}=    Collections.Get From Dictionary    ${value}     role
    \    Run Keyword If   "${role}"=="slave"    Collections.Append To List    ${followers}    ${key}
    Return From Keyword     ${followers}

