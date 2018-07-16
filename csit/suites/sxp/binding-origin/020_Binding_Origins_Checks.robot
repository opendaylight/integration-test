*** Settings ***
Documentation     Test suite to verify binding origins checks are performed in master database
Suite Setup       Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource         ../../../variables/Variables.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Add Lower Priority Binding
    [Documentation]    Test that incoming binding with lower priority does not override already existing
    ...    higher priority binding in master database
    [Tags]    Binding Origins Checks    SXP

Test Add Higher Priority Binding
    [Documentation]    Test that incoming binding with higher priority overrides already existing
    ...    lower priority binding in master database
    [Tags]    Binding Origins Checks    SXP

Test Add Bindings With Different Priorities
    [Documentation]    Test that when there are two incoming bindings with different priorities only
    ...    the binding with higher priority is added to master database
    [Tags]    Binding Origins Checks    SXP

Test Add Unknown Priority Binding
    [Documentation]    Test that incoming binding with unknown priority cannot be added to master database
    [Tags]    Binding Origins Checks    SXP

*** Keywords ***
Provided precondition
    SxpLib.Clean Bindings    127.0.0.1
    SxpLib.Clean Connections    127.0.0.1
