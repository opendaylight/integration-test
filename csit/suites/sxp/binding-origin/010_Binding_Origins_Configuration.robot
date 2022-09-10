*** Settings ***
Documentation       Test suite to verify binding origins configuration possibilities (CRUD)

Library             RequestsLibrary
Resource            ../../../libraries/SxpBindingOriginsLib.robot

Suite Setup         SxpLib.Setup SXP Environment    0
Suite Teardown      SxpLib.Clean SXP Environment    0
Test Setup          SxpBindingOriginsLib.Revert To Default Binding Origins Configuration


*** Variables ***
@{DEFAULT_ORIGINS}          LOCAL    NETWORK
@{CLUSTER}                  CLUSTER
@{DEFAULT_AND_CLUSTER}      LOCAL    NETWORK    CLUSTER


*** Test Cases ***
Test Add Binding Origin
    [Documentation]    Test if binding origin is added to configuration
    [Tags]    binding origins crud    sxp
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0
    SxpBindingOriginsLib.Should Contain Binding Origins    @{DEFAULT_AND_CLUSTER}

Test Add Binding Origin With Already Used Origin Type
    [Documentation]    Test if binding origin with already used origin type cannot be added to configuration
    [Tags]    binding origins crud    sxp
    BuiltIn.Run Keyword And Expect Error
    ...    RPC result is False
    ...    SxpBindingOriginsLib.Add Binding Origin
    ...    LOCAL
    ...    0

Test Add Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin with already used priotity cannot be added to configuration
    [Tags]    binding origins crud    sxp
    BuiltIn.Run Keyword And Expect Error
    ...    RPC result is False
    ...    SxpBindingOriginsLib.Add Binding Origin
    ...    CLUSTER
    ...    1

Test Update Binding Origin
    [Documentation]    Test if binding origin is updated in configuration
    [Tags]    binding origins crud    sxp
    BuiltIn.Comment    Update default origin
    SxpBindingOriginsLib.Update Binding Origin    LOCAL    0
    BuiltIn.Comment    Verify that LOCAL origin priority is updated
    SxpBindingOriginsLib.Should Contain Binding Origin With Priority    LOCAL    0

Test Update Binding Origin Of Unknown Origin Type
    [Documentation]    Test if unknown origin cannot be updated
    [Tags]    binding origins crud    sxp
    BuiltIn.Run Keyword And Expect Error
    ...    RPC result is False
    ...    SxpBindingOriginsLib.Update Binding Origin
    ...    CLUSTER
    ...    0

Test Update Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin cannot be updated to use priority of another binding origin
    [Tags]    binding origins crud    sxp
    BuiltIn.Run Keyword And Expect Error
    ...    RPC result is False
    ...    SxpBindingOriginsLib.Update Binding Origin
    ...    LOCAL
    ...    2

Test Delete Binding Origin
    [Documentation]    Test if binding origin is deleted from configuration
    [Tags]    binding origins crud    sxp
    BuiltIn.Comment    Add CLUSTER origin and verify it is added
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0
    SxpBindingOriginsLib.Should Contain Binding Origins    @{DEFAULT_AND_CLUSTER}
    BuiltIn.Comment    Delete CLUSTER origin
    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER
    BuiltIn.Comment    Verify that CLUSTER origin is no more present
    SxpBindingOriginsLib.Should Not Contain Binding Origins    CLUSTER

Test Delete Default Binding Origin
    [Documentation]    Test that default binding origin cannot be deleted from configuration
    [Tags]    binding origins crud    sxp
    BuiltIn.Comment    Try to delete default origin
    BuiltIn.Run Keyword And Expect Error    RPC result is False    SxpBindingOriginsLib.Delete Binding Origin    LOCAL
    BuiltIn.Comment    Verify all default origins are preserved
    SxpBindingOriginsLib.Should Contain Binding Origins    @{DEFAULT_ORIGINS}
