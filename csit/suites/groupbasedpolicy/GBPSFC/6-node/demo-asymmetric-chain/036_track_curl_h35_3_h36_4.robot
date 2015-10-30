*** Settings ***
Documentation    Deep inspection of HTTP traffic on asymmetric chain.
...    Nodes are located on different VMs.
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

On GBPSFC1 Send HTTP req h35_3-h36_4 to GBPSFC2
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=5    out_port=2    eth_type=0x0800    inner_src_ip=10.0.35.3
    ...    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC2}    nsi=255    proto=6   dst_port=80
    ${nsp_35_3-nsp_36_4}    GET NSP Value From Flow    ${flow}
    Set Global Variable    ${NSP}    ${nsp_35_3-nsp_36_4}

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC3
    Switch Connection    GPSFC2_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC1}    outer_dst_ip=${GBPSFC2}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC3}    nsp=${NSP}    nsi=255    proto=6

On GBPSFC3 Send HTTP req h35_3-h36_4 to GBPSFC2
    Switch Connection    GPSFC3_CONNECTION
    Inspect Service Function    in_port=2    out_port=2    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC3}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC2}    nsp=${NSP}    received_nsi=255

On GBPSFC2 Send HTTP req h35_3-h36_4 to GBPSFC4
    Switch Connection    GPSFC2_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC3}    outer_dst_ip=${GBPSFC2}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC4}    nsp=${NSP}    nsi=254    proto=6

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC5
    Switch Connection    GPSFC4_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC2}    outer_dst_ip=${GBPSFC4}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC5}    nsp=${NSP}    nsi=254    proto=6

On GBPSFC5 Send HTTP req h35_3-h36_4 to GBPSFC4
    Switch Connection    GPSFC5_CONNECTION
    Inspect Service Function    in_port=2    out_port=2    outer_src_ip=${GBPSFC4}    outer_dst_ip=${GBPSFC5}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC4}    nsp=${NSP}    received_nsi=254

On GBPSFC4 Send HTTP req h35_3-h36_4 to GBPSFC6
    Switch Connection    GPSFC4_CONNECTION
     Inspect Service Function Forwarder    in_port=2    out_port=2    outer_src_ip=${GBPSFC5}    outer_dst_ip=${GBPSFC4}    eth_type=0x0800
    ...    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4    next_hop_ip=${GBPSFC6}    nsp=${NSP}    nsi=253    proto=6

On GBPSFC6 Send HTTP req h35_3-h36_4 to h36_4
    Switch Connection    GPSFC6_CONNECTION
    Inspect Classifier Inbound    in_port=2    out_port=6    eth_type=0x0800    inner_src_ip=10.0.35.3    inner_dst_ip=10.0.36.4
    ...    outer_src_ip=${GBPSFC4}    outer_dst_ip=${GBPSFC6}    nsp=${NSP}    nsi=253    proto=6

On GBPSFC6 Send HTTP resp h36_4-h35_3 to GBPSFC1
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=6    out_port=3    eth_type=0x0800    inner_src_ip=10.0.36.4
    ...    inner_dst_ip=10.0.35.3    next_hop_ip=${GBPSFC1}    proto=6   src_port=80

On GBPSFC1 Send HTTP resp h36_4-h35_3 to h35_3
    Switch Connection    GPSFC1_CONNECTION
    Inspect Classifier Inbound    in_port=3    out_port=5    eth_type=0x0800    inner_src_ip=10.0.36.4    inner_dst_ip=10.0.35.3
    ...    outer_src_ip=${GBPSFC6}    outer_dst_ip=${GBPSFC1}    proto=6

Stop Endless Curl on h36_2 on port 80
    Switch Connection    GPSFC1_CONNECTION
    BuiltIn.Sleep    2
    Stop Endless Curl from Docker    h35_3

Stop HTTP on h36_2 on Port 80
    Switch Connection    GPSFC6_CONNECTION
    Stop HTTP Service on Docker    h36_4

