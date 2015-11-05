*** Settings ***
Documentation    Deep icmp traffic inspection.
...    Nodes are located on different VMs in different subnets and are members of different EPGs.
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

Ping from h36_5 to h35_2
    Switch Connection    GPSFC6_CONNECTION
    Ping from Docker    h36_5    10.0.35.2

Start Endless Ping from h36_5 to h35_2
    Start Endless Ping from Docker    h36_5    10.0.35.2

Find ICMP Req from h36_5 to h35_2 on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=7    out_port=3    eth_type=0x0800    inner_src_ip=10.0.36.5
    ...    inner_dst_ip=10.0.35.2    next_hop_ip=${GBPSFC1}    proto=1

Find ICMP Req from h36_5 to h35_2 on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    Inspect Classifier Inbound    in_port=3    out_port=4    eth_type=0x0800    inner_src_ip=10.0.36.5    inner_dst_ip=10.0.35.2
    ...    outer_src_ip=${GBPSFC6}    outer_dst_ip=${GBPSFC1}    proto=1

Find ICMP Resp from h35_2 to h36_5 on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=3    eth_type=0x0800    inner_src_ip=10.0.35.2
    ...    inner_dst_ip=10.0.36.5    next_hop_ip=${GBPSFC6}    proto=1

Find ICMP Resp from h35_2 to h36_5 on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    Inspect Classifier Inbound    in_port=3    out_port=7    eth_type=0x0800    inner_src_ip=10.0.35.2    inner_dst_ip=10.0.36.5
    ...    outer_src_ip=${GBPSFC1}    outer_dst_ip=${GBPSFC6}    proto=1

Stop Endless Ping from h36_5 to h35_2
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address   h36_5    10.0.35.2


