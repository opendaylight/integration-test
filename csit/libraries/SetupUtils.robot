*** Settings ***
Resource          ${CURDIR}/FailFast.robot
Resource          ${CURDIR}/KarafKeywords.robot

*** Keywords ***
Setup_Utils_For_Setup_And_Teardown
    FailFast.Do_Not_Fail_Fast_From_Now_On
    KarafKeywords.Open_Controller_Karaf_Console
    KarafKeywords.Log_Test_Suite_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Fast_Failing
    FailFast.Fail_This_Fast_On_Previous_Error
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf

Setup_Test_With_Logging_And_Without_Fast_Failing
    FailFast.Run_Even_When_Failing_Fast
    KarafKeywords.Log_Testcase_Start_To_Controller_Karaf
