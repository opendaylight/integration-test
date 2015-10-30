*** Settings ***
Documentation     Tests for HTTP flow
Force Tags      multi-tenant    http    multi-tenant-main
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s

${CLIENT_SWITCH_IP} =    ${GBP1}
${CLIENT_DOCKER} =    h35_2
${CLIENT_IP} =        10.0.35.2
${CLIENT_MAC} =       00:00:00:00:35:02

${SAME_WEBSERVER_DOCKER} =    h36_3
${SAME_WEBSERVER_IP} =        10.0.36.3
${SAME_WEBSERVER_MAC} =       00:00:00:00:36:03

${DIFF_WEBSERVER_SWITCH_IP} =    ${GBP3}
${DIFF_WEBSERVER_DOCKER} =    h36_2
${DIFF_WEBSERVER_IP} =        10.0.36.2
${DIFF_WEBSERVER_MAC} =       00:00:00:00:36:02


*** Testcases ***

# Same subnet tests are not supported by current topology configuration;
# clients and webservers are put in two different subnets

Tenant 1 Same switch, start SimpleHttpServer on h36_3
    [Documentation]  Same Switch (sw1)
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, curl once from h35_2 to h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, start endless curl from h35_2 to h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Same switch, HTTP request ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    7

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same switch, HTTP reply ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_3 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    7
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    4

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same switch, stop endless curl from h35_2 to h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Same switch, stop SimpleHttpServer on h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection


Tenant 1 Different switches, start SimpleHttpServer on h36_2
    [Documentation]  Different switches (sw1 -> sw3)
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 1 Different switches, curl once from h35_2 to h36_2
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
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check      ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different switches, HTTP request ovs-dpctl output check on sw3
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check   ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${CLIENT_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append In Port Check      ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different switches, HTTP reply ovs-dpctl output check on sw3
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_2 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different switches, HTTP reply ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_2 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check   ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${CLIENT_SWITCH_IP}
    Append In Port Check      ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    4

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different switches, stop endless curl from h35_2 to h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Different switches, stop SimpleHttpServer on h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection


Setting Variables For Tenant 2
    Set Suite Variable    ${CLIENT_SWITCH_IP}    ${GBP1}
    Set Suite Variable    ${CLIENT_DOCKER}    h35_8
    Set Suite Variable    ${CLIENT_IP}        10.0.35.8
    Set Suite Variable    ${CLIENT_MAC}       00:00:00:00:35:08

    Set Suite Variable    ${SAME_WEBSERVER_DOCKER}    h36_6
    Set Suite Variable    ${SAME_WEBSERVER_IP}        10.0.36.6
    Set Suite Variable    ${SAME_WEBSERVER_MAC}       00:00:00:00:36:06

    Set Suite Variable    ${DIFF_WEBSERVER_SWITCH_IP}    ${GBP2}
    Set Suite Variable    ${DIFF_WEBSERVER_DOCKER}    h36_7
    Set Suite Variable    ${DIFF_WEBSERVER_IP}        10.0.36.7
    Set Suite Variable    ${DIFF_WEBSERVER_MAC}       00:00:00:00:36:07


Tenant 2 Same switch, start SimpleHttpServer on h36_6
    [Documentation]  Same Switch (sw1)
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, curl once from h35_8 to h36_6
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, start endless curl from h35_8 to h36_6
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Same switch, HTTP request ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_8 to h36_6
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    8

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same switch, HTTP reply ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_6 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    8
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same switch, stop endless curl from h35_8 to h36_6
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Same switch, stop SimpleHttpServer on h36_6
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different switches, start SimpleHttpServer on h36_7
    [Documentation]  Different switches (sw1 -> sw3)
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, curl once from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, start endless curl from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP request ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP request ovs-dpctl output check on sw3
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_8 to h36_7
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check   ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${CLIENT_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append In Port Check      ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    6

    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    8

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP reply ovs-dpctl output check on sw3
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_7 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check      ${matches}    8
    Append Inner MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different switches, HTTP reply ovs-dpctl output check on sw1
    [Documentation]  Assert matches and actions on megaflow of HTTP reply from h36_7 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append Tunnel Set Check   ${matches}
    Append Outer IPs Check    ${matches}    src_ip=${DIFF_WEBSERVER_SWITCH_IP}
    Append Outer IPs Check    ${matches}    dst_ip=${CLIENT_SWITCH_IP}
    Append In Port Check      ${matches}    3
    Append Inner MAC Check    ${matches}    dst_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    6

    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    6
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different switches, stop endless curl from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different switches, stop SimpleHttpServer on h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection
