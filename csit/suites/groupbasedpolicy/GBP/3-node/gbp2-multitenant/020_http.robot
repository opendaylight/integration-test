*** Settings ***
Documentation     Tests for HTTP flow
Force Tags        multi-tenant    http    multi-tenant-main
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
Setting Variables for Tenant 1
    [Documentation]    Setting variables for test cases related to tenant 1.
    # Same subnet tests are not supported by current topology configuration;
    # clients and webservers are put in two different subnets
    Set Test Variables    client_switch_ip=${GBP1}    client_docker=h35_2    client_ip=10.0.35.2    client_mac=00:00:00:00:35:02    same_webserver_docker=h36_3    same_webserver_ip=10.0.36.3
    ...    same_webserver_mac=00:00:00:00:36:03    diff_webserver_switch_ip=${GBP3}    diff_webserver_docker=h36_2    diff_webserver_ip=10.0.36.2    diff_webserver_mac=00:00:00:00:36:02

Tenant 1 Same switch, start SimpleHttpServer on h36_3
    [Documentation]    Same Switch (sw1)
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, curl once from h35_2 to h36_3
    [Documentation]    Test HTTP req/rest session between docker located on the same switch.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, start endless curl from h35_2 to h36_3
    [Documentation]    Init of endless HTTP session between endpoints so that
    ...    HTTP traffic can be inspected.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
    [Tags]    tenant1
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
    Append Out Port Check    ${actions}    7
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 1 Same switch, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_3 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    7
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

Tenant 1 Same switch, stop endless curl from h35_2 to h36_3
    [Documentation]    Stopping endless HTTP session after traffic inspection is done.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Same switch, stop SimpleHttpServer on h36_3
    [Documentation]    Stoping HTTP service on docker container.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Different switches, start SimpleHttpServer on h36_2
    [Documentation]    Different switches (sw1 -> sw3)
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 1 Different switches, curl once from h35_2 to h36_2
    [Documentation]    Test HTTP req/resp between endpoints located on different switches.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Different switches, start endless curl from h35_2 to h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Different switches, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_2
    [Tags]    tenant1
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

Tenant 1 Different switches, HTTP request ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_2 to h36_2
    [Tags]    tenant1
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
    Append Out Port Check    ${actions}    6
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 1 Different switches, HTTP reply ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_2 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    6
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

Tenant 1 Different switches, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_2 to h35_2
    [Tags]    tenant1
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

Tenant 1 Different switches, stop endless curl from h35_2 to h36_2
    [Documentation]    Stopping endless HTTP session when traffic inspection finishes.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Different switches, stop SimpleHttpServer on h36_2
    [Documentation]    Terminating HTTP service on docker container.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Setting Variables For Tenant 2
    [Documentation]    Setting variables for test cases related to tenant 1.
    Set Test Variables    client_switch_ip=${GBP1}    client_docker=h35_8    client_ip=10.0.35.8    client_mac=00:00:00:00:35:08    same_webserver_docker=h36_6    same_webserver_ip=10.0.36.6
    ...    same_webserver_mac=00:00:00:00:36:06    diff_webserver_switch_ip=${GBP2}    diff_webserver_docker=h36_7    diff_webserver_ip=10.0.36.7    diff_webserver_mac=00:00:00:00:36:07

Tenant 2 Same switch, start SimpleHttpServer on h36_6
    [Documentation]    Same Switch (sw1)
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, curl once from h35_8 to h36_6
    [Documentation]    Test HTTP req/resp between endpoints on the same switch.
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, start endless curl from h35_8 to h36_6
    [Documentation]    Init if endless HTTP Session between endpoints on the same switch.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_8 to h36_6
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check    ${matches}    6
    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    8
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 2 Same switch, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_6 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    8
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check    ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${matches}    6
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check    ${actions}    6
    Append Out Port Check    ${actions}    6
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 2 Same switch, stop endless curl from h35_8 to h36_6
    [Documentation]    Terminating endless HTTP session after traffic inspection is done.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Same switch, stop SimpleHttpServer on h36_6
    [Documentation]    Stoping HTTP service on serving docker container.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different switches, start SimpleHttpServer on h36_7
    [Documentation]    Different switches (sw1 -> sw3)
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, curl once from h35_8 to h36_7
    [Documentation]    Test HTTP req/resp between endpoints located on different switches.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, start endless curl from h35_8 to h36_7
    [Documentation]    Starting endless HTTP session so that the traffic can be inspected.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP request ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    6
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

Tenant 2 Different switches, HTTP request ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h35_8 to h36_7
    [Tags]    tenant1
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
    Append Out Port Check    ${actions}    8
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP reply ovs-dpctl output check on sw3
    [Documentation]    Assert matches and actions on megaflow of HTTP request from h36_7 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check    ${matches}    8
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

Tenant 2 Different switches, HTTP reply ovs-dpctl output check on sw1
    [Documentation]    Assert matches and actions on megaflow of HTTP reply from h36_7 to h35_8
    [Tags]    tenant2
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
    Append Out Port Check    ${actions}    6
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    SSHLibrary.Close Connection

Tenant 2 Different switches, stop endless curl from h35_8 to h36_7
    [Documentation]    Terminanting endless HTTP session after traffic inspection
    ...    finishes.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different switches, stop SimpleHttpServer on h36_7
    [Documentation]    Stopping HTTP service on docker container.
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection
