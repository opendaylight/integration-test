*** Settings ***
Documentation     Test suite to test routing of virtual ip assigned to leader node in cluster enviroment
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Teardown     Custom Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP_1}    ${EMPTY}
${VIRTUAL_INTERFACE_1}    eth0:1
${VIRTUAL_IP_MASK_1}    255.255.255.0
${VIRTUAL_IP_2}    ${EMPTY}
${VIRTUAL_INTERFACE_2}    eth0:2
${VIRTUAL_IP_MASK_2}    255.255.255.0

*** Test Cases ***
Route Definition Test
    [Documentation]    Test Route update mechanism
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    ${active_controller}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Clean Routing Configuration To Controller    controller${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}

Isolation of SXP service follower Test
    [Documentation]    Test Route update mechanism during Cluster isolation
    ${any_controller}    Get Any Controller
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${any_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${any_controller}
    : FOR    ${i}    IN RANGE    0    2
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Custom Clean SXP Cluster
    [Documentation]    Cleans routing definitions form DS
    ${follower}    Get Active Controller
    Clean Routing Configuration To Controller    controller${follower}

Setup Custom SXP Cluster Session
    [Documentation]    Initialize session to cluster nodes, maps their MAC addresses and generate configuration for testing
    Setup SXP Cluster Session
    : FOR    ${i}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Issue Command On Karaf Console    log:set DEBUG org.opendaylight.sxp.route    ${ODL_SYSTEM_${i}_IP}
    ${mac_addresses}    Map Followers To Mac Addresses
    Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    ${v_ip}    Generate Virtual Ip    ${ODL_SYSTEM_1_IP}
    Set Suite Variable    ${VIRTUAL_IP_1}    ${v_ip}
    ${v_ip}    Generate Virtual Ip    ${VIRTUAL_IP_1}
    Set Suite Variable    ${VIRTUAL_IP_2}    ${v_ip}

Clean Custom SXP Cluster Session
    [Documentation]    Cleans test resources
    Custom Clean SXP Cluster
    Clean SXP Cluster Session

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that virtual ip is routed to new leader of cluster
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_follower}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_follower}
    Flush_Iptables_From_List_Or_All
    : FOR    ${controller_index}    IN RANGE    ${NUM_ODL_SYSTEM}
    \    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
