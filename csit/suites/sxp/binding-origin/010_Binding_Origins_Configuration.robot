*** Settings ***
Documentation     Test suite to verify binding origins configuration possibilities (CRUD)
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource         ../../../variables/Variables.robot
Resource          ../../../libraries/SxpBindingOriginsLib.robot

*** Test Cases ***
Test Initial Binding Origins
    [Documentation]    Test that default binding origins are present in configuration
    [Tags]    Binding Origins CRUD    SXP

Test Add Binding Origin
    [Documentation]    Test if binding origin is added to configuration
    [Tags]    Binding Origins CRUD    SXP

Test Add Binding Origin With Already Used Origin Type
    [Documentation]    Test if binding origin with already used origin type cannot be added to configuration
    [Tags]    Binding Origins CRUD    SXP

Test Add Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin with already used priotity cannot be added to configuration
    [Tags]    Binding Origins CRUD    SXP

Test Update Binding Origin
    [Documentation]    Test if binding origin is updated in configuration
    [Tags]    Binding Origins CRUD    SXP

Test Update Binding Origin With Already Used Origin Type
    [Documentation]    Test if binding origin cannot be updated to use origin type of another binding origin
    [Tags]    Binding Origins CRUD    SXP

Test Update Binding Origin With Already Used Priority
    [Documentation]    Test if binding origin cannot be updated to use priority of another binding origin
    [Tags]    Binding Origins CRUD    SXP

Test Delete Binding Origin
    [Documentation]    Test if binding origin is deleted from configuration
    [Tags]    Binding Origins CRUD    SXP

Test Delete Default Binding Origin
    [Documentation]    Test that default binding origin cannot deleted from configuration
    [Tags]    Binding Origins CRUD    SXP

*** Keywords ***
Provided precondition
    SxpBindingOriginsLib.Clean Binding Origins
