*** Settings ***
Library           SSHLibrary
Resource          ../vars.robot
Resource          ../vpp_node_setup.robot
Resource          ../keywords.robot

*** Variables ***
${ODL_SYSTEM_1_IP}
${ODL_SYSTEM_2_IP}
${ODL_SYSTEM_3_IP}

*** Test Cases ***
Initialize First Node
    [Documentation]    Install and configure first vpp, hc to be able to connect odl to node
    Start VPP Nodes  ${VPP_NODE_1}    ${CURDIR}/scripts

Initialize Second Node
    [Documentation]    Install and configure second vpp, hc to be able to connect odl to node
    Start VPP Nodes  ${VPP_NODE_1}    ${CURDIR}/scripts

Initialize Third Node
    [Documentation]    Install and configure third vpp, hc to be able to connect odl to node
    Start VPP Nodes  ${VPP_NODE_1}    ${CURDIR}/scripts

Identify GBP Master Instance
    [Documentation]    Identify on which ODL node are present active instances of GBP modules
    Log Many    ${ODL_SYSTEM_1_IP}    ${ODL_SYSTEM_2_IP}    ${ODL_SYSTEM_3_IP}
    ${GBP_INSTANCE_COUNT} =  Wait Until Keyword Succeeds    5 x    60 sec    Search For Gbp Master
    Should Be Equal As Integers    ${GBP_INSTANCE_COUNT}    1
    Log    GBP index ${GBP_MASTER_INDEX}
