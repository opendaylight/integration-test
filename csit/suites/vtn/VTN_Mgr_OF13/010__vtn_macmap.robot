*** Settings ***
Documentation       Test suite for VTN Manager using OF13

Resource            ../../../libraries/VtnMaKeywords.robot

Suite Setup         Start SuiteVtnMaTest
Suite Teardown      Stop SuiteVtnMaTest


*** Test Cases ***
Check if switch1 detected
    [Documentation]    Check if openflow:1 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    12    3    Fetch vtn switch inventory    openflow:1

Check if switch2 detected
    [Documentation]    Check if openflow:2 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:2

Check if switch3 detected
    [Documentation]    Check if openflow:3 is detected
    BuiltIn.Wait_Until_Keyword_Succeeds    3    1    Fetch vtn switch inventory    openflow:3

Add a vtn Tenant1
    [Documentation]    Add a vtn Tenant1
    Add a vtn    Tenant1

Add a vBridge vBridge1
    [Documentation]    Add a vBridge vBridge1 in vtn Tenant1
    Add a vBridge    Tenant1    vBridge1

Add a macmap for bridge1
    [Documentation]    Add a macmap for bridge1 in vtn Tenant1
    ${source}=    Get DynamicMacAddress    h1
    ${destination}=    Get DynamicMacAddress    h3
    Add a macmap    Tenant1    vBridge1    ${source}    ${destination}

Get macmapflow h3 h1
    [Documentation]    ping h3 to h1
    Wait Until Keyword Succeeds    20s    1s    Mininet Ping Should Succeed    h3    h1

Delete a vtn Tenant1
    [Documentation]    Delete a vtn Tenant1
    Delete a vtn    Tenant1
