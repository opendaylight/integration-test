*** Settings ***
Documentation     Tests for HTTP flow
Suite Setup       Set Test Variables    client_switch_ip=${GBP1}    client_docker=h35_2    client_ip=10.0.35.2    client_mac=00:00:00:00:35:02    same_webserver_docker=h36_4    same_webserver_ip=10.0.36.4
...               same_webserver_mac=00:00:00:00:36:04    diff_webserver_switch_ip=${GBP3}    diff_webserver_docker=h36_3    diff_webserver_ip=10.0.36.3    diff_webserver_mac=00:00:00:00:36:03
Default Tags      single-tenant    http    single-tenant-main
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot

*** Variables ***
${timeout}        10s

*** Testcases ***
Same switch, start SimpleHttpServer on h36_4
    [Documentation]    Same Switch (sw1)
    # Same subnet tests are not supported by current topology configuration;
    # clients and webservers are put in two different subnets
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Same switch, curl once from h35_2 to h36_4
    [Documentation]    Test HTTP req/resp from h35_2 to h36_4.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Same switch, start endless curl from h35_2 to h36_4
    [Documentation]    Init of endless HTTP session for purposes of traffic inspection.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Same switch, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_4
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check    ${matches}    6
    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    6
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Same switch, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP reply from h36_4 to h35_2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${matches}    6
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    4
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Same switch, stop endless curl from h35_2 to h36_4
    [Documentation]    Stopping endless HTTP session when traffic inspection finishes.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Same switch, stop SimpleHttpServer on h36_4
    [Documentation]    Shutting down HTTP service on h36_4.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Different switches, start SimpleHttpServer on h36_3
    [Documentation]    Different switches (sw1 -> sw3)
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Different switches, curl once from h35_2 to h36_3
    [Documentation]    Test HTTP req/resp from h35_2 to h36_3.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Different switches, start endless curl from h35_2 to h36_3
    [Documentation]    Init of endless HTTP session for purposes of traffic inspection.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Different switches, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    3
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Different switches, HTTP request ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${CLIENT_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append In Port Check    ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check    ${matches}    6
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    5
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Different switches, HTTP reply ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP reply from h36_3 to h35_2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    5
    Append Inner MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${matches}    6
    Append Tunnel Set Check    ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    3
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Different switches, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_3 to h35_2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check    ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${CLIENT_SWITCH_IP}
    Append In Port Check    ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${CLIENT_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${matches}    6
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    4
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Different switches, stop endless curl from h35_2 to h36_3
    [Documentation]    Stopping endless HTTP session when traffic inspection finishes.
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Different switches, stop SimpleHttpServer on h36_3
    [Documentation]    Shutting down HTTP service on h36_3.
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection
