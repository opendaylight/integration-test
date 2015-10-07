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
    KarafKeywords.Log_Test_Suite_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Fast_Failing
    [Documentation]    Test case setup which skips on previous failure. If not, logs test case name to Karaf log.
    ...    Recommended to be used as the default test case setup.
    FailFast.Fail_This_Fast_On_Previous_Error
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Without_Fast_Failing
    [Documentation]    Test case setup which explicitly ignores previous failure and logs test case name to Karaf log.
    ...    Needed if the recommended default is to be overriden.
    FailFast.Run_Even_When_Failing_Fast
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
