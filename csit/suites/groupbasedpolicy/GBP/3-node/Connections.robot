*** Settings ***
Documentation     Creates/closes SSH connections to all GBP nodes. Existing connections
...               can be identified by aliases.
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot
Resource          Variables.robot

*** Keywords ***
Start Connections
    [Documentation]    Establishes connections to remote VMs.
    SSHLibrary.Open Connection    ${GBP1}    alias=GBP1_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBP2}    alias=GBP2_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBP3}    alias=GBP3_CONNECTION
    Utils.Flexible Mininet Login

Close Connections
    [Documentation]    Closes connections to remote VMs.
    Switch Connection    GBP1_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GBP2_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GBP3_CONNECTION
    SSHLibrary.Close Connection
