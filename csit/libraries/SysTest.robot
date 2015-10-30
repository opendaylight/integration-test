*** Keywords ***
Initialize
    ${status}=    BuiltIn.Run_Keyword_And_Return_Status    BuiltIn.Fail    MAGIC_KEYWORD_ASKING_SYSTEST_TO_ENABLE_ITSELF
    Return_From_Keyword_If    ${status}
    ${msg}=    BuiltIn.Set_Variable    ${EMPTY}
    ${msg}=    BuiltIn.Set_Variable    ${msg}\nFailed to initialize system infrastructure testing support. This
    ${msg}=    BuiltIn.Set_Variable    ${msg}\nmeans that for some reason the suite is run by plain vanilla Robot
    ${msg}=    BuiltIn.Set_Variable    ${msg}\nFramework which lacks the system infrastructure support. To fix this
    ${msg}=    BuiltIn.Set_Variable    ${msg}\nproblem put the "enable_systest.sh" script into the script plan of
    ${msg}=    BuiltIn.Set_Variable    ${msg}\nthe Jenkins job that is trying to run this test suite.
    BuiltIn.Fatal_Error    ${msg}

Simulate_Failure
    [Arguments]    ${message}
    BuiltIn.Fail    SIMULATE_FAILURE_BUT_DO_NOT_ACTUALLY_FAIL
    BuiltIn.Pass_Execution    ${message}

Reset_Failure_Simulation
    BuiltIn.Fail    RESET_FAKE_FAILURE_FLAG_IF_SET_OR_DO_NOTHING
    BuiltIn.Run_Keyword_If_Test_Failed    BuiltIn.Return_From_Keyword
    BuiltIn.Set_Test_Message    ${EMPTY}
