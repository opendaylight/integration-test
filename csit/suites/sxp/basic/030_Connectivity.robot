*** Settings ***
Documentation     Test suite to test connectivity problems
Suite Setup       SxpLib.Setup SXP Environment    5
Suite Teardown    SxpLib.Clean SXP Environment    5
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Version 1
    [Documentation]    Test if Version1 <=> Version1 can be connected
    [Tags]    SXP    Connectivity
    Test Nodes    version1    none    version1
    BuiltIn.Log    OK without passwords
    Test Nodes    version1    default    version1
    BuiltIn.Log    OK with passwords

Version 2
    [Documentation]    Test if Version2 <=> Version2 can be connected
    [Tags]    SXP    Connectivity
    Test Nodes    version2    none    version2
    BuiltIn.Log    OK without passwords
    Test Nodes    version2    default    version2
    BuiltIn.Log    OK with passwords

Version 3
    [Documentation]    Test if Version3 <=> Version3 can be connected
    [Tags]    SXP    Connectivity
    Test Nodes    version3    none    version3
    BuiltIn.Log    OK without passwords
    Test Nodes    version3    default    version3
    BuiltIn.Log    OK with passwords

Version 4
    [Documentation]    Test if Version4 <=> Version4 can be connected
    [Tags]    SXP    Connectivity
    Test Nodes    version4    none    version4
    BuiltIn.Log    OK without passwords
    Test Nodes    version4    default    version4
    BuiltIn.Log    OK with passwords

Mixed Versions
    [Documentation]    Test of version negotiation proces during connecting
    [Tags]    SXP    Connectivity
    @{list} =    BuiltIn.Create List    version2    version3    version4
    Test Nodes    version1    none    @{list}
    Test Nodes    version1    default    @{list}
    @{list} =    BuiltIn.Create List    version1    version3    version4
    Test Nodes    version2    none    @{list}
    Test Nodes    version2    default    @{list}
    @{list} =    BuiltIn.Create List    version1    version2    version4
    Test Nodes    version3    none    @{list}
    Test Nodes    version3    default    @{list}
    @{list} =    BuiltIn.Create List    version1    version2    version3
    Test Nodes    version4    none    @{list}
    Test Nodes    version4    default    @{list}

*** Keywords ***
Test Nodes
    [Arguments]    ${version}    ${PASSWORD}    @{versions}
    [Documentation]    Setup connection Speaker => Listener / Listener => Speaker / Both <=> Both for specific versions
    FOR    ${r_version}    IN    @{versions}
        ${cmp_version}    Lower Version    ${r_version}    ${version}
        BuiltIn.Log    ${r_version}
        SxpLib.Add Connection    ${r_version}    listener    127.0.0.2    64999    127.0.0.1
        ...    ${PASSWORD}
        SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
        ...    ${PASSWORD}
        BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    listener
        ...    127.0.0.2    64999    127.0.0.1
        BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    speaker
        ...    127.0.0.1    64999    127.0.0.2
        BuiltIn.Log    OK ${r_version}:listener ${version}:speaker
        SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.3
        ...    ${PASSWORD}
        SxpLib.Add Connection    ${r_version}    speaker    127.0.0.3    64999    127.0.0.2
        ...    ${PASSWORD}
        BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    listener
        ...    127.0.0.2    64999    127.0.0.3
        BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    speaker
        ...    127.0.0.3    64999    127.0.0.2
        BuiltIn.Log    OK ${version}:listener ${r_version}:speaker
        BuiltIn.Run Keyword If    '${version}' == 'version4' and '${r_version}' == 'version4'    Test Both    ${version}    ${r_version}    ${PASSWORD}
        Clean Nodes
    END

Test Both
    [Arguments]    ${version}    ${r_version}    ${PASSWORD}
    [Documentation]    Setup Both <=> Both connection
    ${cmp_version}    Sxp.Lower Version    ${r_version}    ${version}
    SxpLib.Add Connection    ${r_version}    both    127.0.0.3    64999    127.0.0.1    ${PASSWORD}
    SxpLib.Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.3    ${PASSWORD}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    both    127.0.0.3
    ...    64999    127.0.0.1
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpLib.Verify Connection    ${cmp_version}    both    127.0.0.1
    ...    64999    127.0.0.3
    BuiltIn.Log    OK ${r_version}:both ${version}:both

Clean Nodes
    SxpLib.Clean Connections    127.0.0.1
    SxpLib.Clean Connections    127.0.0.2
    SxpLib.Clean Connections    127.0.0.3
