*** Settings ***
Documentation       This Resource contains list of Keywords Set_Variable_If_At_Least*, Set_Variable_If_At_Most,
...                 Run_Keyword_If_At_Least*, Run_Keyword_If_At_Most*,
...                 Run_Keyword_If_More_Than*, Run_Keyword_If_Less_Than*,
...                 for comparison ${ODL_STREAM} to the given ${lower_bound},
...                 in order to replace ad-hoc conditional execution in suites.

Library             Collections
Library             String


*** Variables ***
&{Stream_dict}
...                 carbon=${6}
...                 nitrogen=${7}
...                 oxygen=${8}
...                 fluorine=${9}
...                 neon=${10}
...                 sodium=${11}
...                 magnesium=${12}
...                 aluminium=${13}
...                 silicon=${14}
...                 phosphorus=${15}
...                 sulfur=${16}
...                 chlorine=${17}
...                 master=${999}


*** Keywords ***
Set_Variable_If_At_Least
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${lower_bound},
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${lower_bound}    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return
    ...    BuiltIn.Set_Variable_If
    ...    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]
    ...    ${value_if_true}
    ...    ${value_if_false}

Set_Variable_If_At_Most
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most ${upper_bound},
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${upper_bound}    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return
    ...    BuiltIn.Set_Variable_If
    ...    ${Stream_dict}[${ODL_STREAM}] <= ${Stream_dict}[${upper_bound}]
    ...    ${value_if_true}
    ...    ${value_if_false}

Set_Variable_If_At_Least_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least carbon,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    carbon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least nitrogen,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    nitrogen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least oxygen,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    oxygen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least fluorine,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    fluorine    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least neon,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    neon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Sodium
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least sodium,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    sodium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least magnesium, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    magnesium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least aluminium, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    aluminium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least silicon, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    silicon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least phosphorus, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    phosphorus    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least sulfur, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    sulfur    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least chlorine, return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    chlorine    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most carbon,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    carbon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most nitrogen,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    nitrogen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most oxygen,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    oxygen    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most fluorine,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    fluorine    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most neon,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    neon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Sodium
    [Documentation]    Compare neon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most sodium,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    sodium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most magnesium,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    magnesium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most aluminium,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    aluminium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most silicon,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    silicon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most phosphorus,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    phosphorus    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most sulfur,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    sulfur    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most chlorine,
    ...    return ${value_if_false} otherwise.
    [Arguments]    ${value_if_true}    ${value_if_false}
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    chlorine    ${value_if_true}    ${value_if_false}

CompareStream__Convert_Input
    [Documentation]    Splits arguments into args and kwargs is used in Run_Keyword_If_At_Least_Else and Run_Keyword_If_At_Most_Else.
    ...    The problem is, when the string contains =, but it is not a named argument (name=value). There can be many values containing =, but
    ...    for sure it is present in xmls. If the string starts with "<" it will be treated as it is xml and splitting for
    ...    name and value will not be executed.
    ...    If named argument is passed into this kw, only string data are supported e.g. name=string. Complex variables such as lists or dictionaries
    ...    are not supported.
    [Arguments]    @{arguments}
    ${args}    BuiltIn.Create_List
    ${kwargs}    BuiltIn.Create_Dictionary
    FOR    ${arg}    IN    @{arguments}
        ${arg}    BuiltIn.Convert_To_String    ${arg}
        ${removed}    String.Remove_String    ${arg}    \n    ${Space}    \t
        ...    \r
        IF    "${removed[0]}" == "<"
            ${splitted}    BuiltIn.Create List    ${arg}
        ELSE
            ${splitted}    String.Split_String    ${arg}    separator==    max_split=1
        END
        ${len}    BuiltIn.Get_Length    ${splitted}
        IF    ${len}==1
            Collections.Append_To_List    ${args}    ${splitted}[0]
        ELSE
            Collections.Set_To_Dictionary    ${kwargs}    @{splitted}
        END
    END
    RETURN    ${args}    ${kwargs}

Run_Keyword_If_At_Least
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]
    ...    ${kw_name}
    ...    @{varargs}
    ...    &{kwargs}

Run_Keyword_If_At_Least_Else
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    [Arguments]    ${lower_bound}    @{varargs}
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    IF    "${position}" == "-1"
        BuiltIn.Fail    Missing else statement in defined expresion
    END
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    IF    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]
    ELSE
    END
    RETURN    ${resp}

Run_Keyword_If_At_Most
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${upper_bound}    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${Stream_dict}[${ODL_STREAM}] <= ${Stream_dict}[${upper_bound}]
    ...    ${kw_name}
    ...    @{varargs}
    ...    &{kwargs}

Run_Keyword_If_At_Most_Else
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    [Arguments]    ${upper_bound}    @{varargs}
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    IF    "${position}" == "-1"
        BuiltIn.Fail    Missing else statement in defined expresion
    END
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    IF    ${Stream_dict}[${ODL_STREAM}] >= ${Stream_dict}[${lower_bound}]
    ELSE
    END
    RETURN    ${resp}

Run_Keyword_If_More_Than
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is more than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${Stream_dict}[${ODL_STREAM}] > ${Stream_dict}[${lower_bound}]
    ...    ${kw_name}
    ...    @{varargs}
    ...    &{kwargs}

Run_Keyword_If_Equals
    [Documentation]    Compare ${stream} to ${ODL_STREAM} and in case ${ODL_STREAM} equals ${stream},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${stream}    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${Stream_dict}[${ODL_STREAM}] == ${Stream_dict}[${stream}]
    ...    ${kw_name}
    ...    @{varargs}
    ...    &{kwargs}

Run_Keyword_If_Equals_Else
    [Documentation]    Compare ${stream} to ${ODL_STREAM} and in case ${ODL_STREAM} equals ${stream},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    [Arguments]    ${stream}    @{varargs}
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    IF    "${position}" == "-1"
        BuiltIn.Fail    Missing else statement in defined expresion
    END
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${args_if}    ${kwargs_if}    CompareStream__Convert_Input    @{varargs_if}
    ${args_else}    ${kwargs_else}    CompareStream__Convert_Input    @{varargs_else}
    IF    ${Stream_dict}[${ODL_STREAM}] == ${Stream_dict}[${stream}]
    ELSE
    END
    RETURN    ${resp}

Run_Keyword_If_Less_Than
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is less than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return_If
    ...    ${Stream_dict}[${ODL_STREAM}] < ${Stream_dict}[${lower_bound}]
    ...    ${kw_name}
    ...    @{varargs}
    ...    &{kwargs}

Run_Keyword_If_At_Least_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is at least nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is at least oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at least fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Sodium
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least silicon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    silicon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and in case ${ODL_STREAM} is at least phosphorus,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    phosphorus    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and in case ${ODL_STREAM} is at least sulfur,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    sulfur    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at least chlorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    chlorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is at most nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is at most oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at most fluroine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Sodium
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most silicon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    silicon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and in case ${ODL_STREAM} is at most phosphorus,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    phosphorus    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and in case ${ODL_STREAM} is at most sulfur,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    sulfur    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and in case ${ODL_STREAM} is at most chlorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    chlorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is more than nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is more than oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is more than fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Sodium
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than silicon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    silicon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and in case ${ODL_STREAM} is more than phosphorus,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    phosphorus    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and in case ${ODL_STREAM} is more than sulfur,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    sulfur    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and in case ${ODL_STREAM} is more than chlorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    chlorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Carbon
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Nitrogen
    [Documentation]    Compare nitrogen to ${ODL_STREAM} and in case ${ODL_STREAM} is less than nitrogen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    nitrogen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Oxygen
    [Documentation]    Compare oxygen to ${ODL_STREAM} and in case ${ODL_STREAM} is less than oxygen,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    oxygen    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Fluorine
    [Documentation]    Compare fluorine to ${ODL_STREAM} and in case ${ODL_STREAM} is less than fluorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    fluorine    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Neon
    [Documentation]    Compare neon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than neon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    neon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Sodium
    [Documentation]    Compare sodium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than sodium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    sodium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Magnesium
    [Documentation]    Compare magnesium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than magnesium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    magnesium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Aluminium
    [Documentation]    Compare aluminium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than aluminium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    aluminium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Silicon
    [Documentation]    Compare silicon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than silicon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    silicon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Phosphorus
    [Documentation]    Compare phosphorus to ${ODL_STREAM} and in case ${ODL_STREAM} is less than phosphorus,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    phosphorus    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Sulfur
    [Documentation]    Compare sulfur to ${ODL_STREAM} and in case ${ODL_STREAM} is less than sulfur,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    sulfur    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Chlorine
    [Documentation]    Compare chlorine to ${ODL_STREAM} and in case ${ODL_STREAM} is less than chlorine,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    chlorine    ${kw_name}    @{varargs}    &{kwargs}
