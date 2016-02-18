*** Settings ***
Documentation     Deep icmp traffic inspection.
...               Nodes are located on the same VM, in different subnets and are members of the same EPG.
Suite Setup       Start Connections
Suite Teardown    Close Connections
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot

*** Variables ***

*** Testcases ***
Ping from h36_4 to h35_4
    [Documentation]    Test icmp request.
    Set Test Variables    client_name=h36_4    client_ip=10.0.36.4    server_name=h35_4    server_ip=10.0.35.4    ether_type=0x0800    proto=1
    Switch Connection    GPSFC6_CONNECTION
    Ping from Docker    ${CLIENT_NAME}    ${SERVER_IP}

Start Endless Ping from h36_4 to h35_4
    [Documentation]    Starting of endless pinging for traffic inspection.
    Start Endless Ping from Docker    ${CLIENT_NAME}    ${SERVER_IP}

Find ICMP Req from h36_4 to h35_4 on GBPSFC6
    [Documentation]    Inspecting icmp req on GBPSFC6.
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=6    out_port=4    eth_type=0x0800    inner_src_ip=${CLIENT_IP}    inner_dst_ip=${SERVER_IP}
    ...    proto=${PROTO}

Find ICMP Resp from h35_4 to h36_4 on GBPSFC6
    [Documentation]    Inspecting icmp resp on GBPSFC6.
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=6    eth_type=0x0800    inner_src_ip=${SERVER_IP}    inner_dst_ip=${CLIENT_IP}
    ...    proto=${PROTO}

Stop Endless Ping from h36_4 to h35_4
    [Documentation]    Stoping of endless pinging after traffic inspection finishes.
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address    ${CLIENT_NAME}    ${SERVER_IP}
