*** Settings ***
Documentation     Test suite to verify CRUD operations
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Teardown     Clean Node
Library           RequestsLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot

*** Variables ***

*** Test Cases ***
Test Add Binding
    [Documentation]    Test if bindings are added to Master DB
    [Tags]    Restconf CRUD    SXP
    ${resp}    Get Bindings
    Add Binding    5230    1.1.1.1/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    5230    1.1.1.1/32
    Add Binding    30    2001:0:0:0:0:0:0:0/128
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    30    2001:0:0:0:0:0:0:0/128

Test Add Connection
    [Documentation]    Test if connections are added to Node
    [Tags]    Restconf CRUD    SXP
    Add Connection    version4    speaker    10.1.0.0    60000
    Wait Until Keyword Succeeds    3x    250ms    Connections Should Contain    10.1.0.0    60000    speaker    version4
    Add Connection    version1    listener    105.12.0.50    64000
    Wait Until Keyword Succeeds    3x    250ms    Connections Should Contain    105.12.0.50    64000    listener    version1

Test Delete Binding
    [Documentation]    Test if bindings are deleted from Master DB
    [Tags]    Restconf CRUD    SXP
    Add Binding    52301    12.1.1.1/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    52301    12.1.1.1/32
    Run Keyword And Expect Error    *    Delete Binding    2631    12.1.1.1/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    52301    12.1.1.1/32
    Delete Binding    52301    12.1.1.1/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Not Contain    52301    12.1.1.1/32

Test Delete Connection
    [Documentation]    Test if conncetions are removed from Node
    [Tags]    Restconf CRUD    SXP
    Add Connection    version4    speaker    127.1.0.30    60000
    Wait Until Keyword Succeeds    3x    250ms    Connections Should Contain    127.1.0.30    60000    speaker    version4
    Run Keyword And Expect Error    *    Delete Connections    127.1.0.30    65000
    Wait Until Keyword Succeeds    3x    250ms    Connections Should Contain    127.1.0.30    60000    speaker    version4
    Delete Connections    127.1.0.30    60000
    Wait Until Keyword Succeeds    3x    250ms    Connections Should Not Contain    127.1.0.30    60000    speaker    version4

Test Update Binding
    [Documentation]    Test if bindings can be updated to different values
    [Tags]    Restconf CRUD    SXP
    Add Binding    3230    1.1.1.10/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    3230    1.1.1.10/32
    Update Binding    3230    1.1.1.10/32    623    10.10.10.10/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Not Contain    3230    1.1.1.10/32
    Wait Until Keyword Succeeds    3x    250ms    Bindings Should Contain    623    10.10.10.10/32

*** Keywords ***
Clean Node
    Clean Bindings    127.0.0.1
    Clean Connections    127.0.0.1
