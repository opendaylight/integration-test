*** Settings ***
Documentation    Basic tests for ping and curl
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../Variables.robot

*** Testcases ***
Connect to GBPSFC1
    ConnUtils.Connect and Login    ${GBPSFC1}

Ping From Host h35_2 Address 10.0.35.3
    Ping from Docker    h35_2    10.0.35.3

Ping From Host h35_2 Address 10.0.35.4
    Ping from Docker    h35_2    10.0.35.4

Ping From Host h35_2 Address 10.0.35.5
    Ping from Docker    h35_2    10.0.35.5

Ping From Host h35_2 Address 10.0.36.2
    Ping from Docker    h35_2    10.0.36.2

Ping From Host h35_2 Address 10.0.36.3
    Ping from Docker    h35_2    10.0.36.3

Ping From Host h35_2 Address 10.0.36.4
    Ping from Docker    h35_2    10.0.36.4

Ping From Host h35_2 Address 10.0.36.5
    Ping from Docker    h35_2    10.0.36.5

Ping From Host h35_3 Address 10.0.35.2
    Ping from Docker    h35_3    10.0.35.2

Ping From Host h35_3 Address 10.0.35.4
    Ping from Docker    h35_3    10.0.35.4

Ping From Host h35_3 Address 10.0.35.5
    Ping from Docker    h35_3    10.0.35.5

Ping From Host h35_3 Address 10.0.36.2
    Ping from Docker    h35_3    10.0.36.2

Ping From Host h35_3 Address 10.0.36.3
    Ping from Docker    h35_3    10.0.36.3

Ping From Host h35_3 Address 10.0.36.4
    Ping from Docker    h35_3    10.0.36.4

Ping From Host h35_3 Address 10.0.36.5
    Ping from Docker    h35_3    10.0.36.5

Ping From Host h36_2 Address 10.0.35.2
    Ping from Docker    h36_2    10.0.35.2

Ping From Host h36_2 Address 10.0.35.3
    Ping from Docker    h36_2    10.0.35.3

Ping From Host h36_2 Address 10.0.35.4
    Ping from Docker    h36_2    10.0.35.4

Ping From Host h36_2 Address 10.0.35.5
    Ping from Docker    h36_2    10.0.35.5

Ping From Host h36_2 Address 10.0.36.3
    Ping from Docker    h36_2    10.0.36.3

Ping From Host h36_2 Address 10.0.36.4
    Ping from Docker    h36_2    10.0.36.4

Ping From Host h36_2 Address 10.0.36.5
    Ping from Docker    h36_2    10.0.36.5

Ping From Host h36_3 Address 10.0.35.2
    Ping from Docker    h36_3    10.0.35.2

Ping From Host h36_3 Address 10.0.35.3
    Ping from Docker    h36_3    10.0.35.3

Ping From Host h36_3 Address 10.0.35.4
    Ping from Docker    h36_3    10.0.35.4

Ping From Host h36_3 Address 10.0.35.5
    Ping from Docker    h36_3    10.0.35.5

Ping From Host h36_3 Address 10.0.36.2
    Ping from Docker    h36_3    10.0.36.2

Ping From Host h36_3 Address 10.0.36.4
    Ping from Docker    h36_3    10.0.36.4

Ping From Host h36_3 Address 10.0.36.5
    Ping from Docker    h36_3    10.0.36.5

Close Connection and Connect to GBPSFC6
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${GBPSFC6}    timeout=${timeout}

Ping From Host h35_4 Address 10.0.35.2
    Ping from Docker    h35_4    10.0.35.2

Ping From Host h35_4 Address 10.0.35.3
    Ping from Docker    h35_4   10.0.35.3

Ping From Host h35_4 Address 10.0.35.5
    Ping from Docker    h35_4    10.0.35.5

Ping From Host h35_4 Address 10.0.36.2
    Ping from Docker    h35_4    10.0.36.2

Ping From Host h35_4 Address 10.0.36.3
    Ping from Docker    h35_4    10.0.36.3

Ping From Host h35_4 Address 10.0.36.4
    Ping from Docker    h35_4    10.0.36.4

Ping From Host h35_4 Address 10.0.36.5
    Ping from Docker    h35_4    10.0.36.5

Ping From Host h35_5 Address 10.0.35.2
    Ping from Docker    h35_5    10.0.35.2

Ping From Host h35_5 Address 10.0.35.3
    Ping from Docker    h35_5   10.0.35.3

Ping From Host h35_5 Address 10.0.35.4
    Ping from Docker    h35_5    10.0.35.4

Ping From Host h35_5 Address 10.0.36.2
    Ping from Docker    h35_5    10.0.36.2

Ping From Host h35_5 Address 10.0.36.3
    Ping from Docker    h35_5    10.0.36.3

Ping From Host h35_5 Address 10.0.36.4
    Ping from Docker    h35_5    10.0.36.4

Ping From Host h35_5 Address 10.0.36.5
    Ping from Docker    h35_5    10.0.36.5

Ping From Host h36_4 Address 10.0.35.2
    Ping from Docker    h36_4    10.0.35.2

Ping From Host h36_4 Address 10.0.35.3
    Ping from Docker    h36_4    10.0.35.3

Ping From Host h36_4 Address 10.0.35.4
    Ping from Docker    h36_4    10.0.35.4

Ping From Host h36_4 Address 10.0.35.5
    Ping from Docker    h36_4    10.0.35.5

Ping From Host h36_4 Address 10.0.36.2
    Ping from Docker    h36_4    10.0.36.2

Ping From Host h36_4 Address 10.0.36.3
    Ping from Docker    h36_4    10.0.36.3

Ping From Host h36_4 Address 10.0.36.5
    Ping from Docker    h36_4    10.0.36.5

Ping From Host h36_5 Address 10.0.35.2
    Ping from Docker    h36_5    10.0.35.2

Ping From Host h36_5 Address 10.0.35.3
    Ping from Docker    h36_5    10.0.35.3

Ping From Host h36_5 Address 10.0.35.4
    Ping from Docker    h36_5    10.0.35.4

Ping From Host h36_5 Address 10.0.35.5
    Ping from Docker    h36_5    10.0.35.5

Ping From Host h36_5 Address 10.0.36.2
    Ping from Docker    h36_5    10.0.36.2

Ping From Host h36_5 Address 10.0.36.3
    Ping from Docker    h36_5    10.0.36.3

Ping From Host h36_5 Address 10.0.36.4
    Ping from Docker    h36_5    10.0.36.4

Close Connection
    SSHLibrary.Close Connection
