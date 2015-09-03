*** Settings ***
Documentation     Test suite to test connectivity problems
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Version 1
    [Documentation]    Test if Version1 <=> Version1 can be connected
    Test Nodes    version1    none    version1
    Log    OK without passwords
    Clean Nodes
    Test Nodes    version1    default    version1
    Log    OK with passwords

Version 2
    [Documentation]    Test if Version2 <=> Version2 can be connected
    Test Nodes    version2    none    version2
    Log    OK without passwords
    Clean Nodes
    Test Nodes    version2    default    version2

Version 3
    [Documentation]    Test if Version3 <=> Version3 can be connected
    Test Nodes    version3    none    version3
    Log    OK without passwords
    Clean Nodes
    Test Nodes    version3    default    version3

Version 4
    [Documentation]    Test if Version4 <=> Version4 can be connected
    Test Nodes    version4    none    version4
    Log    OK without passwords
    Clean Nodes
    Test Nodes    version4    default    version4

Mixed Versions
    [Documentation]    Test of version negotiation proces during connecting
    @{list} =    Create List    version2    version3    version4
    Test Nodes    version1    none    @{list}
    Test Nodes    version1    default    @{list}
    @{list} =    Create List    version1    version3    version4
    Test Nodes    version2    none    @{list}
    Test Nodes    version2    default    @{list}
    @{list} =    Create List    version1    version2    version4
    Test Nodes    version3    none    @{list}
    Test Nodes    version3    default    @{list}
    @{list} =    Create List    version1    version2    version3
    Test Nodes    version4    none    @{list}
    Test Nodes    version4    default    @{list}

*** Keywords ***
Test Nodes
    [Arguments]    ${version}    ${PASSWORD}    @{versions}
    [Documentation]    Setup connection Speaker => Listener / Listener => Speaker / Both <=> Both for specific versions
    : FOR    ${r_version}    IN    @{versions}
    \    ${cmp_version}    Lower Version    ${r_version}    ${version}
    \    Log    ${r_version}
    \    Add Connection    ${r_version}    listener    127.0.0.2    64999    127.0.0.1
    \    ...    ${PASSWORD}
    \    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    \    ...    ${PASSWORD}
    \    Wait Until Keyword Succeeds    15    4    Verify Connection    ${cmp_version}    listener
    \    ...    127.0.0.2    64999    127.0.0.1
    \    Wait Until Keyword Succeeds    15    4    Verify connection    ${cmp_version}    speaker
    \    ...    127.0.0.1    64999    127.0.0.2
    \    Log    OK ${r_version}:listener ${version}:speaker
    \    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.3
    \    ...    ${PASSWORD}
    \    Add Connection    ${r_version}    speaker    127.0.0.3    64999    127.0.0.2
    \    ...    ${PASSWORD}
    \    Wait Until Keyword Succeeds    15    4    Verify Connection    ${cmp_version}    listener
    \    ...    127.0.0.2    64999    127.0.0.3
    \    Wait Until Keyword Succeeds    15    4    Verify connection    ${cmp_version}    speaker
    \    ...    127.0.0.3    64999    127.0.0.2
    \    Log    OK ${version}:listener ${r_version}:speaker
    \    Run Keyword If    '${version}' == 'version4' and '${r_version}' == 'version4'    Test Both    ${version}    ${r_version}    ${PASSWORD}
    \    Clean Nodes

Test Both
    [Arguments]    ${version}    ${r_version}    ${PASSWORD}
    [Documentation]    Setup Both <=> Both connection
    ${cmp_version}    Lower Version    ${r_version}    ${version}
    Add Connection    ${r_version}    both    127.0.0.3    64999    127.0.0.1    ${PASSWORD}
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.3    ${PASSWORD}
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${cmp_version}    both    127.0.0.3
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    4    Verify Connection    ${cmp_version}    both    127.0.0.1
    ...    64999    127.0.0.3
    Log    OK ${r_version}:both ${version}:both

Verify Connection
    [Arguments]    ${version}    ${mode}    ${ip}    ${port}    ${node}    ${state}=on
    [Documentation]    Verify that connection is ON
    ${resp}    Get Connections    ${node}
    Should Contain Connection    ${resp}    ${ip}    ${port}    ${mode}    ${version}    ${state}

Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
