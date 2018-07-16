*** Settings ***
Documentation     Test suite to verify binding origins checks are performed in master database
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/SxpBindingOriginsLib.robot

*** Test Cases ***
Test Add Lower Priority Binding
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    LOCAL
    # try to add binding with lower priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that previous binding is preserved
    ${binindgs}    SxpLib.Get Bindings
    SxpLib.Bindings Should Contain    10    1.1.1.1/32
    SxpLib.Bindings Should Not Contain    20    1.1.1.1/32

Test Add Higher Priority Binding
    [Documentation]    Test that incoming binding with higher priority overrides already existing
    ...    lower priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    NETWORK
    # add binding with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL
    # verify that new binding replaced previous binding
    ${binindgs}    SxpLib.Get Bindings
    SxpLib.Bindings Should Not Contain    10    1.1.1.1/32
    SxpLib.Bindings Should Contain    20    1.1.1.1/32

Test Add Unknown Priority Binding
    [Documentation]    Test that incoming binding with unknown priority cannot be added to master database
    [Tags]    Binding Origins Checks    SXP
    # try to add binding with unknown origin priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    10    1.1.1.1/32    CLUSTER
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that binding is not in master database
    ${binindgs}    SxpLib.Get Bindings
    SxpLib.Bindings Should Not Contain    10    1.1.1.1/32    CLUSTER
    
Test Add Lower Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    # create custom domain with bindings
    SxpLib.Add Domain    guest    10    1.1.1.1/32    LOCAL
    # try add bindings to custom domain with lower priority
    ${status}    BuiltIn.Run Keyword And Return Status    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK    domain=guest
    BuiltIn.Should Be Equal As Strings    False    ${status}
    # verify that previous binding is preserved
    ${binindgs}    SxpLib.Get Bindings    127.0.0.1    session    guest    all
    SxpLib.Bindings Should Contain    10    1.1.1.1/32
    SxpLib.Bindings Should Not Contain    20    1.1.1.1/32
     

Test Add Higher Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    # create custom domain with bindings
    SxpLib.Add Domain    guest    10    1.1.1.1/32    NETWORK
    # add bindings to custom domain with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL domain=guest
    # verify that new binding replaced previous binding
    ${binindgs}    SxpLib.Get Bindings    127.0.0.1    session    guest    all
    SxpLib.Bindings Should Not Contain    10    1.1.1.1/32
    SxpLib.Bindings Should Contain    20    1.1.1.1/32

*** Keywords ***
Provided precondition
    SxpLib.Clean Bindings    127.0.0.1
    SxpLib.Clean Connections    127.0.0.1
