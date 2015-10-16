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

HTTP Start h36_2 80b
    Start HTTP Service on Docker    h36_2    80

Start Curl
    Start Endless Curl from Docker    h35_2    10.0.36.2    80    sleep=1

Stop
    SSHLibrary.Close Connection



