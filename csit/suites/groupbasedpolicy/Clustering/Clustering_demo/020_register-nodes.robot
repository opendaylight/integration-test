*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    60 seconds
Resource          ../Variables.robot
Resource          ../Nodes.robot
Resource          ../Connections.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/GBP/DockerUtils.robot

*** Test Cases ***
Register Nodes
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    Register Node    controller    ${VPP1}
    Wait For Karaf Log    controller is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Register Node    compute0    ${VPP2}
    Wait For Karaf Log    compute0 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Register Node    compute1    ${VPP3}
    Wait For Karaf Log    compute1 is capable and ready    karaf_ip=${ODL_SYSTEM_IP}
    Switch Connection    VPP1_CONNECTION
    Ping From Docker    docker1    ${VPP1}