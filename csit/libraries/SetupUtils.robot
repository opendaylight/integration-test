*** Settings ***
Documentation     Simple resource with setup keywords which combine FailFast and Karaf logging.
...
...               See FailFast.robot documentation for intricacies of that library.
Resource          ${CURDIR}/FailFast.robot
Resource          ${CURDIR}/KarafKeywords.robot

*** Keywords ***
Setup_Utils_For_Setup_And_Teardown
    [Documentation]    Prepare both FailFast and karaf logging, to be used in suite setup.
    FailFast.Do_Not_Fail_Fast_From_Now_On
    KarafKeywords.Open_Controller_Karaf_Console_On_Background
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Test_Suite_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Fast_Failing
    [Documentation]    Test case setup which skips on previous failure. If not, logs test case name to Karaf log.
    ...    Recommended to be used as the default test case setup.
    FailFast.Fail_This_Fast_On_Previous_Error
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Without_Fast_Failing
    [Documentation]    Test case setup which explicitly ignores previous failure and logs test case name to Karaf log.
    ...    Needed if the recommended default is to be overriden.
    FailFast.Run_Even_When_Failing_Fast
    BuiltIn.Run Keyword And Ignore Error    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
    [Documentation]    Test case teardown. Show linked bugs and start fast failing in case of failure.
    BuiltIn.Run_Keyword_If_Test_Failed    BuiltIn.Set_Suite_Variable    ${SuiteFastFail}    True
    ${reason}=    String.Get_Lines_Containing_String    ${TEST_MESSAGE}    SKIPPED
    ${skipped}=    String.Get_Line_Count    ${reason}
    BuiltIn.Run_Keyword_If    ${skipped} == 0    Utils.Report_Failure_And_Point_To_Linked_Bugs

Teardown_Test_Show_Bugs_If_Test_Failed
    [Documentation]    Test case teardown. Show linked bugs in case of failure.
    ${reason}=    String.Get_Lines_Containing_String    ${TEST_MESSAGE}    SKIPPED
    ${skipped}=    String.Get_Line_Count    ${reason}
    BuiltIn.Run_Keyword_If    ${skipped} == 0    Utils.Report_Failure_And_Point_To_Linked_Bugs

