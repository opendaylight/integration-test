*** Settings ***
Documentation     This Resource contains list of Keywords Set_Variable_If_At_Least*, Set_Variable_If_At_Most,
...               Run_Keyword_If_At_Least*, Run_Keyword_If_At_Most*,
...               Run_Keyword_If_More_Than*, Run_Keyword_If_Less_Than*,
...               for comparison ${ODL_STREAM} to the given ${lower_bound},
...               in order to replace ad-hoc conditional execution in suites.
Library           Collections
Library           String

*** Variables ***
&{Stream_dict}    carbon=${6}    nitrogen=${7}    oxygen=${8}    fluorine=${9}    neon=${10}    sodium=${11}

*** Keywords ***
Set_Variable_If_At_Least
    [Arguments]    ${lower_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${lower_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_${branch}
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${branch},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    ${branch}    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most
    [Arguments]    ${upper_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most ${upper_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[${upper_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_${branch}
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most ${branch},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    ${branch}    ${value_if_true}    ${value_if_false}

Run_Keyword_If_At_Least
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_${branch}
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${branch},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    ${branch}    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most
    [Arguments]    ${upper_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[${upper_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_${branch}
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${branch},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    ${branch}    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is more than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] > &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_${branch}
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and in case ${ODL_STREAM} is more than ${branch},run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    ${branch}    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is less than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] < &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_${branch}
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${branch} to ${ODL_STREAM} and in case ${ODL_STREAM} is less than ${branch},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    ${branch}    ${kw_name}    @{varargs}    &{kwargs}

CompareStream__Convert_Input
    [Arguments]    @{arguments}
    [Documentation]    Splits arguments into args and kwargs is used in Run_Keyword_If_At_Least_Else and Run_Keyword_If_At_Most_Else.
    ...    The problem is, when the string contains =, but it is not a named argument (name=value). There can be many values containing =, but
    ...    for sure it is present in xmls. If the string starts with "<" it will be treated as it is xml and splitting for
    ...    name and value will not be executed.
    ...    If named argument is passed into this kw, only string data are supported e.g. name=string. Complex variables such as lists or dictionaries
    ...    are not supported.
    ${args}    BuiltIn.Create_List
    ${kwargs}    BuiltIn.Create_Dictionary
    : FOR    ${arg}    IN    @{arguments}
    \    ${arg}    BuiltIn.Convert_To_String    ${arg}
    \    ${removed}    String.Remove_String    ${arg}    \n    ${Space}    \t
    \    ...    \r
    \    ${splitted}    BuiltIn.Run_Keyword_If    "${removed[0]}" == "<"    BuiltIn.Create List    ${arg}
    \    ...    ELSE    String.Split_String    ${arg}    separator==    max_split=1
    \    ${len}    BuiltIn.Get_Length    ${splitted}
    \    Run Keyword If    ${len}==1    Collections.Append_To_List    ${args}    @{splitted}[0]
    \    ...    ELSE    Collections.Set_To_Dictionary    ${kwargs}    @{splitted}
    BuiltIn.Return_From_Keyword    ${args}    ${kwargs}

Run_Keyword_If_At_Least_Else
    [Arguments]    ${lower_bound}    @{varargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    BuiltIn.Run_Keyword_If    "${position}" == "-1"    BuiltIn.Fail    Missing else statement in defined expresion
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    ${resp}    BuiltIn.Run_Keyword_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    @{args_if}    &{kwargs_if}
    ...    ELSE    @{args_else}    &{kwargs_else}
    [Return]    ${resp}

Run_Keyword_If_At_Most_Else
    [Arguments]    ${upper_bound}    @{varargs}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    BuiltIn.Run_Keyword_If    "${position}" == "-1"    BuiltIn.Fail    Missing else statement in defined expresion
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    ${resp}    BuiltIn.Run_Keyword_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    @{args_if}    &{kwargs_if}
    ...    ELSE    @{args_else}    &{kwargs_else}
    [Return]    ${resp}

Run_Keyword_If_Equals
    [Arguments]    ${stream}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${stream} to ${ODL_STREAM} and in case ${ODL_STREAM} equals ${stream},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] == &{Stream_dict}[${stream}]    ${kw_name}    @{varargs}    &{kwargs}
