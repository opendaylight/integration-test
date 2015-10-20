*** Settings ***
Documentation    Basic tests for ping and curl
Library          SSHLibrary
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../Variables.robot

*** Variables ***
${timeout} =     10s

*** Testcases ***

Open Connection to GBPSFC1
    SSHLibrary.Open Connection    ${GBPSFC1}    alias=GPSFC1_CONNECTION
    Utils.Flexible Mininet Login
Open Connection to GBPSFC6 
    SSHLibrary.Open Connection    ${GBPSFC6}    alias=GPSFC6_CONNECTION
    Utils.Flexible Mininet Login

Switch to GBPSFC1 to start servers
    Switch Connection    GPSFC1_CONNECTION

Start HTTP Server at h36_2 on Port 80
    Start HTTP Service on Docker    h36_2    service_port=80

Start HTTP Server at h36_3 on Port 80
    Start HTTP Service on Docker    h36_3    service_port=80

Switch to GBPSFC6 to start servers
    Switch Connection    GPSFC6_CONNECTION

Start HTTP Server at h36_4 on Port 80
    Start HTTP Service on Docker    h36_4    service_port=80

Start HTTP Server at h36_5 on Port 80
    Start HTTP Service on Docker    h36_5    service_port=80

Switch to GBPSFC1 to Execute Curl Request
    Switch Connection    GPSFC1_CONNECTION

Curl Request from h35_2 to h36_2
    Curl from Docker    h35_2    10.0.36.2    service_port=80

Curl Request from h35_2 to h36_3
    Curl from Docker    h35_2    10.0.36.3    service_port=80

Curl Request from h35_2 to h36_4
    Curl from Docker    h35_2    10.0.36.4    service_port=80

Curl Request from h35_2 to h36_5
    Curl from Docker    h35_2    10.0.36.5    service_port=80

Curl Request from h35_3 to h36_2
    Curl from Docker    h35_3    10.0.36.2    service_port=80

Curl Request from h35_3 to h36_3
    Curl from Docker    h35_3    10.0.36.3    service_port=80

Curl Request from h35_3 to h36_4
    Curl from Docker    h35_3    10.0.36.4    service_port=80

Curl Request from h35_3 to h36_5
    Curl from Docker    h35_3    10.0.36.5    service_port=80

Switch to GBPSFC6 to Execute Curl Request and Stop Servers
    Switch Connection    GPSFC6_CONNECTION

Curl Request from h35_4 to h36_2
    Curl from Docker    h35_4    10.0.36.2    service_port=80

Curl Request from h35_4 to h36_3
    Curl from Docker    h35_4    10.0.36.3    service_port=80

Curl Request from h35_4 to h36_4
    Curl from Docker    h35_4    10.0.36.4    service_port=80

Curl Request from h35_4 to h36_5
    Curl from Docker    h35_4    10.0.36.5    service_port=80

Curl Request from h35_5 to h36_2
    Curl from Docker    h35_5    10.0.36.2    service_port=80

Curl Request from h35_5 to h36_3
    Curl from Docker    h35_5    10.0.36.3    service_port=80

Curl Request from h35_5 to h36_4
    Curl from Docker    h35_5    10.0.36.4    service_port=80

Curl Request from h35_5 to h36_5
    Curl from Docker    h35_5    10.0.36.5    service_port=80

Stop HTTP at h36_4 on Port 80
    Stop HTTP Service on Docker    h36_4    service_port=80

Stop HTTP at h36_5 on Port 80
    Stop HTTP Service on Docker    h36_5    service_port=80

Switch to GBPSFC6 to Stop Servers
    Switch Connection    GPSFC1_CONNECTION

Stop HTTP at h36_2 on Port 80
    Stop HTTP Service on Docker    h36_2    service_port=80

Stop HTTP at h36_3 on Port 80
    Stop HTTP Service on Docker    h36_3    service_port=80

Close Connection to GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    SSHLibrary.Close Connection

Close Connection to GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    SSHLibrary.Close Connection

