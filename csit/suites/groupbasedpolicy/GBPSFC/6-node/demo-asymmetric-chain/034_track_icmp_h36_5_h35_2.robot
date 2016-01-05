*** Settings ***
Documentation     Deep icmp traffic inspection.
...               Nodes are located on different VMs in different subnets and are members of different EPGs.
Suite Setup       Start Connections
Suite Teardown    Close Connections
Library           SSHLibrary
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Resource          ../Variables.robot
Resource          ../Connections.robot

*** Variables ***

*** Testcases ***
Ping from h36_5 to h35_2
    [Documentation]    Test icmp request.
    Set Test Variables    client_name=h36_5    client_ip=10.0.36.5    server_name=h35_2    server_ip=10.0.35.2    ether_type=0x0800    proto=1
    ...    vxlan_port=3
    Switch Connection    GPSFC6_CONNECTION
    Ping from Docker    ${CLIENT_NAME}    ${SERVER_IP}

Start Endless Ping from h36_5 to h35_2
    [Documentation]    Starting of endless pinging for traffic inspection.
    Start Endless Ping from Docker    ${CLIENT_NAME}    ${SERVER_IP}

Find ICMP Req from h36_5 to h35_2 on GBPSFC6
    [Documentation]    Inspecting icmp req on GBPSFC6.
    Switch Connection    GPSFC6_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=7    out_port=${VXLAN_PORT}    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}    inner_dst_ip=${SERVER_IP}
    ...    next_hop_ip=${GBPSFC1}    proto=${PROTO}

Find ICMP Req from h36_5 to h35_2 on GBPSFC1
    [Documentation]    Inspecting icmp req on GBPSFC1.
    Switch Connection    GPSFC1_CONNECTION
    Inspect Classifier Inbound    in_port=${VXLAN_PORT}    out_port=4    eth_type=${ETHER_TYPE}    inner_src_ip=${CLIENT_IP}    inner_dst_ip=${SERVER_IP}    outer_src_ip=${GBPSFC6}
    ...    outer_dst_ip=${GBPSFC1}    proto=${PROTO}

Find ICMP Resp from h35_2 to h36_5 on GBPSFC1
    [Documentation]    Inspecting icmp resp on GBPSFC1.
    Switch Connection    GPSFC1_CONNECTION
    ${flow}    Inspect Classifier Outbound    in_port=4    out_port=${VXLAN_PORT}    eth_type=${ETHER_TYPE}    inner_src_ip=${SERVER_IP}    inner_dst_ip=${CLIENT_IP}
    ...    next_hop_ip=${GBPSFC6}    proto=${PROTO}

Find ICMP Resp from h35_2 to h36_5 on GBPSFC6
    [Documentation]    Inspecting icmp resp on GBPSFC6.
    Switch Connection    GPSFC6_CONNECTION
    Inspect Classifier Inbound    in_port=${VXLAN_PORT}    out_port=7    eth_type=${ETHER_TYPE}    inner_src_ip=${SERVER_IP}    inner_dst_ip=${CLIENT_IP}    outer_src_ip=${GBPSFC1}
    ...    outer_dst_ip=${GBPSFC6}    proto=${PROTO}

Stop Endless Ping from h36_5 to h35_2
    [Documentation]    Stoping of endless pinging after traffic inspection finishes.
    Switch Connection    GPSFC6_CONNECTION
    Stop Endless Ping from Docker to Address    ${CLIENT_NAME}    ${SERVER_IP}
