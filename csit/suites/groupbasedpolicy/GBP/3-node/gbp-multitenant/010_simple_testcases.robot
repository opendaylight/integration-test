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

Simple Ping Tenant One
    Log    gbp-multitenant 020
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}
    DockerUtils.Ping From Docker    h35_2    10.0.36.2
    SSHLibrary.Close Connection

Simple Curl Tenant One
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    h36_2    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}
    DockerUtils.Curl from Docker    h35_2    10.0.36.2    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    h36_2
    SSHLibrary.Close Connection

Simple Ping Tenant Two
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}
    DockerUtils.Ping From Docker    h35_8    10.0.36.8
    SSHLibrary.Close Connection

Simple Curl Tenant Two
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    h36_8    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBPSFC1}    timeout=${timeout}
    DockerUtils.Curl from Docker    h35_8    10.0.36.8    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBPSFC3}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    h36_8
    SSHLibrary.Close Connection
