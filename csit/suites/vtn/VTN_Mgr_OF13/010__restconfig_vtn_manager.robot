*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaRestConfTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

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

Add a flowcondition in restconfig
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition In Restconfig

Get flowcondition
    [Documentation]    Retrieve the flowcondition by name
    Get flowcondition In Restconfig    cond_1    retrieve

Get flowconditions
    [Documentation]    Retrieve the list of flowconditions
    Get flowconditions In Restconfig

Remove flowcondition
    [Documentation]    Remove the flowcondition by name
    Remove flowcondition In Restconfig    cond_1

Get flowcondition After Remove
    [Documentation]    Verify the removed flowcondition
    Get flowcondition In Restconfig    cond_1    retrieve_after_remove
