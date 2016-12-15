*** Settings ***
Documentation     Test suite to test cluster connection switchover
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Teardown     Custom Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP_1}    ${EMPTY}
${VIRTUAL_INTERFACE_1}    ${EMPTY}
${VIRTUAL_IP_MASK_1}    255.255.255.0
${VIRTUAL_IP_2}    ${EMPTY}
${VIRTUAL_INTERFACE_2}    ${EMPTY}
${VIRTUAL_IP_MASK_2}    255.255.255.0

*** Test Cases ***
Route Definition Test
    [Documentation]    Test Route update mechanism
    ${controller_index}    Get Any Controller
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
    ${active_controller}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}
    Clean Routing Configuration To Controller    controller${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_controller}

Isolation of SXP service follower Test
    [Documentation]    Test Route update mechanism during Cluster isolation
    ${any_controller}    Get Any Controller
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${any_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_2}    ${VIRTUAL_IP_MASK_2}    ${VIRTUAL_INTERFACE_2}    ${any_controller}
    : FOR    ${i}    IN RANGE    0    5
    \    ${controller_index}    Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Put Route Definition To Cluster
    [Arguments]    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}
    Put Routing Configuration To Controller    ${routes}    controller${follower}

Add Route Definition To Cluster
    [Arguments]    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    ${old_routes}    Get Routing Configuration From Controller    controller${follower}
    ${route}    Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes}    Route Definitions Xml    ${route}    ${old_routes}
    Put Routing Configuration To Controller    ${routes}    controller${follower}

Custom Clean SXP Cluster
    ${follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${follower}

Setup Custom SXP Cluster Session
    Setup SXP Cluster Session
    ${mac_addresses}    Map Followers To Mac Addresses
    Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    ${controller_index}    Get Active Controller
    ${v_ip}    Generate Virtual Ip    ${ODL_SYSTEM_1_IP}
    Set Suite Variable    ${VIRTUAL_IP_1}    ${v_ip}
    ${v_interface}    Generate Virtual Interface    ${v_ip}    ${controller_index}
    Set Suite Variable    ${VIRTUAL_INTERFACE_1}    ${v_interface}
    ${v_ip}    Generate Virtual Ip    ${VIRTUAL_IP_1}
    Set Suite Variable    ${VIRTUAL_IP_2}    ${v_ip}
    ${v_interface}    Generate Virtual Interface    ${v_ip}    ${controller_index}    ${VIRTUAL_INTERFACE_1}
    Set Suite Variable    ${VIRTUAL_INTERFACE_2}    ${v_interface}

Clean Custom SXP Cluster Session
    ${any_follower}    Get Any Controller
    Clean Routing Configuration To Controller    controller${any_follower}
    Clean SXP Cluster Session

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected afterwards reverts isolation
    Isolate_Member_From_List_Or_All    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_False    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${controller_index}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${controller_index}
    ${active_follower}    Get Active Controller
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_follower}
    Wait Until Keyword Succeeds    240    1    Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_2}    ${active_follower}
    Flush_Iptables_From_List_Or_All
    Wait Until Keyword Succeeds    240    1    Sync_Status_Should_Be_True    ${controller_index}
