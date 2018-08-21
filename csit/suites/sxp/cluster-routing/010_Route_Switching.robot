*** Settings ***
Documentation     Test suite to test cluster connection switchover using virtual ip, this suite requires additional TOOLS_SYSTEM VM.
...               VM is used for its assigned ip-address that will be overlayed by virtual-ip used in test suites.
...               Resources of this VM are not required and after start of Test suite this node shutted down and to reduce routing conflicts.
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Teardown     Custom Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${SAMPLES}        1
${MAC_ADDRESS_TABLE}    &{EMPTY}
${VIRTUAL_IP_1}    ${TOOLS_SYSTEM_2_IP}
${VIRTUAL_INTERFACE_1}    eth0:0
${VIRTUAL_IP_MASK_1}    255.255.255.0

*** Test Cases ***
Route Definition Test
    [Documentation]    Test Route update mechanism without cluster node isolation
    SxpClusterLib.Check Shards Status
    ${active_controller} =    SxpClusterLib.Get Active Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${active_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    SxpLib.Clean Routing Configuration To Controller    controller${active_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${active_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_controller}

Isolation of SXP service follower Test
    [Documentation]    Test Route update mechanism during Cluster isolation,
    ...    after each isolation virtual ip should be pre-routed to new leader
    SxpClusterLib.Check Shards Status
    ${any_controller} =    SxpClusterLib.Get Any Controller
    Add Route Definition To Cluster    ${VIRTUAL_IP_1}    ${VIRTUAL_IP_MASK_1}    ${VIRTUAL_INTERFACE_1}    ${any_controller}
    : FOR    ${i}    IN RANGE    0    ${SAMPLES}
    \    ${controller_index} =    SxpClusterLib.Get Active Controller
    \    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Put Route Definition To Cluster
    [Arguments]    ${virtual_ip}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    [Documentation]    Put Route definition to DS replacing all present
    ${route} =    Sxp.Route Definition Xml    ${virtual_ip}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes} =    Sxp.Route Definitions Xml    ${route}
    SxpLib.Put Routing Configuration To Controller    ${routes}    controller${follower}

Add Route Definition To Cluster
    [Arguments]    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    [Documentation]    Add Route definition to DS
    ${old_routes} =    SxpLib.Get Routing Configuration From Controller    controller${follower}
    ${route} =    Sxp.Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes} =    Sxp.Route Definitions Xml    ${route}    ${old_routes}
    SxpLib.Put Routing Configuration To Controller    ${routes}    controller${follower}

Custom Clean SXP Cluster
    [Documentation]    Cleans up Route definitions
    ${follower} =    SxpClusterLib.Get Active Controller
    SxpLib.Clean Routing Configuration To Controller    controller${follower}

Setup Custom SXP Cluster Session
    [Documentation]    Prepare topology for testing, creates sessions and generate Route definitions based on Cluster nodes ip
    SxpClusterLib.Shutdown Tools Node
    SxpClusterLib.Setup SXP Cluster Session
    ${mac_addresses} =    SxpClusterLib.Map Followers To Mac Addresses
    BuiltIn.Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    SxpClusterLib.Create Virtual Interface

Clean Custom SXP Cluster Session
    [Documentation]    Cleans up resources generated by test
    ${controller_index} =    SxpClusterLib.Get Active Controller
    SxpLib.Clean Routing Configuration To Controller    controller${controller_index}
    SxpClusterLib.Clean SXP Cluster Session
    SxpClusterLib.Delete Virtual Interface

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that virtual ip is routed to another cluster node,
    ...    afterwards unisolate old leader.
    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${controller_index}
    ${active_follower} =    SxpClusterLib.Get Active Controller
    BuiltIn.Wait Until Keyword Succeeds    120    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP_1}    ${active_follower}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120    1    ClusterManagement.Sync_Status_Should_Be_True    ${controller_index}
