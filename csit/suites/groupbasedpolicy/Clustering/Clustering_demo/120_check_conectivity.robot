*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Resource          ../Connections.robot
Resource          ../../../../libraries/GBP/DockerUtils.robot

*** Test Cases ***
Verify VM connectivity
    [Documentation]    Verify that connections between VMS are working
    Switch Connection    VPP2_CONNECTION
    Ping From Docker    docker1    10.100.0.3
    Ping From Docker    docker1    10.100.0.4
    Ping From Docker    docker1    10.100.0.5
