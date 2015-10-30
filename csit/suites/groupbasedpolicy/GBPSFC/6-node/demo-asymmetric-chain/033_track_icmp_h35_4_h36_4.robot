*** Settings ***
Documentation    Deep icmp traffic inspection.
...    Nodes are located on the same VM, in different subnets and are members of the same EPG.
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
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=6    out_port=4    eth_type=0x0800    inner_src_ip=10.0.36.4
    ...    inner_dst_ip=10.0.35.4    proto=1

Find ICMP Resp from h35_4 to h36_4 on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=6    eth_type=0x0800    inner_src_ip=10.0.35.4
    ...    inner_dst_ip=10.0.36.4    proto=1

Stop Endless Ping from h36_4 to h35_4
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address   h36_4    10.0.35.4


