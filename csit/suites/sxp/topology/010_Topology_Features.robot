*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Export Test
    [Documentation]    Test behaviour after shutting down connections in Version4
    Setup Topology Triangel    version4
    Wait Until Keyword Succeeds    4    1    Check Export Part One
    Delete Connections    127.0.0.1    64999    127.0.0.3
    Delete Connections    127.0.0.3    64999    127.0.0.1
    Wait Until Keyword Succeeds    4    1    Check Export Part Two
    Delete Connections    127.0.0.1    64999    127.0.0.2
    Delete Connections    127.0.0.2    64999    127.0.0.1
    Wait Until Keyword Succeeds    4    1    Check Export Part Three

Export Test Legacy
    [Documentation]    Test behaviour after shutting down connections in Legacy versions
    @{list} =    Create List    version1
    : FOR    ${version}    IN    @{list}
    \    Setup Topology Triangel    ${version}
    \    Wait Until Keyword Succeeds    4    1    Check Export Part One
    \    Delete Connections    127.0.0.1    64999    127.0.0.3
    \    Delete Connections    127.0.0.3    64999    127.0.0.1
    \    Wait Until Keyword Succeeds    4    1    Check Export Part Two
    \    Delete Connections    127.0.0.1    64999    127.0.0.2
    \    Delete Connections    127.0.0.2    64999    127.0.0.1
    \    Wait Until Keyword Succeeds    4    1    Check Export Part Three
    \    Clean Nodes

Forwarding Test V2=>V1
    [Documentation]    Version 2 => 1 functionality
    Setup Topology Linear    version2    version1
    Wait Until Keyword Succeeds    4    1    Check Forwarding V2=>V1

Forwarding Test V3=>V2
    [Documentation]    Version 3 => 2 functionality
    Setup Topology Linear    version3    version2
    Wait Until Keyword Succeeds    4    1    Check Forwarding V3=>V2

Forwarding Test V4=>V3
    [Documentation]    Version 4 => 3 functionality
    Setup Topology Linear    version4    version3
    Wait Until Keyword Succeeds    4    1    Check Forwarding V4=>V3

Most Recent Rule Test
    [Documentation]    Most Recent Rule
    Setup Topology Fork    version4
    Add Binding    542    5.5.5.5/32    127.0.0.2
    Sleep    2s
    Add Binding    543    5.5.5.5/32    127.0.0.3
    Add Binding    100    15.15.15.15/32    127.0.0.3
    Sleep    2s
    Add Binding    99    15.15.15.15/32    127.0.0.2
    Sleep    1s
    ${resp}    Get Bindings
    Should Contain Binding    ${resp}    543    5.5.5.5/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32
    ${resp}    Get Bindings    127.0.0.4
    Should Contain Binding    ${resp}    543    5.5.5.5/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32

Shorthest Path Test
    [Documentation]    Shorthes Path over Most Recent
    Add Connection    version4    listener    127.0.0.5    64999    127.0.0.3
    Add Connection    version4    speaker    127.0.0.3    64999    127.0.0.5
    Wait Until Keyword Succeeds    15    1    Verify Connection    version4    listener    127.0.0.5
    ...    64999    127.0.0.3
    Setup Topology Fork    version4
    Add Binding    542    5.5.5.5/32    127.0.0.2
    Add Binding    545    5.5.5.5/32    127.0.0.5
    Add Binding    99    15.15.15.15/32    127.0.0.2
    Add Binding    9954    105.15.125.15/32    127.0.0.5
    Add Binding    95    15.15.15.15/32    127.0.0.5
    Wait Until Keyword Succeeds    4    1    Check Shorthest Path

*** Keywords ***
Setup Topology Triangel
    [Arguments]    ${version}
    [Documentation]    Setup 3 nodes connected to each other
    Add Binding    542    5.5.5.5/32    127.0.0.2
    Add Binding    543    5.5.5.5/32    127.0.0.3
    Add Binding    99    15.15.15.15/32    127.0.0.3
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    Sleep    1s
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.3
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    ...    64999    127.0.0.3

Setup Topology Linear
    [Arguments]    ${version}    ${r_version}
    [Documentation]    Setup 3 nodes connected linearly
    Add Binding    6    56.56.56.0/24    127.0.0.2
    Add Binding    66    9.9.9.9/32    127.0.0.2
    Add Binding    666    2001:db8:0:0:0:0:1428:57ab/128    127.0.0.2
    Add Binding    555    2001:db8:85a3:8d3:0:0:0:0/64    127.0.0.2
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    Add Connection    ${r_version}    speaker    127.0.0.3    64999    127.0.0.1
    Add Connection    ${r_version}    listener    127.0.0.1    64999    127.0.0.3
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${r_version}    speaker    127.0.0.3

Setup Topology Fork
    [Arguments]    ${version}
    [Documentation]    Setup 4 nodes in to T topology
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.1
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.4
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.4

Check Export Part One
    [Documentation]    Checks if Bindings 542 5.5.5.5/32 is replaced by 543 5.5.5.5/32
    ${resp}    Get Bindings
    log    ${resp}
    Should Contain Binding    ${resp}    543    5.5.5.5/32
    Should Not Contain Binding    ${resp}    542    5.5.5.5/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32

Check Export Part Two
    [Documentation]    Checks if Bindings 542 5.5.5.5/32 was updated after peer shutdown
    ${resp}    Get Bindings
    log    ${resp}
    Should Not Contain Binding    ${resp}    543    5.5.5.5/32
    Should Contain Binding    ${resp}    542    5.5.5.5/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32

Check Export Part Three
    [Documentation]    Checks if database is empty after peers shutdown
    ${resp}    Get Bindings
    log    ${resp}
    Should Not Contain Binding    ${resp}    542    5.5.5.5/32
    Should Not Contain Binding    ${resp}    99    15.15.15.15/32

Check Forwarding V2=>V1
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp}    Get Bindings
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24    sxp
    Should Contain Binding    ${resp}    66    9.9.9.9/32    sxp
    Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128    sxp
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64    sxp
    Log    Init OK
    ${resp}    Get Bindings    127.0.0.3
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24    sxp
    Should Contain Binding    ${resp}    66    9.9.9.9/32    sxp
    Should Not Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128    sxp
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64    sxp
    Log    Forward OK

Check Forwarding V3=>V2
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp}    Get Bindings
    Should Contain Binding    ${resp}    6    56.56.56.0/24    sxp
    Should Contain Binding    ${resp}    66    9.9.9.9/32    sxp
    Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128    sxp
    Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64    sxp
    Log    Init OK
    ${resp}    Get Bindings    127.0.0.3
    Should Not Contain Binding    ${resp}    6    56.56.56.0/24    sxp
    Should Contain Binding    ${resp}    66    9.9.9.9/32    sxp
    Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128    sxp
    Should Not Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64    sxp
    Log    Forward OK

Check Forwarding V4=>V3
    [Documentation]    Check if appropriate bindings are exported per version
    ${resp}    Get Bindings
    Should Contain Binding    ${resp}    6    56.56.56.0/24
    Should Contain Binding    ${resp}    66    9.9.9.9/32
    Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128
    Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64
    Log    Init OK
    ${resp}    Get Bindings    127.0.0.3
    Should Contain Binding    ${resp}    6    56.56.56.0/24    sxp
    Should Contain Binding    ${resp}    66    9.9.9.9/32    sxp
    Should Contain Binding    ${resp}    666    2001:db8:0:0:0:0:1428:57ab/128    sxp
    Should Contain Binding    ${resp}    555    2001:db8:85a3:8d3:0:0:0:0/64    sxp
    Log    Forward OK

Check Shorthest Path
    [Documentation]    Checks if Shorthest path rule is applied onto bindings
    ${resp}    Get Bindings
    Should Contain Binding    ${resp}    542    5.5.5.5/32
    Should Contain Binding    ${resp}    9954    105.15.125.15/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32
    ${resp}    Get Bindings    127.0.0.4
    Should Contain Binding    ${resp}    542    5.5.5.5/32
    Should Contain Binding    ${resp}    9954    105.15.125.15/32
    Should Contain Binding    ${resp}    99    15.15.15.15/32

Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
    Clean Connections    127.0.0.4
    Clean Connections    127.0.0.5
    Clean Bindings    127.0.0.1
    Clean Bindings    127.0.0.2
    Clean Bindings    127.0.0.3
    Clean Bindings    127.0.0.4
    Clean Bindings    127.0.0.5
