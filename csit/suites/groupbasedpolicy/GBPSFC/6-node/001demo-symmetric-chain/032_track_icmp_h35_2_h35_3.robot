*** Settings ***
Documentation    Deep icmp traffic inspection.
...    Nodes are located on the same VM in the same subnet and are members of the same EPG.
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

Ping Once from h35_2 to h35_3
    Switch Connection    GPSFC1_CONNECTION
    Ping from Docker    h35_2    10.0.35.3

Start Endless Ping from h35_2 to h35_3
    Start Endless Ping from Docker    h35_2    10.0.35.3

Find ICMP Req from h35_2 to h35_3 on GBPSFC6
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=5    eth_type=0x0800    inner_src_ip=10.0.35.2
    ...    inner_dst_ip=10.0.35.3    proto=1

Find ICMP Resp from h35_3 to h35_2 on GBPSFC6
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=5    out_port=4    eth_type=0x0800    inner_src_ip=10.0.35.3
    ...    inner_dst_ip=10.0.35.2    proto=1

Stop Endless Ping from h35_2 to h35_3
    Switch Connection    GPSFC1_CONNECTION
    Stop Endless Ping from Docker to Address   h35_2    10.0.35.3


