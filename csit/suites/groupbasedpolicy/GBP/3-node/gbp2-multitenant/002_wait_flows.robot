*** Settings ***
Documentation       Waiting until flows are created

Library             SSHLibrary
Resource            ../../../../../libraries/Utils.robot
Resource            ../../../../../libraries/GBP/OpenFlowUtils.robot
Variables           ../../../../../variables/Variables.py
Resource            ../Variables.robot

Default Tags        multi-tenant    setup    multi-tenant-setup


*** Variables ***
${timeout}      10s


*** Test Cases ***
Wait For Flows
    Sleep    30s
    ${passed} =    Run Keyword And Return Status    OpenFlowUtils.Wait For Flows On Switch    ${GBP1}    sw1
    IF    not ${passed}    Fatal Error    Flows not created on sw1!
    ${passed} =    Run Keyword And Return Status    OpenFlowUtils.Wait For Flows On Switch    ${GBP2}    sw2
    IF    not ${passed}    Fatal Error    Flows not created on sw2!
    ${passed} =    Run Keyword And Return Status    OpenFlowUtils.Wait For Flows On Switch    ${GBP3}    sw3
    IF    not ${passed}    Fatal Error    Flows not created on sw3!
