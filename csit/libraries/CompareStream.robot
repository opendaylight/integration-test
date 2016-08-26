*** Settings ***
Documentation     This Resource contains list of kws Set_Variable_If_At_Least_* for comparison ${ODL_STREAM} to the given ${lower_bound}
...               in order to replace conditional execution in suites, written such as this: BuiltIn.Set_Variable_If
...               by these kws
...
Library           OperatingSystem
Library           SSHLibrary
Library           String
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          NexusKeywords.robot

*** Variables ***

${Variables}      ${CURDIR}/../variables/Variables.py
${BGP_BMP_DIR}    ${CURDIR}/../../../variables/bgpfunctional/bmp_basic


&{Stream_dict}    hydrogen=${1}     stable-helium=${2}    stable-lithium=${3}   beryllium=${4}    boron=${5}    carbon=${6}    nitrogen=${7}


*** Keywords ***

Set_Variable_If_At_Least
    [Arguments]        ${lower_bound}   ${value_if_true}   ${value_if_false}
    [Documentation]    Compare  ${lower_bound} to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least ${lower_bound},
    ...                return ${value_if_false} otherwise.

     BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]     ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_Carbon
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    Compare carbon to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least carbon,
     ...               return ${value_if_false} otherwise.

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    carbon    ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_stable-helium
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    Compare stable-helium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least stable-helium,
     ...               return ${value_if_false} otherwise.

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    stable-helium    ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_stable-lithium
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    Compare stable-lithium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least stable-lithium,
     ...               return ${value_if_false} otherwise.

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    stable-lithium   ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_boron
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    Compare boron to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least boron,
     ...               return ${value_if_false} otherwise.

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    boron   ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_beryllium
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    Compare beryllium to ${ODL_STREAM} and return ${value_if_true} if ${ODL_STREAM} is at least beryllium,
     ...               return ${value_if_false} otherwise.

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    beryllium   ${value_if_true}    ${value_if_false}


Run_Keyword_If_At_Least
    [Arguments]        ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare  ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
     ...               run ${kw_name} @{varargs} &{kwargs} and return its value

     BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}]} >= &{Stream_dict}[${lower_bound}]}    ${kw_name}    @{varargs}    &{kwargs}


Run_Keyword_If_At_Least_Carbon
    [Arguments]        ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    Compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
     ...               run ${kw_name} @{varargs} &{kwargs} and return its value

    BuiltIn.Run_Keyword_And_Return_If    Run_Keyword_If_At_Least     carbon    ${kw_name}    @{varargs}    &{kwargs}
