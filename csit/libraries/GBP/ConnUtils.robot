*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot

*** Keywords ***
Connect and Login
    [Arguments]    ${ip}    ${timeout}==3s
    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    Utils.Flexible Mininet Login
