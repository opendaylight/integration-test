*** Settings ***
Documentation     Unimgr keywords defination that will be used in Unimgr suite.
Library           OperatingSystem
Library           SSHLibrary
Library           String
Resource          ./Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${ping_command}    h1 ping -w 1 h2

*** Keywords ***
Check Ping
    [Documentation]    Send ping from mininet and verify no packet loss.
    Write    ${ping_command}
    LegatoUtils.Check Expected Ping Result    0

Check No Ping
    [Documentation]    Send ping from mininet and verify packet loss.
    Write    ${ping_command}
    LegatoUtils.Check Expected Ping Result    100

Check Expected Ping Result
    [Arguments]    ${Expected_value}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    received, ${Expected_value}% packet loss
