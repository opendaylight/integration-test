*** Settings ***
Documentation     Test suite to test connectivity problems
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment     4
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Version 1
    [Documentation]    Test of custom passwords on version1 connections
    [Tags]    SXP    Passwords
    Test Mode    version1    listener    speaker
    Clean Nodes
    Test Mode    version1    speaker    listener

Version 2
    [Documentation]    Test of custom passwords on version2 connections
    [Tags]    SXP    Passwords
    Test Mode    version2    listener    speaker
    Clean Nodes
    Test Mode    version2    speaker    listener

Version 3
    [Documentation]    Test of custom passwords on version3 connections
    [Tags]    SXP    Passwords
    Test Mode    version3    listener    speaker
    Clean Nodes
    Test Mode    version3    speaker    listener

Version 4
    [Documentation]    Test of custom passwords on version4 connections
    [Tags]    SXP    Passwords
    Test Mode    version4    speaker    listener
    Clean Nodes
    Test Mode    version4    listener    speaker
    Clean Nodes
    Test Mode    version4    both    both

*** Keywords ***
Setup SXP Environment
    [Documentation]    Create session to Controller
    Setup SXP Sesion
    Add Node    127.0.0.1    ${EMPTY}
    Add Node    127.0.0.2    ${EMPTY}
    Add Node    127.0.0.3    CUSTOM

Test Mode
    [Arguments]    ${version}    ${mode_local}    ${mode_remote}
    [Documentation]    Setup connection Speaker => Listener / Listener => Speaker / Both <=> Both for specific versions
    Add Connection    ${version}    ${mode_local}    127.0.0.3    64999    127.0.0.1    CUSTOM
    Add Connection    ${version}    ${mode_remote}    127.0.0.1    64999    127.0.0.3    ${EMPTY}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_local}    127.0.0.3
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_remote}    127.0.0.1
    ...    64999    127.0.0.3
    Add Connection    ${version}    ${mode_local}    127.0.0.2    64999    127.0.0.1    ${EMPTY}
    Add Connection    ${version}    ${mode_remote}    127.0.0.1    64999    127.0.0.2    ${EMPTY}
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_local}    127.0.0.2
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_remote}    127.0.0.1
    ...    64999    127.0.0.2
    Add Connection    ${version}    ${mode_local}    127.0.0.3    64999    127.0.0.2    CUSTOM_2
    Add Connection    ${version}    ${mode_remote}    127.0.0.2    64999    127.0.0.3    CUSTOM_2
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_local}    127.0.0.3
    ...    64999    127.0.0.2
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    ${mode_remote}    127.0.0.2
    ...    64999    127.0.0.3

Clean Nodes
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
