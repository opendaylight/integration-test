*** Settings ***
Documentation     Library to provide ovsdb access to mininet topologies
Library           SSHLibrary
Library           ${CURDIR}/VsctlListParser.py
Library           Collections

*** Variables ***
${SH_BR_CMD}      ovs-vsctl list Bridge
${SH_CNTL_CMD}    ovs-vsctl list Controller
${ovs_switch_data}    ${None}
${lprompt}        mininet>
${lcmd_prefix}    sh

*** Keywords ***
Initialize If Shell Used
    [Arguments]    ${prompt}    ${cmd_prefix}
    BuiltIn.Set Suite variable    ${lprompt}    ${prompt}
    BuiltIn.Set Suite variable    ${lcmd_prefix}    ${cmd_prefix}

Get Ovsdb Data
    [Arguments]    ${prompt}=mininet>
    [Documentation]    Gets ovs data and parse them.
    SSHLibrary.Write    ${lcmd_prefix} ${SH_BR_CMD}
    ${brstdout}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${brstdout}
    SSHLibrary.Write    ${lcmd_prefix} ${SH_CNTL_CMD}
    ${cntlstdout}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${cntlstdout}
    ${data}    ${bridegs}    ${controllers}=    VsctlListParser.Parse    ${brstdout}    ${cntlstdout}
    BuiltIn.Log    ${data}
    BuiltIn.Set Suite Variable    ${ovs_switch_data}    ${data}
    BuiltIn.Return From Keyword    ${data}

Get Controllers Uuid
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Returns controllers uuid
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${uuid}=    Collections.Get From Dictionary    ${cntl}    _uuid
    BuiltIn.Return From Keyword    ${uuid}

Execute OvsVsctl Show Command
    [Documentation]    Executes ovs-vsctl show command
    SSHLibrary.Write    ${lcmd_prefix} ovs-vsctl show
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}

Set Bridge Controllers
    [Arguments]    ${bridge}    ${controllers}    ${disconnected}=${False}
    [Documentation]    Adds controller to the bridge
    ${cmd}=    BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set-controller ${bridge}
    : FOR    ${cntl}    IN    @{controllers}
    \    ${cmd}=    BuiltIn.Set Variable If    ${disconnected}==${False}    ${cmd} tcp:${cntl}:6653    ${cmd} tcp:${cntl}:6654
    BuiltIn.Log    ${cmd}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}

Disconnect Switch From Controller And Verify Disconnected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}    ${verify_disconnected}=${True}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid    ${switch}    ${controller}
    ${cmd}=    BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6654"
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    Return From Keyword If    ${verify_disconnected}==${False}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Should Be Disconnected    ${switch}    ${controller}    update_data=${True}
    [Teardown]    Execute OvsVsctl Show Command

Reconnect Switch To Controller And Verify Connected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}    ${verify_connected}=${True}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${uuid}=    Get Controllers Uuid    ${switch}    ${controller}
    ${cmd}=    BuiltIn.Set Variable    ${lcmd_prefix} ovs-vsctl set Controller ${uuid} target="tcp\\:${controller}\\:6653"
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read_Until    ${lprompt}
    Log    ${output}
    Return From Keyword If    ${verify_connected}==${False}
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    Should Be Connected    ${switch}    ${controller}    update_data=${True}
    [Teardown]    Execute OvsVsctl Show Command

Should Be Connected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${connected}=    Collections.Get From Dictionary    ${cntl}    is_connected
    BuiltIn.Should Be True    ${connected}
    [Teardown]    Execute OvsVsctl Show Command

Should Be Disconnected
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${connected}=    Collections.Get From Dictionary    ${cntl}    is_connected
    BuiltIn.Should Be Equal    ${connected}    ${False}
    [Teardown]    Execute OvsVsctl Show Command

Should Be Master
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Verifies the master role
    ${role}    Get Node Role    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be Equal    ${role}    master

Should Be Slave
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Verifies the slave role
    ${role}    Get Node Role    ${switch}    ${controller}    update_data=${update_data}
    BuiltIn.Should Be Equal    ${role}    slave

Get Node Role
    [Arguments]    ${switch}    ${controller}    ${update_data}=${False}
    [Documentation]    Returns the controllers role
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntl}=    Collections.Get From Dictionary    ${cntls}    ${controller}
    ${role}=    Collections.Get From Dictionary    ${cntl}    role
    Return From Keyword    ${role}

Get Master Node
    [Arguments]    ${switch}    ${update_data}=${False}
    [Documentation]    Gets controller which is a master
    ${master}=    BuiltIn.Set Variable    ${None}
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    : FOR    ${key}    ${value}    IN    @{cntls_items}
    \    Log    ${key} : ${value}
    \    ${role}=    Collections.Get From Dictionary    ${value}    role
    \    Run Keyword If    "${role}"=="master"    BuiltIn.Should Be Equal    ${master}    ${None}
    \    ${master}=    BuiltIn.Set Variable If    "${role}"=="master"    ${key}    ${master}
    BuiltIn.Should Not Be Equal    ${master}    ${None}
    Return From Keyword    ${master}

Get Follower Nodes
    [Arguments]    ${switch}    ${update_data}=${False}
    [Documentation]    Gets followers nodes
    ${followers}=    BuiltIn.Create List
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    : FOR    ${key}    ${value}    IN    @{cntls_items}
    \    Log    ${key} : ${value}
    \    ${role}=    Collections.Get From Dictionary    ${value}    role
    \    Run Keyword If    "${role}"=="slave"    Collections.Append To List    ${followers}    ${key}
    Return From Keyword    ${followers}

Setup Clustered Controller For Switches
    [Arguments]    ${switches}    ${controller_ips}     ${verify_connected}=${False}
    [Documentation]    The idea of this keyword is to setup clustered controller and to be more or less sure that the role is filled correctly. The problem is when
    ...    more controllers are being set up at once, the role shown in Controller ovsdb table is not the same as we can see from wireshark traces.
    ...    Now we set disconnected controllers and we will connect them expecting that the first connected controller will be master and owner.
    : FOR    ${switch_name}    IN    @{switches}
    \    Set Bridge Controllers    ${switch_name}    ${controller_ips}    disconnected=${True}
    # now we need to enable one node which will be master
    OvsManager.Get Ovsdb Data
    : FOR    ${switch_name}    IN    @{switches}
    \    ${own}    BuiltIn.Evaluate    random.choice(${controller_ips})    modules=random
    \    Reconnect Switch To Controller And Verify Connected    ${switch_name}    ${own}    verify_connected=${False}
    # now we need to wait till master controllers are connected
    BuiltIn.Wait Until Keyword Succeeds    5x    2s    OvsManager__Verify_Leaders_Connected    ${switches}    update_data=${True}
    # now we can enable followers
    OvsManager__Enable_Followers    ${switches}       verify_connected=${verify_connected}

OvsManager__Verify_Leaders_Connected
    [Arguments]    ${switches}    ${update_data}=${False}
    [Documentation]    Private keyword, the existence of master means it is verified
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    : FOR    ${switch_name}    IN    @{switches}
    \    Get Master Node    ${switch_name}

OvsManager__Enable_Followers
    [Arguments]    ${switches}    ${update_data}=${False}     ${verify_connected}=${False}
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    : FOR    ${switch_name}    IN    @{switches}
    \    OvsManager__Enable_Followers_For_Switch    ${switch_name}     verify_connected=${verify_connected}

OvsManager__Enable_Followers_For_Switch
    [Arguments]    ${switch}    ${update_data}=${False}     ${verify_connected}=${False}
    [Documentation]    This is a private keyword
    Run Keyword If    ${update_data}==${True}    Get Ovsdb Data
    ${bridge}=    Collections.Get From Dictionary    ${ovs_switch_data}    ${switch}
    ${cntls_dict}=    Collections.Get From Dictionary    ${bridge}    controller
    ${cntls_items}=    Collections.Get Dictionary Items    ${cntls_dict}
    : FOR    ${cntl_id}    ${cntl_value}    IN    @{cntls_items}
    \    Log    ${cntl_id} : ${cntl_value}
    \    ${role}=    Collections.Get From Dictionary    ${cntl_value}    role
    \    ${connected}=    Collections.Get From Dictionary    ${cntl_value}    is_connected
    \    Run Keyword If    ${connected}==${False}    Reconnect Switch To Controller And Verify Connected    ${switch}    ${cntl_id}    verify_connected=${verify_connected}
