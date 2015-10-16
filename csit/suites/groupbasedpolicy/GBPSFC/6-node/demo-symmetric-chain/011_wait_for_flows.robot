*** Settings ***
Documentation     Waiting for flows to appear on switches.
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Testcases ***

Wait For Flows on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw1
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Wait For Flows on GBPSFC2
    Switch Connection    GPSFC2_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw2
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Wait For Flows on GBPSFC3
    Switch Connection    GPSFC3_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw3
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Wait For Flows on GBPSFC4
    Switch Connection    GPSFC4_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw4
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Wait For Flows on GBPSFC5
    Switch Connection    GPSFC5_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw5
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0

Wait For Flows on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw6
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
