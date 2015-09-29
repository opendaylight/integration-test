*** Settings ***
Library           SSHLibrary
Resource          ../Utils.robot


*** Variables ***


*** Keywords ***
Connect and Login
    [Arguments]    ${ip}    ${timeout}==3s
    SSHLibrary.Open Connection    ${ip}    timeout=${timeout}
    Utils.Flexible Mininet Login    #TODO make alias keyword in ConnUtils, not containing "Mininet" word
