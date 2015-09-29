*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s


*** Testcases ***

Wait For Flows Created
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    ${rc}=    Execute Command    sudo ${VM_HOME_FOLDER}${/}${VM_SCRIPTS_FOLDER}/wait_flows sw1
    ...    return_stdout=False    return_stderr=False    return_rc=True
    Should Be Equal As Integers    ${rc}    0
    SSHLibrary.Close Connection

Simple Ping
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    DockerUtils.Ping From Docker    h35_2    10.0.36.3
    SSHLibrary.Close Connection

Endless Ping
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    DockerUtils.Start Endless Ping from Docker    h35_2    10.0.36.3
    Sleep    20 sec
    DockerUtils.Stop Endless Ping from Docker to Address    h35_2    10.0.36.3
    SSHLibrary.Close Connection

Simple Curl
    ConnUtils.Connect and Login    ${GBP3}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    h36_3    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    DockerUtils.Curl from Docker    h35_2    10.0.36.3    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBP3}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    h36_3
    SSHLibrary.Close Connection

Endless Curl
    ConnUtils.Connect and Login    ${GBP3}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    h36_3    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBP1}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    h35_2    10.0.36.3    80
    Sleep    20 sec
    DockerUtils.Stop Endless Curl from Docker    h35_2
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBP3}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    h36_3
    SSHLibrary.Close Connection
