*** Settings ***
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Resource          Variables.robot

*** Keywords ***
Start Connections
    [Documentation]    Establishes connections to remote VMs.
    SSHLibrary.Open Connection    ${VPP1}    alias=VPP1_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${VPP2}    alias=VPP2_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${VPP3}    alias=VPP3_CONNECTION
    Utils.Flexible Mininet Login

Close Connections
    [Documentation]    Closes connections to remote VMs.
    Switch Connection    VPP1_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    VPP2_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    VPP3_CONNECTION
    SSHLibrary.Close Connection