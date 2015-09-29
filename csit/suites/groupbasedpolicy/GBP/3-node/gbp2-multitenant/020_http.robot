*** Settings ***
Documentation     Tests for HTTP flow
Force Tags      multi-tenant    http    multi-tenant-main
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/PathCheckUtils.robot
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

Tenant 1 Same Switch Simple Curl
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Same Switch Endless Curl Start
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Same Switch Endless Curl Flow On Source Switch
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check             ${matches}    4
    Append Encapsulated MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check               ${matches}    6

    Append Encapsulated MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Encapsulated IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    7

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same Switch Endless Curl Flow On Destination Switch
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check             ${matches}    7
    Append Encapsulated MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${matches}    6

    Append Encapsulated MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Encapsulated IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    4

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same Switch Endless Curl Stop
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Different Switches Simple Curl
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 1 Different Switches Endless Curl Start
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 1 Different Switches Flows On Source Switch
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check             ${matches}    4
    Append Encapsulated MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check               ${matches}    6

    Append Tunnel Set Check          ${actions}
    Append Encapsulated MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Encapsulated IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Flows On Destination Switch
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check             ${matches}    6
    Append Encapsulated MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${matches}    6

    Append Tunnel Set Check          ${actions}
    Append Encapsulated MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Encapsulated IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Endless Curl Stop
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection
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


Tenant 2 Same Switch Simple Curl
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Same Switch Endless Curl Start
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Same Switch Endless Curl Flow On Source Switch
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check             ${matches}    6
    Append Encapsulated MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check               ${matches}    6

    Append Encapsulated MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Encapsulated IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    8

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same Switch Endless Curl Flow On Destination Switch
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check             ${matches}    8
    Append Encapsulated MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${matches}    6

    Append Encapsulated MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Encapsulated IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same Switch Endless Curl Stop
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different Switches Simple Curl
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Tenant 2 Different Switches Endless Curl Start
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Tenant 2 Different Switches Flows On Source Switch
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check             ${matches}    6
    Append Encapsulated MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check               ${matches}    6

    Append Tunnel Set Check          ${actions}
    Append Encapsulated MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Encapsulated IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Flows On Destination Switch
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check             ${matches}    8
    Append Encapsulated MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check          ${matches}    0x0800
    Append Encapsulated IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${matches}    6

    Append Tunnel Set Check          ${actions}
    Append Encapsulated MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Encapsulated IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check               ${actions}    6
    Append Out Port Check            ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Endless Curl Stop
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection
