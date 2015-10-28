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

Ping from h36_5 to h35_2
    Switch Connection    GPSFC6_CONNECTION
    Ping from Docker    h36_5    10.0.35.2

Start Endless Ping from h36_5 to h35_2
    Start Endless Ping from Docker    h36_5    10.0.35.2

Find ICMP Req from h36_5 to h35_2 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    7
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:36:05
    Append Inner IPs Check    ${actions}    10.0.36.5    10.0.35.2
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:35:02
    Append Inner IPs Check    ${actions}    10.0.36.5    10.0.35.2
    Append Tunnel Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.70
    Append Out Port Check    ${actions}    3
    Find Flow in DPCTL Output    ${matches}    ${actions}

Find ICMP Req from h36_5 to h35_2 on GBPSFC1
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    3
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:02
    Append Tunnel Set Check    ${matches}
    Append Inner IPs Check    ${matches}    10.0.36.5    10.0.35.2
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.75/255.255.255.255    dst_ip=192.168.50.70/255.255.255.255
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${matches}    1
    Append Out Port Check    ${actions}    4
    Append Inner IPs Check    ${actions}    10.0.36.5    10.0.35.2
    Find Flow in DPCTL Output    ${matches}    ${actions}

Find ICMP Resp from h35_2 to h36_5 on GBPSFC1
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    4
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:35:02
    Append Inner IPs Check    ${actions}    10.0.35.2    10.0.36.5
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    1
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:36:05
    Append Inner IPs Check    ${actions}    10.0.35.2    10.0.36.5
    Append Tunnel Set Check    ${actions}
    Append Proto Check    ${actions}    1
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.75
    Append Out Port Check    ${actions}    3
    Find Flow in DPCTL Output    ${matches}    ${actions}

Find ICMP Resp from h35_2 to h36_5 on GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    3
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:05
    Append Tunnel Set Check    ${matches}
    Append Inner IPs Check    ${matches}    10.0.35.2    10.0.36.5
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.70/255.255.255.255    dst_ip=192.168.50.75/255.255.255.255
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${matches}    1
    Append Out Port Check    ${actions}    7
    Append Inner IPs Check    ${actions}    10.0.35.2    10.0.36.5
    Find Flow in DPCTL Output    ${matches}    ${actions}

Stop Endless Ping from h36_5 to h35_2
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address   h36_5    10.0.35.2


