*** Settings ***
Documentation     Tests for HTTP flow
Default Tags      single-tenant    http    single-tenant-main
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/PathCheckUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s

${CLIENT_SWITCH_IP} =  ${GBP1}
${CLIENT_DOCKER} =     h35_2
${CLIENT_IP} =         10.0.35.2
${CLIENT_MAC} =        00:00:00:00:35:02

${SAME_WEBSERVER_DOCKER} =  h36_4
${SAME_WEBSERVER_IP} =      10.0.36.4
${SAME_WEBSERVER_MAC} =     00:00:00:00:36:04

${DIFF_WEBSERVER_SWITCH_IP} =  ${GBP3}
${DIFF_WEBSERVER_DOCKER} =     h36_3
${DIFF_WEBSERVER_IP} =         10.0.36.3
${DIFF_WEBSERVER_MAC} =        00:00:00:00:36:03


*** Testcases ***

# Same subnet tests are not supported by current topology configuration;
# clients and webservers are put in two different subnets

Same Switch Simple Curl
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Same Switch Endless Curl Start
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}    80
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Same Switch Request Flow
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_4
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
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Same Switch Reply Flow
    [Documentation]  Assert matches and actions on megaflow of HTTP reply from h36_4 to h35_2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    6
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

Same Switch Endless Curl Stop
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    DockerUtils.Stop HTTP Service on Docker    ${SAME_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Different Switches Simple Curl
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection

Different Switches Endless Curl Start
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}    80
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Start Endless Curl from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}    80
    SSHLibrary.Close Connection

Different Switches Request Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
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

Different Switches Request Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h35_2 to h36_3
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
    Append Out Port Check     ${actions}    5

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Different Switches Reply Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of HTTP reply from h36_3 to h35_2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List

    Append In Port Check      ${matches}    5
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

Different Switches Reply Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of HTTP request from h36_3 to h35_2
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

Different Switches Endless Curl Stop
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Curl from Docker    ${CLIENT_DOCKER}
    SSHLibrary.Close Connection
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop HTTP Service on Docker    ${DIFF_WEBSERVER_DOCKER}
    SSHLibrary.Close Connection
