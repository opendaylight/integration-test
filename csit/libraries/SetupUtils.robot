*** Settings ***
Documentation     Simple resource with setup keywords which combine FailFast and Karaf logging.
...
...               See FailFast.robot documentation for intricacies of that library.
Resource          ${CURDIR}/FailFast.robot
Resource          ${CURDIR}/KarafKeywords.robot
Resource          ${CURDIR}/Utils.robot

*** Variables ***
${SetupUtils__Known_Bug_ID}    ${EMPTY}

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

Set_Known_Bug_Id
    [Arguments]    ${id}
    [Documentation]    Tell the Teardown keywords that any failure from now on is due to the specified known bug.
    Set_Suite_Variable    ${SetupUtils__Known_Bug_ID}    ${id}

Set_Unknown_Bug_Id
    [Documentation]    Tell the Teardown keywords that from now on there is no longer known bug causing the failure so it should use linked bugs.
    Set_Known_Bug_Id    ${EMPTY}

SetupUtils__Report_Bugs_Causing_Failure
    BuiltIn.Run_Keyword_If    '${SetupUtils__Known_Bug_ID}' != ''    Utils.Report_Failure_Due_To_Bug    ${SetupUtils__Known_Bug_ID}
    BuiltIn.Run_Keyword_And_Return_If    '${SetupUtils__Known_Bug_ID}' != ''    Set_Known_Bug_Id    ${EMPTY}
    Utils.Report_Failure_And_Point_To_Linked_Bugs

Teardown_Test_Show_Bugs_And_Start_Fast_Failing_If_Test_Failed
    [Documentation]    Test case teardown. Show linked bugs and start fast failing in case of failure.
    BuiltIn.Run_Keyword_If_Test_Failed    BuiltIn.Set_Suite_Variable    ${SuiteFastFail}    True
    SetupUtils__Report_Bugs_Causing_Failure

Teardown_Test_Show_Bugs_If_Test_Failed
    [Documentation]    Test case teardown. Show linked bugs in case of failure.
    SetupUtils__Report_Bugs_Causing_Failure
