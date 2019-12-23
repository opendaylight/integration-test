*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment    5
Suite Teardown    Clean SXP Environment    5
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Export Test
    [Documentation]    Test behaviour after shutting down connections in Version4
    [Tags]    SXP    TopoBuiltIn.Logy
    Setup TopoBuiltIn.Logy Triangel    version4
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part One
    SxpLib.Delete Connections    127.0.0.1    64999    127.0.0.3
    SxpLib.Delete Connections    127.0.0.3    64999    127.0.0.1
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part Two
    SxpLib.Delete Connections    127.0.0.1    64999    127.0.0.2
    SxpLib.Delete Connections    127.0.0.2    64999    127.0.0.1
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part Three

Export Test Legacy
    [Documentation]    Test behaviour after shutting down connections in Legacy versions
    [Tags]    SXP    TopoBuiltIn.Logy
    @{list} =    Create List    version1
    FOR    ${version}    IN    @{list}
        Setup TopoBuiltIn.Logy Triangel    ${version}
        BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part One
        SxpLib.Delete Connections    127.0.0.1    64999    127.0.0.3
        SxpLib.Delete Connections    127.0.0.3    64999    127.0.0.1
        BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part Two
        SxpLib.Delete Connections    127.0.0.1    64999    127.0.0.2
        SxpLib.Delete Connections    127.0.0.2    64999    127.0.0.1
        BuiltIn.Wait Until Keyword Succeeds    4    1    Check Export Part Three
        Clean Nodes
    END

Forwarding Test V2=>V1
    [Documentation]    Version 2 => 1 functionality
    [Tags]    SXP    TopoBuiltIn.Logy
    Setup TopoBuiltIn.Logy Linear    version2    version1
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Forwarding V2=>V1

Forwarding Test V3=>V2
    [Documentation]    Version 3 => 2 functionality
    [Tags]    SXP    TopoBuiltIn.Logy
    Setup TopoBuiltIn.Logy Linear    version3    version2
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Forwarding V3=>V2

Forwarding Test V4=>V3
    [Documentation]    Version 4 => 3 functionality
    [Tags]    SXP    TopoBuiltIn.Logy
    Setup TopoBuiltIn.Logy Linear    version4    version3
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Forwarding V4=>V3

Most Recent Rule Test
    [Documentation]    Most Recent Rule
    [Tags]    SXP    TopoBuiltIn.Logy
    Setup TopoBuiltIn.Logy Fork    version4
    SxpLib.Add Bindings    542    5.5.5.5/32    127.0.0.2
    BuiltIn.Sleep    2s
    SxpLib.Add Bindings    543    5.5.5.5/32    127.0.0.3
    SxpLib.Add Bindings    100    15.15.15.15/32    127.0.0.3
    BuiltIn.Sleep    2s
    SxpLib.Add Bindings    99    15.15.15.15/32    127.0.0.2
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Most Recent

Shorthest Path Test
    [Documentation]    Shorthes Path over Most Recent
    [Tags]    SXP    TopoBuiltIn.Logy
    SxpLib.Add Connection    version4    listener    127.0.0.5    64999    127.0.0.3
    SxpLib.Add Connection    version4    speaker    127.0.0.3    64999    127.0.0.5
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    version4    listener    127.0.0.5
    ...    64999    127.0.0.3
    Setup TopoBuiltIn.Logy Fork    version4
    SxpLib.Add Bindings    542    5.5.5.5/32    127.0.0.2
    SxpLib.Add Bindings    545    5.5.5.5/32    127.0.0.5
    SxpLib.Add Bindings    99    15.15.15.15/32    127.0.0.2
    SxpLib.Add Bindings    9954    105.15.125.15/32    127.0.0.5
    SxpLib.Add Bindings    95    15.15.15.15/32    127.0.0.5
    BuiltIn.Wait Until Keyword Succeeds    4    1    Check Shorthest Path

*** Keywords ***
Setup TopoBuiltIn.Logy Triangel
    [Arguments]    ${version}
    [Documentation]    Setup 3 nodes connected to each other
    SxpLib.Add Bindings    542    5.5.5.5/32    127.0.0.2
    SxpLib.Add Bindings    543    5.5.5.5/32    127.0.0.3
    SxpLib.Add Bindings    99    15.15.15.15/32    127.0.0.3
    SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    BuiltIn.Sleep    1s
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.3
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    ...    64999    127.0.0.3

Setup TopoBuiltIn.Logy Linear
    [Arguments]    ${version}    ${r_version}
    [Documentation]    Setup 3 nodes connected linearly
    SxpLib.Add Bindings    6    56.56.56.0/24    127.0.0.2
    SxpLib.Add Bindings    66    9.9.9.9/32    127.0.0.2
    SxpLib.Add Bindings    666    2001:db8:0:0:0:0:1428:57ab/128    127.0.0.2
    SxpLib.Add Bindings    555    2001:db8:85a3:8d3:0:0:0:0/64    127.0.0.2
    SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    SxpLib.Add Connection    ${r_version}    speaker    127.0.0.3    64999    127.0.0.1
    SxpLib.Add Connection    ${r_version}    listener    127.0.0.1    64999    127.0.0.3
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${r_version}    speaker    127.0.0.3

Setup TopoBuiltIn.Logy Fork
    [Arguments]    ${version}
    [Documentation]    Setup 4 nodes in to T topoBuiltIn.Logy
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3
    SxpLib.Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    SxpLib.Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    SxpLib.Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    SxpLib.Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.1
    SxpLib.Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.4
    BuiltIn.Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.4

Check Export Part One
    [Documentation]    Checks if Bindings 542 5.5.5.5/32 is replaced by 543 5.5.5.5/32
    ${resp} =    SxpLib.Get Bindings
    BuiltIn.Log    ${resp}
    SxpLib.Should Contain Binding    ${resp}    543    5.5.5.5/32
    Should Not Contain Binding    ${resp}    542    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32

Check Export Part Two
    [Documentation]    Checks if Bindings 542 5.5.5.5/32 was updated after peer shutdown
    ${resp} =    SxpLib.Get Bindings
    BuiltIn.Log    ${resp}
    Should Not Contain Binding    ${resp}    543    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    542    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32

Check Export Part Three
    [Documentation]    Checks if database is empty after peers shutdown
    ${resp} =    SxpLib.Get Bindings
    BuiltIn.Log    ${resp}
    Should Not Contain Binding    ${resp}    542    5.5.5.5/32
    Should Not Contain Binding    ${resp}    99    15.15.15.15/32

Check Forwarding V2=>V1
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp} =    SxpLib.Get Bindings
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    SxpLib.Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Init OK
    ${resp} =    SxpLib.Get Bindings    127.0.0.3
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    Should Not Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Forward OK

Check Forwarding V3=>V2
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp} =    SxpLib.Get Bindings
    SxpLib.Should Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    SxpLib.Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    SxpLib.Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Init OK
    ${resp} =    SxpLib.Get Bindings    127.0.0.3
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    SxpLib.Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Forward OK

Check Forwarding V4=>V3
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp} =    SxpLib.Get Bindings
    SxpLib.Should Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    SxpLib.Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    SxpLib.Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Init OK
    ${resp} =    SxpLib.Get Bindings    127.0.0.3
    SxpLib.Should Contain Binding    ${resp}    6    56.56.56.0/24
    SxpLib.Should Contain Binding    ${resp}    66    9.9.9.9/32
    SxpLib.Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    SxpLib.Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    BuiltIn.Log    Forward OK

Check Shorthest Path
    [Documentation]    Checks if Shorthest path rule is applied onto bindings
    ${resp} =    SxpLib.Get Bindings
    SxpLib.Should Contain Binding    ${resp}    542    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    9954    105.15.125.15/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    SxpLib.Should Contain Binding    ${resp}    542    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    9954    105.15.125.15/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32

Check Most Recent
    [Documentation]    Checks if MostRecent rule is applied onto bindings
    ${resp} =    SxpLib.Get Bindings
    SxpLib.Should Contain Binding    ${resp}    543    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32
    ${resp} =    SxpLib.Get Bindings    127.0.0.4
    SxpLib.Should Contain Binding    ${resp}    543    5.5.5.5/32
    SxpLib.Should Contain Binding    ${resp}    99    15.15.15.15/32

Clean Nodes
    SxpLib.Clean Bindings    127.0.0.1
    SxpLib.Clean Bindings    127.0.0.2
    SxpLib.Clean Bindings    127.0.0.3
    SxpLib.Clean Bindings    127.0.0.4
    SxpLib.Clean Bindings    127.0.0.5
    SxpLib.Clean Connections    127.0.0.1
    SxpLib.Clean Connections    127.0.0.2
    SxpLib.Clean Connections    127.0.0.3
    SxpLib.Clean Connections    127.0.0.4
    SxpLib.Clean Connections    127.0.0.5
