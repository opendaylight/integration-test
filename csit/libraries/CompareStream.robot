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
    [Documentation]    compare  ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
     ...               returns ${value_if_true}
    ...                in case ${ODL_STREAM} is before ${lower_bound} returns ${value_if_false}

     BuiltIn.Run_Keyword_And_Return    BuiltIn.Set_Variable_If    &{Stream_dict}[${ODL_STREAM}] >= &{Stream_dict}[${lower_bound}]     ${value_if_true}    ${value_if_false}


Set_Variable_If_At_Least_Carbon
    [Arguments]        ${value_if_true}   ${value_if_false}
    [Documentation]    compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
     ...               returns ${value_if_true}
    ...                in case ${ODL_STREAM} is before carbon returns ${value_if_false}

    BuiltIn.Run_Keyword_And_Return  Set_Variable_If_At_Least    carbon    ${value_if_true}    ${value_if_false}


Run_Keyword_If_At_Least
    [Arguments]        ${lower_bound}    ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    compare  ${lower_bound} to ${ODL_STREAM} and in case ${ODL_STREAM} is at least ${lower_bound},
     ...               run ${kw_name} @{varargs} &{kwargs} and return its value
    ...
     BuiltIn.Run_Keyword_And_Return_If    &{Stream_dict}[${ODL_STREAM}]} >= &{Stream_dict}[${lower_bound}]}    ${kw_name}    @{varargs}    &{kwargs}


Run_Keyword_If_At_Least_Carbon
    [Arguments]        ${kw_name}    @{varargs}    &{kwargs}
    [Documentation]    compare carbon to ${ODL_STREAM} and in case ${ODL_STREAM} is at least carbon,
     ...               run ${kw_name} @{varargs} &{kwargs} and return its value

    BuiltIn.Run_Keyword_And_Return_If    Run_Keyword_If_At_Least     carbon    ${kw_name}    @{varargs}    &{kwargs}
