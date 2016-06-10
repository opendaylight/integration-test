*** Settings ***
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          ../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../variables/Variables.py
Resource          Variables.robot

*** Keywords ***
Start Connections
    [Documentation]    Establishes connections to remote VMs.
    SSHLibrary.Open Connection    ${GBPSFC1}    alias=GPSFC1_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC2}    alias=GPSFC2_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC3}    alias=GPSFC3_CONNECTION
    Utils.Flexible Mininet Login

Close Connections
    [Documentation]    Closes connections to remote VMs.
    Switch Connection    GPSFC1_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC2_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC3_CONNECTION
    SSHLibrary.Close Connection