*** Settings ***
Documentation     Unimgr keywords defination that will be used in Unimgr suite.
Library           OperatingSystem
Library           SSHLibrary
Library           String
Resource          ./Utils.robot
Variables         ../variables/Variables.py

*** Keywords ***
Check Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify connectivity.
    Write    ${host1} ping -w 1 ${host2}
    LegatoUtils.Check Expected Ping Result    0

Check No Ping
    [Arguments]    ${host1}    ${host2}
    [Documentation]    Send ping from mininet and verify no conectivity.
    Write    ${host1} ping -w 1 ${host2}
    LegatoUtils.Check Expected Ping Result    100

Check Expected Ping Result
    [Arguments]    ${Expected_value}
    ${result}=    Read Until    mininet>
    Should Contain    ${result}    received, ${Expected_value}% packet loss
