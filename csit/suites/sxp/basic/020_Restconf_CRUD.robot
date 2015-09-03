*** Settings ***
Documentation     Test suite to verify CRUD operations
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Test Setup        Clean Node
Library           RequestsLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.py

*** Variables ***

*** Test Cases ***
Test Add Binding
    [Documentation]    Test if bindings are added to Master DB
    ${resp}    Get Bindings Master Database
    Add Binding    5230    1.1.1.1/32
    ${resp}    Get Bindings Master Database
    Should Contain Binding    ${resp}    5230    1.1.1.1/32
    Add Binding    30    2001:0:0:0:0:0:0:0/128
    ${resp}    Get Bindings Master Database
    Should Contain Binding    ${resp}    30    2001:0:0:0:0:0:0:0/128

Test Add Connection
    [Documentation]    Test if connections are added to Node
    Add Connection    version4    speaker    10.1.0.0    60000
    ${resp}    Get Connections
    Should Contain Connection    ${resp}    10.1.0.0    60000    speaker    version4
    Add Connection    version1    listener    105.12.0.50    64000
    ${resp}    Get Connections
    Should Contain Connection    ${resp}    105.12.0.50    64000    listener    version1

Test Delete Binding
    [Documentation]    Test if bindings are deleted from Master DB
    Add Binding    52301    12.1.1.1/32
    ${resp}    Get Bindings Master Database
    Should Contain Binding    ${resp}    52301    12.1.1.1/32
    Delete Binding    2631    12.1.1.1/32
    ${resp}    Get Bindings Master Database
    Should Contain Binding    ${resp}    52301    12.1.1.1/32
    Delete Binding    52301    12.1.1.1/32
    ${resp}    Get Bindings Master Database
    Should Not Contain Binding    ${resp}    52301    12.1.1.1/32

Test Delete Connection
    [Documentation]    Test if conncetions are removed from Node
    Add Connection    version4    speaker    127.1.0.30    60000
    ${resp}    Get Connections
    Should Contain Connection    ${resp}    127.1.0.30    60000    speaker    version4
    Delete Connections    127.1.0.30    65000
    ${resp}    Get Connections
    Should Contain Connection    ${resp}    127.1.0.30    60000    speaker    version4
    Delete Connections    127.1.0.30    60000
    ${resp}    Get Connections
    Should Not Contain Connection    ${resp}    127.1.0.30    60000    speaker    version4

Test Update Binding
    [Documentation]    Test if bindings can be updated to different values
    Add Binding    3230    1.1.1.10/32
    ${resp}    Get Bindings Master Database
    Should Contain Binding    ${resp}    3230    1.1.1.10/32
    Update Binding    3230    1.1.1.10/32    623    10.10.10.10/32
    ${resp}    Get Bindings Master Database
    Should Not Contain Binding    ${resp}    3230    1.1.1.10/32
    Should Contain Binding    ${resp}    623    10.10.10.10/32

*** Keywords ***
Clean Node
    Clean Connections    127.0.0.1
    Clean Bindings    127.0.0.1
