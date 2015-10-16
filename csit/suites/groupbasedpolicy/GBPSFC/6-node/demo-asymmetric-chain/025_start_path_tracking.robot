*** Settings ***
Documentation     Initializes traffic between docker instances that will be tracked.
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
Connect to GBPSFC1
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}

Start HTTP on h36_2 on Port 80
    Start HTTP Service on Docker    h36_2    80

Start Endless Curl on h35_2 on port 80
    Start Endless Curl from Docker    h35_2    10.0.36.2    80    sleep=1

Close connection
    SSHLibrary.Close Connection

