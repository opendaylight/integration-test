*** Settings ***
Library           SSHLibrary
Resource          ../Variables.robot
Resource          ../Nodes.robot
Resource          ../../../../libraries/KarafKeywords.robot
Resource          ../../../../libraries/GBP/DockerUtils.robot

*** Test Cases ***
Register Nodes
    Set Suite Variable    ${ODL_SYSTEM_IP}    ${GBP_MASTER_IP}
    Register Node    controller    ${VPP1}
    Wait For Karaf Log    controller is capable and ready
    Register Node    compute0    ${VPP2}
    Wait For Karaf Log    compute0 is capable and ready
    Register Node    compute1    ${VPP3}
    Wait For Karaf Log    compute1 is capable and ready
    Switch Connection    VPP1_CONNECTION
    Ping From Docker    docker1    ${VPP1}