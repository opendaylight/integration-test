*** Settings ***
Documentation    Basic tests for ping and curl
Library           SSHLibrary
Library           Collections
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/PathCheckUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Library           OperatingSystem
Suite Setup       Start Connections
Suite Teardown    Close Connections

#Find Flow in DPCTL Output        [Arguments]    ${flow_match_criteria}    ${flow_action_criteria}
#Get Matches Part                 [Arguments]    ${ovs-dpctl_flow}
#Get Actions Part                 [Arguments]    ${ovs-dpctl_flow}
#Check Match                      [Arguments]    ${string}    @{match_criteria}
#Append Proto Check               [Arguments]    ${list}    ${proto}
#Append Encapsulated MAC Check    [Arguments]    ${list}    ${src_addr}=${EMPTY}    ${dst_addr}=${EMPTY}
#Append Encapsulated IPs Check    [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
#Append Next Hop IPs Check        [Arguments]    ${list}    ${src_ip}=${EMPTY}    ${dst_ip}=${EMPTY}
#Append In Port Check             [Arguments]    ${list}    ${in_port}
#Append L4 Check                  [Arguments]    ${list}    ${src_port}=${EMPTY}    ${dst_port}=${EMPTY}
#Append Out Port Check            [Arguments]    ${list}    ${out_port}
#Append NSI Check                 [Arguments]    ${list}    ${nsi}
#Append Tunnel Set Check          [Arguments]    ${list}
#Append Ether-Type Check          [Arguments]    ${list}    ${eth_type}
#Get NSP Value From Flow          [Arguments]    ${flow}

*** Variables ***
${NSP}

*** Testcases ***

Get NSP Test Case
    @{matches}    Create List
    @{actions}    Create List
    Switch Connection    GPSFC1_CONNECTION
    Append L4 Check    ${matches}    dst_port=80
    Append Ether-Type Check    ${matches}    0x0800
    Append Encapsulated MAC Check    ${matches}    src_addr=00:00:00:00:35:02    # container -> switch
    

    Append Encapsulated MAC Check    ${actions}    dst_addr=00:00:00:00:36:02
    Append Encapsulated IPs Check    ${actions}    10.0.35.2    10.0.36.2
    Append Next Hop IPs Check    ${actions}    dst_ip=192.168.50.71
    Append Out Port Check    ${actions}    2
    Append Proto Check    ${actions}    6
    Append Tunnel Set Check    ${actions}
    Append NSI Check    ${actions}    255
    ${output}    Find Flow in DPCTL Output    ${matches}    ${actions}
    ${nsp_35_2-nsp_36_2}    GET NSP Value From Flow    ${output}
    Set Global Variable    ${NSP}    ${nsp_35_2-nsp_36_2}
    Log    ${NSP}

*** Keywords ***

Start Connections
    SSHLibrary.Open Connection    ${GBPSFC1}    alias=GPSFC1_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC2}    alias=GPSFC2_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC3}    alias=GPSFC3_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC4}    alias=GPSFC4_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC5}    alias=GPSFC5_CONNECTION
    Utils.Flexible Mininet Login
    SSHLibrary.Open Connection    ${GBPSFC6}    alias=GPSFC6_CONNECTION
    Utils.Flexible Mininet Login

Close Connections
    Switch Connection    GPSFC1_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC2_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC3_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC4_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC5_CONNECTION
    SSHLibrary.Close Connection
    Switch Connection    GPSFC6_CONNECTION
    SSHLibrary.Close Connection

