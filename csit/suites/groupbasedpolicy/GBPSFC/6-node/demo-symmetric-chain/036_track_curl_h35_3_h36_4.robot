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

Start HTTP on h36_4 on Port 80
    Switch Connection    GPSFC6_CONNECTION
    Start HTTP Service on Docker    h36_4    80

Curl 10.0.36.4 from h35_3
    Switch Connection    GPSFC1_CONNECTION
    Curl from Docker    h35_3    10.0.36.4    service_port=80

Start Endless Curl on h35_3 on port 80
    Start Endless Curl from Docker    h35_3    10.0.36.4    80    sleep=1

On GBPSFC1 Send HTTP req h35_3-h36_4 to GBPSFC2
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
    ${nsp_35_2-nsp_36_2}    GET NSP Value From Flow    ${output}
    Set Global Variable    ${NSP_path1}    ${nsp_35_2-nsp_36_2}

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.70    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.72
    Append NSI Check    ${actions}    255
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC3 Send HTTP req h35_3-h36_4 to GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC3_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71/255.255.255.255    dst_ip=192.168.50.72/255.255.255.255
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Inner IPs Check    ${matches}    10.0.35.3/0.0.0.0    10.0.36.4/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.72    dst_ip=192.168.50.71
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC5
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71    dst_ip=192.168.50.73
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Inner IPs Check    ${matches}    10.0.35.3/255.255.255.255    10.0.36.4/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.74
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC5 Send HTTP req h35_3-h36_4 to GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC5_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73/255.255.255.255    dst_ip=192.168.50.74/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Inner IPs Check    ${matches}    10.0.35.3/0.0.0.0    10.0.36.4/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC6
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.74/255.255.255.255    dst_ip=192.168.50.73/255.255.255.255
    Append NSI Check    ${matches}    253
    Append NSP Check    ${matches}    ${NSP_path1}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.75
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP_path1}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC6 Send HTTP req h35_3-h36_4 to h36_4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:36:04
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73    dst_ip=192.168.50.75
    Append Inner IPs Check    ${matches}    10.0.35.3    10.0.36.4
    Append NSP Check    ${matches}    ${NSP_path1}
    Append NSI Check    ${matches}    253
    Append Proto Check    ${matches}    6
    Append Tunnel Not Set Check    ${actions}
    Append Inner IPs Check    ${actions}    10.0.35.3    10.0.36.4
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    6
    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC6 Send HTTP resp h36_4-h35_3 to GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC6_CONNECTION
    Append In Port Check    ${matches}    6
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    10.0.36.4    10.0.35.3
    Append Proto Check    ${matches}    6
    Append L4 Check    ${matches}    src_port=80
    Append Inner Mac Check    ${actions}    dst_addr=00:00:00:00:35:03
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.3
    Append NSI Check    ${actions}    255
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    ${nsp_36_2-nsp_35_2}    GET NSP Value From Flow    ${output}
    Set Global Variable    ${NSP_path2}    ${nsp_36_2-nsp_35_2}

On GBPSFC4 Send HTTP resp h36_4-h35_3 to GBPSFC5
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.75    dst_ip=192.168.50.73
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Inner IPs Check    ${matches}    10.0.36.4/255.255.255.255    10.0.35.3/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.74
    Append NSI Check    ${actions}    255
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC5 Send HTTP resp h36_4-h35_3 to GBPSFC4
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC5_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73/255.255.255.255    dst_ip=192.168.50.74/255.255.255.255
    Append NSI Check    ${matches}    255
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Inner IPs Check    ${matches}    10.0.36.4/0.0.0.0    10.0.35.3/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.73
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC4 Send HTTP resp h36_4-h35_3 to GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC4_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.74/255.255.255.255    dst_ip=192.168.50.73/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC2 Send HTTP resp h36_4-h35_3 to GBPSFC3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.73/255.255.255.255    dst_ip=192.168.50.71/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Inner IPs Check    ${matches}    10.0.36.4/255.255.255.255    10.0.35.3/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.72
    Append NSI Check    ${actions}    254
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC3 Send HTTP resp h36_4-h35_3 to GBPSFC2
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC3_CONNECTION
    Append In Port Check    ${matches}    2
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71/255.255.255.255    dst_ip=192.168.50.72/255.255.255.255
    Append NSI Check    ${matches}    254
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Inner IPs Check    ${matches}    10.0.36.4/0.0.0.0    10.0.35.3/0.0.0.0
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.71
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC2 Send HTTP resp h36_4-h35_3 to GBPSFC1
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC2_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.72/255.255.255.255    dst_ip=192.168.50.71/255.255.255.255
    Append NSI Check    ${matches}    253
    Append NSP Check    ${matches}    ${NSP_path2}
    Append Inner IPs Check    ${matches}    10.0.36.4/255.255.255.255    10.0.35.3/255.255.255.255
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Outer IPs Check    ${actions}    dst_ip=192.168.50.70
    Append NSI Check    ${actions}    253
    Append NSP Check    ${actions}    ${NSP_path2}
    Append Out Port Check    ${actions}    2
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

On GBPSFC1 Send HTTP resp h36_4-h35_3 to h35_3
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append In Port Check    ${matches}    2
    Append Inner Mac Check    ${matches}    dst_addr=00:00:00:00:35:03
    Append Ether-Type Check    ${matches}    0x0800
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=192.168.50.71    dst_ip=192.168.50.70
    Append Inner IPs Check    ${matches}    10.0.36.4    10.0.35.3
    Append NSP Check    ${matches}    ${NSP_path2}
    Append NSI Check    ${matches}    253
    Append Proto Check    ${matches}    6
    Append Tunnel Not Set Check    ${actions}
    Append Inner IPs Check    ${actions}    10.0.36.4    10.0.35.3
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    5
    Find Flow in DPCTL Output    ${matches}    ${actions}

Compare NSPs
    Should Not Be Equal As Numbers    ${NSP_path1}    ${NSP_path2}

Stop Endless Curl on h35_3 on port 80
    Switch Connection    GPSFC1_CONNECTION
    Stop Endless Curl from Docker    h35_3

Stop HTTP on h36_4 on Port 80
    Switch Connection    GPSFC6_CONNECTION
    Stop HTTP Service on Docker    h36_4

