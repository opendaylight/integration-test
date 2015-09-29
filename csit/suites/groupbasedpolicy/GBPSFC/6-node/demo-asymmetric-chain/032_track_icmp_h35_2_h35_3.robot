*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/PathCheckUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Variables ***
${NSP_path1}
${NSP_path2}

*** Testcases ***

Ping Once from h35_2 to h35_3
    Switch Connection    GPSFC1_CONNECTION
    Ping from Docker    h35_2    10.0.35.3

Start Endless Ping from h35_2 to h35_3
    Start Endless Ping from Docker    h35_2    10.0.35.3

Find ICMP Req from h35_2 to h35_3 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    4
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:35:02
    Append Inner IPs Check    ${actions}    10.0.35.2    10.0.35.3
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner IPs Check    ${actions}    10.0.35.2    10.0.35.3
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Out Port Check    ${actions}    5
    Find Flow in DPCTL Output    ${matches}    ${actions}

Find ICMP Resp from h35_3 to h35_2 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    5
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:35:03
    Append Inner IPs Check    ${actions}    10.0.35.3    10.0.35.2
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner IPs Check    ${actions}    10.0.35.3    10.0.35.2
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Out Port Check    ${actions}    4
    Find Flow in DPCTL Output    ${matches}    ${actions}

Stop Endless Ping from h35_2 to h35_3
    Switch Connection    GPSFC1_CONNECTION
    Stop Endless Ping from Docker to Address   h35_2    10.0.35.3


