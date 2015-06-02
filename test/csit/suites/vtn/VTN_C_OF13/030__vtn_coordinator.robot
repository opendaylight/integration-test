*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Start SuiteVtnCoTest
Suite Teardown    Stop SuiteVtnCoTest
Resource          ../../../libraries/VtnCoKeywords.txt

*** Test Cases ***
Add a ODL Controller
    [Documentation]    Add a Controller odc1
    [Tags]    exclude
    Add a Controller    odc_test    ${CONTROLLER}

Verify the Controller Status is up
    [Documentation]    Check Controller status
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Check Controller Status    odc_test    up

Verify switch1
    [Documentation]    Get switch1
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify Switch    odc_test    00:00:00:00:00:00:00:01

Verify switch2
    [Documentation]    Get switch2
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify Switch    odc_test    00:00:00:00:00:00:00:02

Verify switch3
    [Documentation]    Get switch3
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify Switch    odc_test    00:00:00:00:00:00:00:03

Verify switchPort switch1
    [Documentation]    Get switchport/switch1
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify SwitchPort    odc_test    00:00:00:00:00:00:00:01

Verify switchPort switch2
    [Documentation]    Get switchport/switch2
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify SwitchPort    odc_test    00:00:00:00:00:00:00:02

Verify switchPort switch3
    [Documentation]    Get switchport/switch3
    [Tags]    exclude
    Wait Until Keyword Succeeds    30s    2s    Verify SwitchPort    odc_test    00:00:00:00:00:00:00:03

Delete a Controller
    [Documentation]    Delete Controller odc1
    [Tags]    exclude
    Remove Controller    odc_test
