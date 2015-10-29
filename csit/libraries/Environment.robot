*** Settings ***
Documentation     Mockable versions of environment accessor keywords.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This Resource contains keywords that either perform actions
...               that affect environment outside of the computer where the
...               Robot is running or query data from such environment. The
...               motivation is to make it possible to build repeatable tests
...               of testing infrastructure included in the libraries.
...
...               Currently only time handling sensitive operations are included.
...               These are "DateTime.Get_Current_Date" and "BuiltIn.Sleep".
Library           DateTime

*** Variables ***
${Environment__Access_Real_Environment}    True

*** Keywords ***
Switch_To_Mockups
    [Arguments]    ${datetime}=2015-10-29 18:47:26.846    ${timedrift}=0.007s
    [Documentation]    Switch to simulated version of the environment accessors.
    ...    ${datetime} specifies the simulated date and time.
    ...    ${timedrift} specifies the time that is added during each Sleep.
    BuiltIn.Set_Suite_Variable    ${Environment__Access_Real_Environment}    False
    BuiltIn.Set_Suite_Variable    ${Environment__Current_Time}    ${datetime}
    BuiltIn.Set_Suite_Variable    ${Environment__Time_Drift}    ${timedrift}

Get_Current_Date
    BuiltIn.Run_Keyword_And_Return_If    ${Environment__Access_Real_Environment}    DateTime.Get_Current_Date
    [Return]    ${Environment__Current_Time}

Sleep
    [Arguments]    ${time}
    BuiltIn.Run_Keyword_And_Return_If    ${Environment__Access_Real_Environment}    BuiltIn.Sleep    ${time}
    ${tmp}=    DateTime.Add_Time_To_Date    ${Environment__Current_Time}    ${time}
    ${tmp}=    DateTime.Add_Time_To_Date    ${tmp}    ${Environment__Time_Drift}
    BuiltIn.Set_Suite_Variable    ${Environment__Current_Time}    ${tmp}
