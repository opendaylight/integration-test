*** Settings ***
Documentation     Test suite for VTN Manager using OF13
Suite Setup       Start SuiteVtnMaTest
Suite Teardown    Stop SuiteVtnMaTest
Resource          ../../../libraries/VtnMaKeywords.robot

*** Test Cases ***

Add a flowcondition in restconfig
    [Documentation]    Create a flowcondition cond_1 using restconfig api
    Add a flowcondition    cond_1

Get flowcondition
    [Documentation]    Retrieve the flowcondition by name
    Get flowcondition    cond_1    retrieve

Get flowconditions
    [Documentation]    Retrieve the list of flowconditions
    Get flowconditions

Remove flowcondition
    [Documentation]    Remove the flowcondition by name
    Remove flowcondition    cond_1

Get flowcondition After Remove
    [Documentation]    Verify the removed flowcondition
    Get flowcondition    cond_1    retrieve_after_remove
