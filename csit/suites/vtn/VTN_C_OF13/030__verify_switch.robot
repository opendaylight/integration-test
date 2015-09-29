*** Settings ***
Documentation     Test suite for VTN Coordinator
Suite Setup       Start SuiteVtnCoTest
Suite Teardown    Stop SuiteVtnCoTest
Resource          ../../../libraries/VtnCoKeywords.robot

*** Test Cases ***
Add a ODL Controller
    [Documentation]    Add a Controller odc1
    Add a Controller    odc_test    ${CONTROLLER}

Verify the Controller Status is waiting_audit
    [Documentation]    Check Controller status
    Wait Until Keyword Succeeds    12s    2s    Check Controller Status    odc_test    waiting_audit

Audit a controller
    [Documentation]    Trigger update audit
    Audit Controller    odc_test

Verify switch1
    [Documentation]    Get switch1
    [Tags]    exclude
    Verify Switch    odc_test    openflow:1

Verify switch2
    [Documentation]    Get switch2
    [Tags]    exclude
    Verify Switch    odc_test    openflow:2

Verify switch3
    [Documentation]    Get switch3
    [Tags]    exclude
    Verify Switch    odc_test    openflow:3

Verify switchPort switch1
    [Documentation]    Get switchport/switch1
    Verify SwitchPort    odc_test    openflow:1

Verify switchPort switch2
    [Documentation]    Get switchport/switch2
    Verify SwitchPort    odc_test    openflow:2

Verify switchPort switch3
    [Documentation]    Get switchport/switch3
    Verify SwitchPort    odc_test    openflow:3

Delete a Controller
    [Documentation]    Delete Controller odc1
    Remove Controller    odc_test
