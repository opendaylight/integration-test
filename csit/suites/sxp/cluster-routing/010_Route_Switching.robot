*** Settings ***
Documentation     Test suite to test cluster connection switchover using virtual IP, this suite requires additional TOOLS_SYSTEM VM.
...               VM is used for its assigned ip-address that will be overlayed by virtual-ip used in test suites.
...               Resources of this VM are not required and after start of Test suite this node shutted down and to reduce routing conflicts.
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Test Teardown     Custom Clean SXP Cluster
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Test Cases ***
Route Definition Test
    [Documentation]    Test Route update mechanism without cluster node isolation
    SxpClusterLib.Check Shards Status
    ${owner_controller} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${owner_controller}
    Add Route Definition To Cluster    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${owner_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${owner_controller}
    SxpLib.Clean Routing Configuration To Controller    ClusterManagement__session_${owner_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${owner_controller}
    Put Route Definition To Cluster    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${owner_controller}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${owner_controller}

Isolation of SXP service follower Test
    [Documentation]    Test Route update mechanism during Cluster isolation,
    ...    after each isolation virtual IP should be pre-routed to new leader
    SxpClusterLib.Check Shards Status
    ${any_controller} =    SxpClusterLib.Get Any Controller
    Add Route Definition To Cluster    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${any_controller}
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    Isolate SXP Controller    ${controller_index}

*** Keywords ***
Put Route Definition To Cluster
    [Arguments]    ${virtual_ip}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    [Documentation]    Put Route definition to DS replacing all present
    ${route} =    Sxp.Route Definition Xml    ${virtual_ip}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes} =    Sxp.Route Definitions Xml    ${route}
    SxpLib.Put Routing Configuration To Controller    ${routes}    ClusterManagement__session_${follower}

Add Route Definition To Cluster
    [Arguments]    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}    ${follower}
    [Documentation]    Add Route definition to DS
    ${old_routes} =    SxpLib.Get Routing Configuration From Controller    ClusterManagement__session_${follower}
    ${route} =    Sxp.Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes} =    Sxp.Route Definitions Xml    ${route}    ${old_routes}
    SxpLib.Put Routing Configuration To Controller    ${routes}    ClusterManagement__session_${follower}

Custom Clean SXP Cluster
    [Documentation]    Cleans up Route definitions
    SxpLib.Clean Routing Configuration To Controller    ${CONTROLLER_SESSION}

Setup Custom SXP Cluster Session
    [Documentation]    Prepare topology for testing, creates sessions and generate Route definitions based on Cluster nodes IP
    SxpClusterLib.Shutdown Tools Node
    SxpClusterLib.Setup SXP Cluster Session
    ${mac_addresses} =    SxpClusterLib.Map Followers To Mac Addresses
    BuiltIn.Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}
    SxpClusterLib.Create Virtual Interface

Clean Custom SXP Cluster Session
    [Documentation]    Cleans up resources generated by test
    SxpLib.Clean Routing Configuration To Controller    ${CONTROLLER_SESSION}
    SxpClusterLib.Clean SXP Cluster Session
    SxpClusterLib.Delete Virtual Interface

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate the cluster leader node and perform check that virtual IP is routed to a new leader,
    ...    afterwards unisolate old leader.
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${active_follower} =    SxpClusterLib.Get Owner Controller    ${running_member}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Check_Cluster_Is_In_Sync
