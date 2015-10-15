*** Settings ***
Documentation     Unit test suite to ScalarClosures library.
Suite Setup       SCT_Setup
Resource          ${CURDIR}/../../libraries/ScalarClosures.robot

*** Test Cases ***
Identity_Closure_Defined
    [Documentation]    An identity closure is created, comparison shows it is equal to a variable set in library setup.
    ${actual} =    BuiltIn.Set_Variable    ${ScalarClosures__identity}
    ${expected} =    ScalarClosures.Closure_From_Keyword_And_Arguments    BuiltIn.Set_Variable    placeholder
    BuiltIn.Should_Be_Equal    ${actual}    ${expected}

Zero_Args_No_Kwargs_Execution_Test
    [Documentation]    The identity closure is run as is, the placeholder is visible.
    ${actual} =    ScalarClosures.Run_Closure_As_Is    ${ScalarClosures__identity}
    BuiltIn.Should_Be_Equal    ${actual}    placeholder

One_Arg_No_Kwargs_Execution_Test
    [Documentation]    The identity closure is run with rerplaced argument, the value is visible.
    ${actual} =    ScalarClosures.Run_Closure_After_Replacing_First_Argument    ${ScalarClosures__identity}    first_value
    BuiltIn.Should_Be_Equal    ${actual}    first_value

Two_Args_No_Kwargs_Execution_Test
    [Documentation]    Closure which puts two placeholders into list is created, run with substitution shows new values in list.
    ${closure} =    ScalarClosures.Closure_From_Keyword_And_Arguments    BuiltIn.Set_Variable    first_placeholder    second_placeholder
    ${actual} =    ScalarClosures.Run_Closure_After_Replacing_First_Two_Arguments    ${closure}    first_value    second_value
    ${expected} =    BuiltIn.Set_Variable    first_value    second_value
    BuiltIn.Should_Be_Equal    ${actual}    ${expected}

One_Kwarg_Nested_In_Zero_Args_Execution_Test
    [Documentation]    Inner closure takes kwarg, outer closure runs it as is. Result shows execution chain went well and kwarg was processed.
    ${inner_closure} =    ScalarClosures.Closure_From_Keyword_And_Arguments    BuiltIn.Create_Dictionary    foo=bar
    ${outer_closure} =    ScalarClosures.Closure_From_Keyword_And_Arguments    ScalarClosures.Run_Closure_As_Is    ${inner_closure}
    ${actual} =    ScalarClosures.Run_Closure_As_Is    ${outer_closure}
    ${expected} =    BuiltIn.Create_Dictionary    foo=bar
    BuiltIn.Should_Be_Equal    ${actual}    ${expected}

*** Keywords ***
SCT_Setup
    [Documentation]    Call ScalarClosures setup.
    ScalarClosures.SC_Setup
