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
    ${passed} =    Run Keyword And Return Status    Wait For Flows On Sw1
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw1!
    ${passed} =    Run Keyword And Return Status    Wait For Flows On Sw2
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw2!
    ${passed} =    Run Keyword And Return Status    Wait For Flows On Sw3
    Run Keyword Unless    ${passed}    Fatal Error    Flows not created on sw3!


*** Keywords ***

Wait For Flows On Sw1
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw1
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    SSHLibrary.Close Connection

Wait For Flows On Sw2
    ConnUtils.Connect and Login    ${GBP2}    timeout=${timeout}
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw2
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    SSHLibrary.Close Connection

Wait For Flows On Sw3
    ConnUtils.Connect and Login    ${GBP3}    timeout=${timeout}
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw3
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    SSHLibrary.Close Connection
