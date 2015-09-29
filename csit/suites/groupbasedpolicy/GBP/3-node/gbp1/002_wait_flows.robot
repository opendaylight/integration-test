*** Settings ***
Documentation     Waiting until flows are created
Default Tags      single-tenant    setup    single-tenant-setup
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s


*** Testcases ***

Wait For Flows
    ${passed} =  Run Keyword And Return Status    Wait For Flows On Switch  ${GBP1}  sw1
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw1!
    ${passed} =  Run Keyword And Return Status    Wait For Flows On Switch  ${GBP2}  sw2
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw2!
    ${passed} =  Run Keyword And Return Status    Wait For Flows On Switch  ${GBP3}  sw3
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw3!


*** Keywords ***

Wait For Flows On Switch
    [Arguments]  ${switch_ip}  ${switch_name}
    [Documentation]  Counts flows on switch, fails if 0
    ConnUtils.Connect and Login  ${switch_ip}  timeout=${timeout}
    Wait Until Keyword Succeeds  2 min  20 sec  Count Flows On Switch  ${switch_name}
    SSHLibrary.Close Connection

Count Flows On Switch
    [Arguments]  ${switch_name}
    ${out}  SSHLibrary.Execute Command  printf "%d" $(($(sudo ovs-ofctl dump-flows ${switch_name} -OOpenFlow13 | wc -l)-1))
    Should Not Be Equal As Integers  ${out}  0
