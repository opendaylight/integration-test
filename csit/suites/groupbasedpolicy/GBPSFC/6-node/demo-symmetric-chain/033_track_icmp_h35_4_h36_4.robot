*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Variables ***
${NSP_path1}
${NSP_path2}

*** Testcases ***

Ping from h36_4 to h35_4
    Switch Connection    GPSFC6_CONNECTION
    Ping from Docker    h36_4    10.0.35.4

Start Endless Ping from h36_4 to h35_4
    Start Endless Ping from Docker    h36_4    10.0.35.4

Find ICMP Req from h36_4 to h35_4 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    6
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:36:04
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.4
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:35:04
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.4
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Out Port Check    ${actions}    4
    Find Flow in DPCTL Output    ${matches}    ${actions}

Find ICMP Resp from h35_4 to h36_4 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    4
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:35:04
    Append Inner IPs Check    ${actions}    10.0.35.4    10.0.36.4
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:36:04
    Append Inner IPs Check    ${actions}    10.0.35.4    10.0.36.4
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Out Port Check    ${actions}    6
    Find Flow in DPCTL Output    ${matches}    ${actions}

Stop Endless Ping from h36_4 to h35_4
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address   h36_4    10.0.35.4


