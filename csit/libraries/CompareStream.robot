*** Settings ***
Documentation     This Resource contains list of Keywords Set_Variable_If_At_Least*, Set_Variable_If_At_Most,
...               Run_Keyword_If_At_Least*, Run_Keyword_If_At_Most*,
...               Run_Keyword_If_More_Than*, Run_Keyword_If_Less_Than*,
...               for comparison ${ODL_STREAM} to the given ${lower_bound},
...               in order to replace ad-hoc conditional execution in suites.
Library           Collections

*** Variables ***
&{Stream_dict}    hydrogen=${1}    stable-helium=${2}    stable-lithium=${3}    beryllium=${4}    boron=${5}    carbon=${6}    nitrogen=${7}

*** Keywords ***
Set_Variable_If_At_Least
    [Arguments]    ${lower_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${lower_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most
    [Arguments]    ${upper_bound}    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most ${upper_bound},
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[${upper_bound}]    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Helium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least stable-helium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    stable-helium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Lithium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least stable-lithium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    stable-lithium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Beryllium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least beryllium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    beryllium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Boron
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare boron to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least boron,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    boron    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Least_Carbon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least carbon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Least    carbon    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Helium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most stable-helium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    stable-helium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Lithium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most stable-lithium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    stable-lithium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Beryllium
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most beryllium,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    beryllium    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Boron
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare boron to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most boron,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    boron    ${value_if_true}    ${value_if_false}

Set_Variable_If_At_Most_Carbon
    [Arguments]    ${value_if_true}    ${value_if_false}
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at most carbon,
    ...    return ${value_if_false} otherwise.
    BuiltIn.Run_Keyword_And_Return    Set_Variable_If_At_Most    carbon    ${value_if_true}    ${value_if_false}

Run_Keyword_If_At_Least
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Else
    [Arguments]    ${lower_bound}    @{varargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    BuiltIn.Run_Keyword_If    "${position}" == "-1"    BuiltIn.Fail    Missing else statement in defined expresion
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${resp}    BuiltIn.Run_Keyword_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]    @{varargs_if}
    ...    ELSE    @{varargs_else}
    [Return]    ${resp}

Run_Keyword_If_At_Most
    [Arguments]    ${upper_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[${upper_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Else
    [Arguments]    ${upper_bound}    @{varargs}
    [Documentation]    Compare ${upper_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at most ${upper_bound},
    ...    run keyword defined before ELSE statement otherwise run keyword defined after ELSE statement and return its value.
    ${position}    Collections.Get_Index_From_List    ${varargs}    \ELSE
    BuiltIn.Run_Keyword_If    "${position}" == "-1"    BuiltIn.Fail    Missing else statement in defined expresion
    ${varargs_if}    Collections.Get_Slice_From_List    ${varargs}    0    ${position}
    ${varargs_else}    Collections.Get_Slice_From_List    ${varargs}    ${position+1}
    ${resp}    BuiltIn.Run_Keyword_If    &{Stream_dict}[${ODL_STREAM}] <= &{Stream_dict}[${upper_bound}]    @{varargs_if}
    ...    ELSE    @{varargs_else}
    [Return]    ${resp}

Run_Keyword_If_More_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is more than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] > &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than
    [Arguments]    ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is less than ${lower_bound},
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}] < &{Stream_dict}[${lower_bound}]    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Helium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least stable-helium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    stable-helium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Lithium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least stable-lithium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    stable-lithium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Beryllium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and in case ${ODL_STREAM} is at least beryllium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    beryllium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Boron
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare boron to ${ODL_STREAM} and in case ${ODL_STREAM} is at least boron,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    boron    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Least_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Least    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Helium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most stable-helium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    stable-helium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Lithium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most stable-lithium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    stable-lithium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Beryllium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and in case ${ODL_STREAM} is at most beryllium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    beryllium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Boron
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare boron to ${ODL_STREAM} and in case ${ODL_STREAM} is at most boron,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    boron    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_At_Most_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at most carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_At_Most    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Helium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than stable-helium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    stable-helium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Helium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than stable-helium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    stable-helium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Lithium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than stable-lithium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    stable-lithium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Lithium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than stable-lithium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    stable-lithium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Beryllium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and in case ${ODL_STREAM} is more than beryllium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    beryllium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Beryllium
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and in case ${ODL_STREAM} is less than beryllium,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    beryllium    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Boron
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare boron to ${ODL_STREAM} and in case ${ODL_STREAM} is more than boron,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    boron    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Boron
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare boron to ${ODL_STREAM} and in case ${ODL_STREAM} is less than boron,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    boron    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_More_Than_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is more than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_More_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}

Run_Keyword_If_Less_Than_Carbon
    [Arguments]    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is less than carbon,
    ...    run ${kw_name} @{varargs} &{kwargs} and return its value.
    BuiltIn.Run_Keyword_And_Return    Run_Keyword_If_Less_Than    carbon    ${kw_name}    @{varargs}    &{kwargs}
