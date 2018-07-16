*** Settings ***
Documentation     Test suite to verify binding origins checks are performed in master database
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Add Lower Priority Binding
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    [SETUP]    Clean Bindings
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    LOCAL
    # try to add binding with lower priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that previous binding is preserved
    ${bindings}    SxpLib.Get Bindings
    SxpLib.Should Contain Binding    ${bindings}    10    1.1.1.1/32
    SxpLib.Should Not Contain Binding    ${bindings}    20    1.1.1.1/32

Test Add Higher Priority Binding
    [Documentation]    Test that incoming binding with higher priority overrides already existing
    ...    lower priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    [SETUP]    Clean Bindings
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    NETWORK
    # add binding with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL
    # verify that new binding replaced previous binding
    ${bindings}    SxpLib.Get Bindings
    SxpLib.Should Not Contain Binding    ${bindings}    10    1.1.1.1/32
    SxpLib.Should Contain Binding    ${bindings}    20    1.1.1.1/32

Test Add Unknown Priority Binding
    [Documentation]    Test that incoming binding with unknown priority cannot be added to master database
    [Tags]    Binding Origins Checks    SXP
    [SETUP]    Clean Bindings
    # try to add binding with unknown origin priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    10    1.1.1.1/32    CLUSTER
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that binding is not in master database
    SxpLib.Bindings Should Not Contain    10    1.1.1.1/32
    
Test Add Lower Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [SETUP]    Clean Bindings
    # create custom domain with bindings
    SxpLib.Add Domain    guest    10    1.1.1.1/32    LOCAL
    # try add bindings to custom domain with lower priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK    127.0.0.1    session    guest
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that previous binding is preserved
    ${bindings}    SxpLib.Get Bindings    127.0.0.1    session    guest    all
    SxpLib.Should Contain Binding    ${bindings}    10    1.1.1.1/32
    SxpLib.Should Not Contain Binding    ${bindings}    20    1.1.1.1/32
     

Test Add Higher Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [SETUP]    Clean Bindings
    # create custom domain with bindings
    SxpLib.Add Domain    guest    10    1.1.1.1/32    NETWORK
    # add bindings to custom domain with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL    127.0.0.1    session    guest
    # verify that new binding replaced previous binding
    ${bindings}    SxpLib.Get Bindings    127.0.0.1    session    guest    all
    SxpLib.Should Not Contain Binding    ${bindings}    10    1.1.1.1/32
    SxpLib.Should Contain Binding    ${bindings}    20    1.1.1.1/32
    
*** Keywords ***
Clean Bindings
    SxpLib.Clean Bindings
    SxpLib.Clean Bindings    127.0.0.1    session    guest
