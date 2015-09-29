*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Variables ***
${NSP}

*** Testcases ***

Start HTTP on h36_4 on Port 80
    Switch Connection    GPSFC6_CONNECTION
    Start HTTP Service on Docker    h36_4    80

Curl 10.0.36.4 from h35_3
    Switch Connection    GPSFC1_CONNECTION
    Curl from Docker    h35_3    10.0.36.4    service_port=80

Start Endless Curl on h35_3 on port 80
    Start Endless Curl from Docker    h35_3    10.0.36.4    80    sleep=1

GBPSFC1 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    5
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Proto Check    ${matches}    6
    Append L4 Check    ${matches}    dst_port=80
    Append Out Port Check    ${actions}    2
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:36:04
    Append Inner IPs Check    ${actions}    10.0.35.3    10.0.36.4
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    255
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    ${nsp_35_3-nsp_36_4}    GET NSP Value From Flow    ${output}
    Set Global Variable    ${NSP}    ${nsp_35_3-nsp_36_4}

GBPSFC2 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.70    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.72
    Append NSI Check    ${actions}    255
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC3 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC3_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71/255.255.255.255    dst_ip=192.168.50.72/255.255.255.255
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP}
    Append Inner IPs Check    ${matches}    10.0.35.3/0.0.0.0    10.0.36.4/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC2 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.72    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC4 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC5
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71    dst_ip=192.168.50.73
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.74
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC5 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC5_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73/255.255.255.255    dst_ip=192.168.50.74/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP}
    Append Inner IPs Check    ${matches}    10.0.35.3/0.0.0.0    10.0.36.4/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC4 | h35_3 -> h36_4 | HTTP 80 | -> GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.74/255.255.255.255    dst_ip=192.168.50.73/255.255.255.255
    Append NSI Check    ${matches}    253
    Append NSP Check    ${matches}    ${NSP}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.75
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC6 | h35_3 -> h35_6 | HTTP 80 | -> h36_4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73    dst_ip=192.168.50.75
    Append Inner IPs Check    ${matches}    10.0.35.3    10.0.36.4
    Append NSP Check    ${matches}    ${NSP}
    Append NSI Check    ${matches}    253
    Append Proto Check    ${matches}    6
    Append Inner IPs Check    ${actions}    10.0.35.3    10.0.36.4
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    6
    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC6 | h36_4 -> h35_3 | HTTP 80 | -> h35_3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    6
    Append Inner Mac Check    ${matches}    src_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    10.0.36.4    10.0.35.3
    Append Proto Check    ${matches}    6
    Append L4 Check    ${matches}    src_port=80
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:35:03
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.3
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.70
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    3
    Find Flow in DPCTL Output    ${matches}    ${actions}

GBPSFC1 | h36_4 -> h35_3 | HTTP 80 | -> h35_3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    3
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    10.0.36.4    10.0.35.3
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.75/255.255.255.255    dst_ip=192.168.50.70/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.3
    Append Tunnel Not Set Check    ${actions}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}   5
    Find Flow in DPCTL Output    ${matches}    ${actions}

Stop Curl
    Switch Connection    GPSFC1_CONNECTION
    BuiltIn.Sleep    2
    Stop Endless Curl from Docker    h35_3

HTTP Stop h36_4 80a
    Switch Connection    GPSFC6_CONNECTION
    Stop HTTP Service on Docker    h36_4

