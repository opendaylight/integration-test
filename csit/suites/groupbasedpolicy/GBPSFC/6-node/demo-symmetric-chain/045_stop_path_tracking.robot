*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Library           OperatingSystem


*** Variables ***
${timeout} =     10s

*** Testcases ***
Start
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}

Stop Curl
    BuiltIn.Sleep    2
    Stop Endless Curl from Docker    h35_2

HTTP Stop h36_2 80a
    Stop HTTP Service on Docker    h36_2

Stop
    SSHLibrary.Close Connection



