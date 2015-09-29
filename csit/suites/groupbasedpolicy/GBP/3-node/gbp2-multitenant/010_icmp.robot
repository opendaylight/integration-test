*** Settings ***
Documentation     Tests for ICMP flow
Force Tags      multi-tenant    icmp    multi-tenant-main
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

Tenant 1 Same Switch Start
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Ping From Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    DockerUtils.Start Endless Ping from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    SSHLibrary.Close Connection

Tenant 1 Same Switch Request Flow
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h35_2 to h36_3
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${matches}    1

    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    7

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same Switch Reply Flow
    [Documentation]  Assert matches and actions on megaflow of ICMP reply from h36_3 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    7
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    1

    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    4

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Same Switch Stop
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Ping from Docker to Address    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    SSHLibrary.Close Connection


Tenant 1 Different Switches Start
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Ping From Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    DockerUtils.Start Endless Ping from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    SSHLibrary.Close Connection

Tenant 1 Different Switches Request Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h35_2 to h36_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    4
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    1

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Request Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h35_2 to h36_2
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
    Append Proto Check        ${matches}    1

    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Reply Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h36_2 to h35_2
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    1

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Reply Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP reply from h36_2 to h35_2
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
    Append Proto Check        ${matches}    1

    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    4

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 1 Different Switches Stop
    [Tags]    tenant1
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Ping from Docker to Address    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    SSHLibrary.Close Connection

Setting Variables For Tenant 2
    Set Suite Variable    ${CLIENT_SWITCH_IP}  ${GBP1}
    Set Suite Variable    ${CLIENT_DOCKER}     h35_8
    Set Suite Variable    ${CLIENT_IP}         10.0.35.8
    Set Suite Variable    ${CLIENT_MAC}        00:00:00:00:35:08

    Set Suite Variable    ${SAME_WEBSERVER_DOCKER}  h36_6
    Set Suite Variable    ${SAME_WEBSERVER_IP}      10.0.36.6
    Set Suite Variable    ${SAME_WEBSERVER_MAC}     00:00:00:00:36:06

    Set Suite Variable    ${DIFF_WEBSERVER_SWITCH_IP}  ${GBP2}
    Set Suite Variable    ${DIFF_WEBSERVER_DOCKER}     h36_7
    Set Suite Variable    ${DIFF_WEBSERVER_IP}         10.0.36.7
    Set Suite Variable    ${DIFF_WEBSERVER_MAC}        00:00:00:00:36:07


Tenant 2 Same Switch Start
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Ping From Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    DockerUtils.Start Endless Ping from Docker    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    SSHLibrary.Close Connection

Tenant 2 Same Switch Request Flow
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${matches}    1

    Append Inner MAC Check    ${actions}    dst_addr=${SAME_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${SAME_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    8

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same Switch Reply Flow
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    8
    Append Inner MAC Check    ${matches}    src_addr=${SAME_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    1

    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${SAME_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Same Switch Stop
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Ping from Docker to Address    ${CLIENT_DOCKER}    ${SAME_WEBSERVER_IP}
    SSHLibrary.Close Connection


Tenant 2 Different Switches Start
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Ping From Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    DockerUtils.Start Endless Ping from Docker    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    SSHLibrary.Close Connection

Tenant 2 Different Switches Request Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h35_8 to h36_7
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    6
    Append Inner MAC Check    ${matches}    src_addr=${CLIENT_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${matches}    1

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${DIFF_WEBSERVER_MAC}
    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Request Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h35_8 to h36_7
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
    Append Proto Check        ${matches}    1

    Append Inner IPs Check    ${actions}    ${CLIENT_IP}    ${DIFF_WEBSERVER_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    8

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Reply Flow On Destination Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP request from h36_7 to h35_8
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${DIFF_WEBSERVER_SWITCH_IP}    timeout=${timeout}

    @{matches}    Create List
    @{actions}    Create List
    Append In Port Check      ${matches}    8
    Append Inner MAC Check    ${matches}    src_addr=${DIFF_WEBSERVER_MAC}
    Append Ether-Type Check   ${matches}    0x0800
    Append Inner IPs Check    ${matches}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${matches}    1

    Append Tunnel Set Check   ${actions}
    Append Inner MAC Check    ${actions}    dst_addr=${CLIENT_MAC}
    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    3

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Reply Flow On Source Switch
    [Documentation]  Assert matches and actions on megaflow of ICMP reply from h36_7 to h35_8
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
    Append Proto Check        ${matches}    1

    Append Inner IPs Check    ${actions}    ${DIFF_WEBSERVER_IP}    ${CLIENT_IP}
    Append Proto Check        ${actions}    1
    Append Out Port Check     ${actions}    6

    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}

    SSHLibrary.Close Connection

Tenant 2 Different Switches Stop
    [Tags]    tenant2
    ConnUtils.Connect and Login    ${CLIENT_SWITCH_IP}    timeout=${timeout}
    DockerUtils.Stop Endless Ping from Docker to Address    ${CLIENT_DOCKER}    ${DIFF_WEBSERVER_IP}
    SSHLibrary.Close Connection
