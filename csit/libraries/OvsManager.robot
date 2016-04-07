*** Settings ***
Documentation
Library           SSHLibrary
Library           ${CURDIR}/VsctlListParser.py

*** Variables ***
${SH_BR_CMD}      ovs-vsctl list Bridge
${SH_CNTL_CMD}     ovs-vsctl list Controller
${ovs_data}       ${None}
${lprompt}         mininet>
${lcmd_prefix}     sh

*** Keywords ***
Initialize If Shell Used
    [Arguments]     ${prompt}      ${cmd_prefix}
    BuiltIn.Set Suite variable   ${lprompt}     ${prompt}
    BuiltIn.Set Suite variable   ${lcmd_prefix}     ${cmd_prefix}

Get Ovsdb Data
    [Atguments]     ${prompt}=mininet>
    [Documentation]    Gets ovs data and parse them.
    SSHLibrary.Write    ${lcmd_prefix} ${SH_BR_CMD}
    ${brstdout}=  SSHLibrary.Read_Until     ${lprompt}
    Log    ${brstdout}
    SSHLibrary.Write    ${lcmd_prefix} ${SH_CNTL_CMD}
    ${cntlstdout}=  SSHLibrary.Read_Until    ${lprompt}
    Log    ${cntlstdout}
    ${data}    ${bridegs}     ${controllers}=     VsctlListParser.Parse    ${brstdout}      ${cntlstdout}
    BuiltIn.Log    ${data}
    BuiltIn.Set Suite Variable   ${ovs_data}      ${data}
    BuiltIn.Return From Keyword     ${data}

Disconnect Switch From Controller
    [Arguments]    ${switch}    ${controller}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    [Setup]      Get Ovsdb Data
    BuiltIn.No Action

Reconnect Switch To Controller
    [Arguments]    ${switch}    ${controller}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    [Setup]      Get Ovsdb Data
    BuiltIn.No Action

Should Be Connected
    [Arguments]    ${switch}    ${controller}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    [Setup]      Get Ovsdb Data
    BuiltIn.No Action

Should Be Master
    [Arguments]    ${switch}    ${controller}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    [Setup]      Get Ovsdb Data
    BuiltIn.No Action

Should Be Slave
    [Arguments]    ${switch}    ${controller}
    [Documentation]    This will set the destination port to 6654 which causes switch disconnection
    [Setup]      Get Ovsdb Data
    BuiltIn.No Action

