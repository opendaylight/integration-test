*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Setup        Setup SXP Cluster
Test Teardown     Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1
${MAC_ADDRESS_TABLE}    &{EMPTY}

${VIRTUAL_IP}           192.168.50.20
${VIRTUAL_INTERFACE}    eth1:0
${VIRTUAL_IP_MASK}      255.255.255.0

*** Test Cases ***
Isolation of SXP service follower Test
    [Documentation]    Test SXP connection switchover only if Controller with SCS is isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

Isolation of SXP noservice follower Test
    [Documentation]    Test SXP connection switchover only if Controller without SCS are isolated
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index}    Get Inactive Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Setup Custom SXP Cluster Session
    [Documentation]
    Setup SXP Cluster Session
    ${mac_addresses}    Map Followers To Mac Addresses
    Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}
    ${any_follower}    Get Any Controller
    Put Routing Configuration To Controller    ${routes}    controller${any_follower}

Clean Custom SXP Cluster Session
    [Documentation]
    ${any_follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${any_follower}
    Clean SXP Cluster Session

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}

    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}

    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    Wait Until Keyword Succeeds    60    1    Check Cluster is Connected    ${CLUSTER_NODE_ID}    session=controller${active_follower}
    Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
