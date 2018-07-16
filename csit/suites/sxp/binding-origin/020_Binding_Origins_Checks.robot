*** Settings ***
Documentation     Test suite to verify binding origins checks are performed in master database
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Add Lower Priority Binding
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    [Setup]    Clean Bindings
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    LOCAL
    # try to add binding with lower priority
    BuiltIn.Run Keyword And Expect Error    RPC result is False    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK
    # verify that new binding is not added and previous binding is preserved
    Verify Bindings Content    10    20    1.1.1.1/32

Test Add Higher Priority Binding
    [Documentation]    Test that incoming binding with higher priority overrides already existing
    ...    lower priority binding in master database for the same IP prefix
    [Tags]    Binding Origins Checks    SXP
    [Setup]    Clean Bindings
    # add binding
    SxpLib.Add Bindings    10    1.1.1.1/32    NETWORK
    # add binding with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL
    # verify that new binding replaced previous binding
    Verify Bindings Content    20    10    1.1.1.1/32

Test Add Unknown Priority Binding
    [Documentation]    Test that incoming binding with unknown priority cannot be added to master database
    [Tags]    Binding Origins Checks    SXP
    [Setup]    Clean Bindings
    # try to add binding with unknown origin priority
    BuiltIn.Run Keyword And Expect Error    RPC result is False    SxpLib.Add Bindings    10    1.1.1.1/32    CLUSTER
    # verify that binding is not in master database
    SxpLib.Bindings Should Not Contain    10    1.1.1.1/32

Test Add Lower Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [Setup]    Clean Bindings
    # create custom domain with binding
    SxpLib.Add Domain    guest    10    1.1.1.1/32    LOCAL
    # try add binding to custom domain with lower priority
    BuiltIn.Run Keyword And Expect Error    RPC result is False    SxpLib.Add Bindings    20    1.1.1.1/32    NETWORK        domain=guest
    # verify that new binding is not added and previous binding is preserved
    Verify Bindings Content    10    20    1.1.1.1/32    guest

Test Add Higher Priority Binding To Domain
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database for the same IP prefix
    [Setup]    Clean Bindings
    # create custom domain with binding
    SxpLib.Add Domain    guest    10    1.1.1.1/32    NETWORK
    # add binding to custom domain with higher priority
    SxpLib.Add Bindings    20    1.1.1.1/32    LOCAL    domain=guest
    # verify that new binding replaced previous binding
    Verify Bindings Content    20    10    1.1.1.1/32    guest

Test Get Bindings
    [Documentation]    Test that when requesting for LOCAL bindings then only LOCAL bindings are returned
    [Setup]    Clean Bindings
    # add LOCAL binding
    SxpLib.Add Bindings    10    1.1.1.1/32    LOCAL
    # add NETWORK binding
    SxpLib.Add Bindings    20    2.2.2.2/32    NETWORK
    # verify request for LOCAL bindings
    Verify Local Bindings Contain    10    1.1.1.1/32     But Not    20    2.2.2.2/32
    # verify request for ALL bindings
    Verify All Bindings Contain    10    1.1.1.1/32     And    20    2.2.2.2/32

*** Keywords ***
Clean Bindings
    SxpLib.Clean Bindings    scope=all
    SxpLib.Clean Bindings    domain=guest scope=all

Verify Bindings Content
    ${should_contains_sgt}    ${should_not_contains_sgt}    ${prefix}    ${domain}=global
    ${bindings}    SxpLib.Get Bindings    domain=domain    scope=all
    SxpLib.Should Contain Binding    ${should_contains_sgt}    ${prefix}
    SxpLib.Should Not Contain Binding    ${should_not_contains_sgt}    ${prefix}

Verify Local Bindings Contain    ${should_contains_sgt}    ${should_contains_prefix}    But Not    ${should_not_contains_sgt}    ${should_not_contains_prefix}
    ${bindings}    SxpLib.Get Bindings    domain=domain    scope=local
    SxpLib.Should Contain Binding    ${bindings.json()}    ${should_contains_sgt}    ${should_contains_prefix}
    SxpLib.Should Not Contain Binding    ${bindings.json()}    ${should_not_contains_sgt}    ${should_not_contains_prefix}

Verify All Bindings Contain    ${should_contains_sgt}    ${should_contains_prefix}     And    ${next_should_contains_sgt}    ${next_should_contains_prefix}
    ${bindings}    SxpLib.Get Bindings    domain=domain    scope=all
    SxpLib.Should Contain Binding    ${bindings.json()}    ${should_contains_sgt}    ${should_contains_prefix}
    SxpLib.Should Contain Binding    ${bindings.json()}    ${next_should_contains_sgt}    ${next_should_contains_prefix}
