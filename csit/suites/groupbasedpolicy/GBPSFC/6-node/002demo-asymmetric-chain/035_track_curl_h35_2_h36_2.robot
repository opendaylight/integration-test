*** Settings ***
Documentation    Deep inspection of HTTP traffic on asymmetric chain.
...    Nodes are located on the same VM.
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

Start HTTP on h36_2 on Port 80
    Switch Connection    GPSFC1_CONNECTION
    Start HTTP Service on Docker    h36_2    80

Curl 10.0.36.2 from h35_2
    Curl from Docker    h35_2    10.0.36.2    service_port=80

Start Endless Curl on h35_2 on port 80
    Start Endless Curl from Docker    h35_2    10.0.36.2    80    sleep=1

On GBPSFC1 Send HTTP req h35_2-h36_2 to GBPSFC2
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=2    eth_type=0x0800    inner_src_ip=10.0.35.2
    ...    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC2}    nsi=255    proto=6   dst_port=80
    ${nsp_35_2-nsp_36_2}    GET NSP Value From Flow    ${flow}
    Set Global Variable    ${NSP}    ${nsp_35_2-nsp_36_2}

On GBPSFC2 Send HTTP req h35_2-h36_2 to GBPSFC3
    Switch Connection    GPSFC2_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC1}    outer_dst_ip=${GBPSFC2}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC3}    nsp=${NSP}    nsi=255    proto=6

On GBPSFC3 Send HTTP req h35_2-h36_2 to GBPSFC2
    Switch Connection    GPSFC3_CONNECTION
    Inspect Service Function    in_port=2    out_port=2    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC3}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC2}    nsp=${NSP}    received_nsi=255

On GBPSFC2 Send HTTP req h35_2-h36_2 to GBPSFC4
    Switch Connection    GPSFC2_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC3}    outer_dst_ip=${GBPSFC2}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC4}    nsp=${NSP}    nsi=254    proto=6

On GBPSFC4 Send HTTP req h35_2-h36_2 to GBPSFC5
    Switch Connection    GPSFC4_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC4}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC5}    nsp=${NSP}    nsi=254    proto=6

On GBPSFC5 Send HTTP req h35_2-h36_2 to GBPSFC4
    Switch Connection    GPSFC5_CONNECTION
    Inspect Service Function    in_port=2    out_port=2    outer_src_ip=${GBPSFC4}    outer_dst_ip=${GBPSFC5}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC4}    nsp=${NSP}    received_nsi=254

On GBPSFC4 Send HTTP req h35_2-h36_2 to GBPSFC1
    Switch Connection    GPSFC4_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC5}    outer_dst_ip=${GBPSFC4}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2    next_hop_ip=${GBPSFC1}    nsp=${NSP}    nsi=253    proto=6

On GBPSFC1 Send HTTP req h35_2-h36_2 to h36_2
    Switch Connection    GPSFC1_CONNECTION
    Inspect Classifier Inbound    in_port=2    out_port=6    eth_type=0x0800    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.2
    ...    outer_src_ip=${GBPSFC4}    outer_dst_ip=${GBPSFC1}    nsp=${NSP}    nsi=253    proto=6

On GBPSFC1 Send HTTP resp h36_2-h35_2 to h35_2
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=6    out_port=4    eth_type=0x0800    inner_src_ip=10.0.36.2
    ...    inner_dst_ip=10.0.35.2   proto=6   src_port=80

Stop Endless Curl on h36_2 on port 80
    BuiltIn.Sleep    2
    Stop Endless Curl from Docker    h35_2

Stop HTTP on h36_2 on Port 80
    Stop HTTP Service on Docker    h36_2

