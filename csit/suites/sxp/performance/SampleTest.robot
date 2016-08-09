*** Settings ***
Documentation     Test suite to verify Behaviour in different topologies
Suite Setup       Setup SXP Environment
Suite Teardown    Clean SXP Environment
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Library           Remote     http://${NODE_0}:8270    WITH NAME    DefaultNode

*** Variables ***
${NODE_0}    127.0.0.1
${NODE_1}    127.0.1.0

*** Test Cases ***
Connectivity Test
    : FOR    ${num}    IN RANGE    0    5
    \    Add Connection To Nodes
    ${time_elapsed}    DefaultNode.Open Connections
    LOG    ${time_elapsed}

*** Keywords ***
Clean SXP Environment
    [Arguments]    ${ip}=127.0.0.1
    [Documentation]
    Delete Node    ${ip}
    DefaultNode.Stop Nodes

Add Connection To Nodes
    [Arguments]    ${mode_local}=listener    ${mode_remote}=speaker    ${version}=version4    ${PASSWORD}=${EMPTY}
    [Documentation]
    ${destination_port}    DefaultNode.Add Connection    ${version}    ${mode_remote}    ${NODE_0}    64999    ${PASSWORD}
    Add Connection    ${version}    ${mode_local}    ${NODE_1}    ${destination_port}    ${NODE_0}    ${PASSWORD}

