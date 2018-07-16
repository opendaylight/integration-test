*** Settings ***
Documentation     Test suite to verify binding origins configuration possibilities (CRUD)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/SxpBindingOriginsLib.robot
Library           ../../../libraries/Sxp.py

*** Variables ***
@{DEFAULT_ORIGINS}    LOCAL    NETWORK
@{CLUSTER}        CLUSTER

*** Test Cases ***
Test Add Binding Origin
    [Documentation]    Test if binding origin is added to configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0
    ${origins}    SxpBindingOriginsLib.Get Binding Origins
    ${expected}    Collections.Combine Lists    ${DEFAULT_ORIGINS}    ${CLUSTER}
    SxpBindingOriginsLib.Should Contain Binding Origins    ${origins.json()}    @{expected}

Test Add Binding Origin With Already Used Origin Type
    [Documentation]    Test if binding origin with already used origin type cannot be added to configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Add Binding Origin    LOCAL    0
    BuiltIn.Should Be Equal As Strings    False    ${status}

Test Add Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin with already used priotity cannot be added to configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    1
    BuiltIn.Should Be Equal As Strings    False    ${status}

Test Update Binding Origin
    [Documentation]    Test if binding origin is updated in configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    SxpBindingOriginsLib.Update Binding Origin    LOCAL    0
    ${origins}    SxpBindingOriginsLib.Get Binding Origins
    SxpBindingOriginsLib.Should Contain Binding Origins    ${origins.json()}    @{DEFAULT_ORIGINS}

Test Update Binding Origin With Missing Origin Type
    [Documentation]    Test if unknown origin cannot be updated
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Update Binding Origin    CLUSTER    1
    BuiltIn.Should Be Equal As Strings    False    ${status}

Test Update Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin cannot be updated to use priority of another binding origin
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Update Binding Origin    LOCAL    2
    BuiltIn.Should Be Equal As Strings    False    ${status}

Test Delete Binding Origin
    [Documentation]    Test if binding origin is deleted from configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    # add CLUSTER origin and verify it is added
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0
    ${origins}    SxpBindingOriginsLib.Get Binding Origins
    ${expected}    Collections.Combine Lists    ${DEFAULT_ORIGINS}    ${CLUSTER}
    SxpBindingOriginsLib.Should Contain Binding Origins    ${origins.json()}    @{expected}

    # delete CLUSTER origin
    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER
    # verify default origins are preserved
    ${origins}    SxpBindingOriginsLib.Get Binding Origins
    SxpBindingOriginsLib.Should Contain Binding Origins    ${origins.json()}    @{DEFAULT_ORIGINS}
    # verify that CLUSTER origin is no more present
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Should Contain Binding Origins    ${resp.json()}    CLUSTER
    BuiltIn.Should Be Equal As Strings    False    ${status}

Test Delete Default Binding Origin
    [Documentation]    Test that default binding origin cannot be deleted from configuration
    [Tags]    Binding Origins CRUD    SXP
    [Setup]    SxpBindingOriginsLib.Clean Binding Origins
    # try to delete default origin
    ${status}    BuiltIn.Run Keyword And Return Status    SxpBindingOriginsLib.Delete Binding Origin    LOCAL
    BuiltIn.Should Be Equal As Strings    False    ${status}

    # verify all default origins are preserved
    ${origins}    SxpBindingOriginsLib.Get Binding Origins
    SxpBindingOriginsLib.Should Contain Binding Origins    ${origins.json()}    @{DEFAULT_ORIGINS}
