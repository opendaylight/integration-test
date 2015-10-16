*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Library           Collections
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/PathCheckUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../Connections.robot
Library           OperatingSystem
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Variables ***
${NSP}

*** Testcases ***

GBPSFC1 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    4
    Append Encapsulated MAC Check    ${matches}    src_addr=00:00:00:00:35:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    6
    Append L4 Check    ${matches}    dst_port=80
    Append Out Port Check    ${actions}    2
    Append Encapsulated MAC Check    ${actions}    dst_addr=00:00:00:00:36:02
    Append Encapsulated IPs Check    ${actions}    10.0.35.2    10.0.36.2
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    255
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    ${nsp_35_2-nsp_36_2}    GET NSP Value From Flow    ${output}
    Set Global Variable    ${NSP}    ${nsp_35_2-nsp_36_2}

GBPSFC2 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Encapsulated MAC Check    ${matches}    dst_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.70    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP}
    Append Encapsulated IPs Check    ${matches}    10.0.35.2/255.255.255.255    10.0.36.2/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.72
    Append NSI Check    ${actions}    255
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC3 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC3_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.71/255.255.255.255    dst_ip=192.168.50.72/255.255.255.255
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP}
    Append Encapsulated IPs Check    ${matches}    10.0.35.2/0.0.0.0    10.0.36.2/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC2 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Encapsulated MAC Check    ${matches}    dst_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.72    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Encapsulated IPs Check    ${matches}    10.0.35.2/255.255.255.255    10.0.36.2/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC4 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC5
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Encapsulated MAC Check    ${matches}    dst_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.71    dst_ip=192.168.50.73
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Encapsulated IPs Check    ${matches}    10.0.35.2/255.255.255.255    10.0.36.2/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.74
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC5 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC5_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.73/255.255.255.255    dst_ip=192.168.50.74/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Encapsulated IPs Check    ${matches}    10.0.35.2/0.0.0.0    10.0.36.2/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC4 | h35_2 -> h36_2 | HTTP 80 | -> GBPSFC1
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Encapsulated MAC Check    ${matches}    dst_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.74/255.255.255.255    dst_ip=192.168.50.73/255.255.255.255
    Append NSI Check    ${matches}    253
    Append NSP Check    ${matches}    ${NSP}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.70
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC1 | h35_2 -> h35_6 | HTTP 80 | -> h36_2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    2
    Append Encapsulated MAC Check    ${matches}    dst_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Next Hop IPs Check    ${matches}    src_ip=192.168.50.73    dst_ip=192.168.50.70
    Append Encapsulated IPs Check    ${matches}    10.0.35.2    10.0.36.2
    Append NSP Check    ${matches}    ${NSP}
    Append NSI Check    ${matches}    253
    Append Proto Check    ${matches}    6
    Append Encapsulated IPs Check    ${actions}    10.0.35.2    10.0.36.2
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    6
    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC1 | h35_6 -> h35_2 | HTTP 80 | -> h36_2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    6
    Append Encapsulated MAC Check    ${matches}    src_addr=00:00:00:00:36:02
    Append Ether-Type Check    ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    10.0.36.2    10.0.35.2
    Append Proto Check    ${matches}    6
    Append L4 Check    ${matches}    src_port=80
    Append Encapsulated MAC Check    ${actions}    dst_addr=00:00:00:00:35:02
    Append Encapsulated IPs Check    ${actions}    10.0.36.2    10.0.35.2
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    4
    Find Flow in DPCTL Output    ${matches}    ${actions}
