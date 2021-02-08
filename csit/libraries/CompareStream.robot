*** Settings ***
Documentation     This Resource contains list of Keywords Set_Variable_If_At_Least*, Set_Variable_If_At_Most,
...               Run_Keyword_If_At_Least*, Run_Keyword_If_At_Most*,
...               Run_Keyword_If_More_Than*, Run_Keyword_If_Less_Than*,
...               for comparison ${ODL_STREAM} to the given ${lower_bound},
...               in order to replace ad-hoc conditional execution in suites.
Library           Collections
Library           String

*** Variables ***
&{Stream_dict}    carbon=${6}    nitrogen=${7}    oxygen=${8}    fluorine=${9}    neon=${10}    sodium=${11}    magnesium=${12}    aluminium=${13}    silicon=${14}

*** Keywords ***
Set_Variable_If_At_Least
    [Arguments]    ${lower_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${lower_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most
    [Arguments]    ${upper_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most ${upper_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    ${Stream_dict}[${ODL_STREAM}] <= ${Stream_dict}[${upper_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Carbon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least carbon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    carbon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Nitrogen
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least nitrogen,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    nitrogen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Oxygen
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least oxygen,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    oxygen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Fluorine
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least fluorine,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    fluorine    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Neon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least neon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    neon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Sodium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least sodium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    sodium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Magnesium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is atleast magnesium, return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    magnesium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Aluminium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare aluminium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is atleast aluminium, return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    aluminium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Silicon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare silicon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is atleast silicon, return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    silicon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Carbon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most carbon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    carbon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Nitrogen
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most nitrogen,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    nitrogen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Oxygen
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most oxygen,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    oxygen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Fluorine
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most fluorine,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    fluorine    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Neon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most neon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    neon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Sodium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most sodium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    sodium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Magnesium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most magnesium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    magnesium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Aluminium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare aluminium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most aluminium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    aluminium    ${value_if_true}    ${value_if_false}

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
    FOR    ${arg}    IN    @{arguments}
        ${arg}    BuiltIn.Convert_To_String    ${arg}
        ${removed}    String.Remove_String    ${arg}    \n    ${Space}    \t
        ...    \r
        ${splitted}    BuiltIn.Run_Keyword_If    "${removed[0]}" == "<"    BuiltIn.Create List    ${arg}
        ...    ELSE    String.Split_String    ${arg}    separator==    max_split=1
        ${len}    BuiltIn.Get_Length    ${splitted}
        Run Keyword If    ${len}==1    Collections.Append_To_List    ${args}    ${splitted}[0]
        ...    ELSE    Collections.Set_To_Dictionary    ${kwargs}    @{splitted}
    END
    BuiltIn.Return_From_Keyword    ${args}    ${kwargs}

Run_Keyword_If_At_Least
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

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
    ${resp}    BuiltIn.Run_Keyword_If    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]    @{args_if}    &{kwargs_if}
    ...    ELSE    @{args_else}    &{kwargs_else}
    [Return]    ${resp}

Run_Keyword_If_At_Most
    [Arguments]    ${upper_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    ${Stream_dict}[${ODL_STREAM}] <= ${Stream_dict}[${upper_bound}]    ${kw_name}    @{varargs}    &{kwargs}

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
    ${resp}    BuiltIn.Run_Keyword_If    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]    @{args_if}    &{kwargs_if}
    ...    ELSE    @{args_else}    &{kwargs_else}
    [Return]    ${resp}

Run_Keyword_If_More_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is more than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    ${Stream_dict}[${ODL_STREAM}] > ${Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Equals
    [Arguments]    ${stream}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${stream} to ${ODL_STREAM} and in case ${ODL_STREAM} equals ${stream},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    ${Stream_dict}[${ODL_STREAM}] == ${Stream_dict}[${stream}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Equals_Else
    [Arguments]    ${stream}    @{varargs}
    [Documentation]    Compare ${stream} to ${ODL_STREAM} and in case ${ODL_STREAM} equals ${stream},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    BuiltIn.Run_Keyword_If    "${position}" == "-1"    BuiltIn.Fail    Missing else statement in defined expresion
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    ${resp}    BuiltIn.Run_Keyword_If    ${Stream_dict}[${ODL_STREAM}] == ${Stream_dict}[${stream}]    @{args_if}    &{kwargs_if}
    ...    ELSE    @{args_else}    &{kwargs_else}
    [Return]    ${resp}

Run_Keyword_If_Less_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is less than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    ${Stream_dict}[${ODL_STREAM}] < ${Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Nitrogen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is at least nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Oxygen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is at least oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Fluorine
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at least fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Neon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Sodium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Magnesium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Aluminium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Nitrogen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is at most nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Oxygen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is at most oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Fluorine
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at most fluroine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Neon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Sodium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Magnesium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Aluminium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Nitrogen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is more than nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Oxygen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is more than oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Fluorine
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is more than fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Neon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Sodium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Magnesium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Aluminium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Nitrogen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is less than nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Oxygen
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is less than oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Fluorine
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is less than fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Neon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Sodium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Magnesium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    magnesium    ${kw_name}    @{varargs}    &{kwargs}
