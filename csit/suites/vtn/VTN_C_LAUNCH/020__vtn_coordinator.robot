*** Settings ***
Documentation       Test suite for VTN Coordinator

Resource            ../../../libraries/VtnCoKeywords.robot

Suite Setup         Start SuiteVtnCoTest
Suite Teardown      Stop SuiteVtnCoTest


*** Test Cases ***
Test if VTNC is ready
    [Documentation]    Get Coordinator Version
    BuiltIn.Wait_Until_Keyword_Succeeds    20    5    Get Coordinator Version
