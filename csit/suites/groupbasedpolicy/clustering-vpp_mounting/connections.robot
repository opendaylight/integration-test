*** Settings ***
Library           SSHLibrary
Resource          vars.robot
Resource          ../../../libraries/Utils.robot

*** Keywords ***
Start Connections
    [Documentation]    Establishes connections to remote VMs.
    SSHLibrary.Open Connection    ${VPP_NODE_1}    alias=VPP1_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${VPP_NODE_2}    alias=VPP2_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${VPP_NODE_3}    alias=VPP3_CONNECTION
    Utils.Flexible Mininet Login

Close Connections
    [Documentation]    Closes connections to remote VMs.
    Switch Connection    VPP1_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    VPP2_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    VPP3_CONNECTION
    SSHLibrary.Close Connection
