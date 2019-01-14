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
Test Add Bindings
    [Documentation]    Test if bindings are added to Master DB
    [Tags]    Restconf CRUD    SXP
    ${resp}    Get Bindings
    Add Bindings    5230    1.1.1.1/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    5230    1.1.1.1/32
    Add Bindings    30    2001:0:0:0:0:0:0:0/128
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    30    2001:0:0:0:0:0:0:0/128

Test Update Bindings
    [Documentation]    Test if bindings can be updated to different SGT values by new incoming bindings for the same IP prefix
    [Tags]    Restconf CRUD    SXP
    Add Bindings    30    1.1.1.10/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    30    1.1.1.10/32
    Sleep    1s    New binding must be at least 1s newer
    Add Bindings    40    1.1.1.10/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Not Contain    30    1.1.1.10/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    40    1.1.1.10/32

Test Delete Bindings
    [Documentation]    Test if bindings are deleted from Master DB
    [Tags]    Restconf CRUD    SXP
    Add Bindings    52301    12.1.1.1/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    52301    12.1.1.1/32
    Run Keyword And Expect Error    *    Delete Bindings    2631    12.1.1.1/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Contain    52301    12.1.1.1/32
    Delete Bindings    52301    12.1.1.1/32
    Wait Until Keyword Succeeds    30x    1s    Bindings Should Not Contain    52301    12.1.1.1/32

Test Add Connection
    [Documentation]    Test if connections are added to Node
    [Tags]    Restconf CRUD    SXP
    Add Connection    version4    speaker    10.1.0.0    60000
    Wait Until Keyword Succeeds    30x    1s    Connections Should Contain    10.1.0.0    60000    speaker
    ...    version4
    Add Connection    version1    listener    105.12.0.50    64000
    Wait Until Keyword Succeeds    30x    1s    Connections Should Contain    105.12.0.50    64000    listener
    ...    version1

Test Delete Connection
    [Documentation]    Test if conncetions are removed from Node
    [Tags]    Restconf CRUD    SXP
    Add Connection    version4    speaker    127.1.0.30    60000
    Wait Until Keyword Succeeds    30x    1s    Connections Should Contain    127.1.0.30    60000    speaker
    ...    version4
    Run Keyword And Expect Error    *    Delete Connections    127.1.0.30    65000
    Wait Until Keyword Succeeds    30x    1s    Connections Should Contain    127.1.0.30    60000    speaker
    ...    version4
    Delete Connections    127.1.0.30    60000
    Wait Until Keyword Succeeds    30x    1s    Connections Should Not Contain    127.1.0.30    60000    speaker
    ...    version4

*** Keywords ***
Clean Node
    Clean Bindings    127.0.0.1
    Clean Connections    127.0.0.1
