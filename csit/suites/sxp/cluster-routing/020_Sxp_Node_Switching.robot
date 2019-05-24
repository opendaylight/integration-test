*** Settings ***
Documentation     Test suite to test cluster connection and propagation switchover using virtual IP, this suite requires additional TOOLS_SYSTEM_2 VM.
...               VM is used for its assigned ip-address that will be overlayed by virtual-ip used in test suites.
...               Resources of this VM are not required. At suite start this node is shutted down to reduce routing conflicts.
Suite Setup       Setup Custom SXP Cluster Session
Suite Teardown    Clean Custom SXP Cluster Session
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot

*** Variables ***
${BINDINGS}       4
${NEW_OWNER}      ${EMPTY}

*** Test Cases ***
Isolation Of SXP Service Follower W/O Bindings Listener Test
    [Documentation]    Device is listener. Connection between device and cluster must be established despite of cluster owner isolation
    [Setup]    Setup Nodes And Connections    listener
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    listener
    Isolate SXP Controller    ${cluster_owner}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${NEW_OWNER}
    Check Connections    ${NEW_OWNER}    listener
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower W/O Bindings Speaker Test
    [Documentation]    Device is speaker. Connection between device and cluster must be established despite of cluster owner isolation
    [Setup]    Setup Nodes And Connections    speaker
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    speaker
    Isolate SXP Controller    ${cluster_owner}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${NEW_OWNER}
    Check Connections    ${NEW_OWNER}    speaker
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower Listener Test
    [Documentation]    Device is listener. Cluster owner is isolated but bindings must be propagated to the device throught virtual IP
    [Setup]    Setup Nodes And Connections    listener
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    listener
    Add Bindings To Node    ${CLUSTER_NODE_ID}    ClusterManagement__session_${cluster_owner}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    Isolate SXP Controller    ${cluster_owner}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${NEW_OWNER}
    Check Connections    ${NEW_OWNER}    listener
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower Speaker Test
    [Documentation]    Device is speaker. Cluster owner is isolated but bindings must be propagated to the cluster throught virtual IP
    [Setup]    Setup Nodes And Connections    speaker
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    speaker
    Add Bindings To Node    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    Check Bindings    ${CLUSTER_NODE_ID}    ClusterManagement__session_${cluster_owner}
    Isolate SXP Controller    ${cluster_owner}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${NEW_OWNER}
    Check Connections    ${NEW_OWNER}    speaker
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    Check Bindings    ${CLUSTER_NODE_ID}    ClusterManagement__session_${NEW_OWNER}
    [Teardown]    Clean Custom SXP Cluster

*** Keywords ***
Setup Custom SXP Cluster Session
    [Documentation]    Prepare topology for testing, creates sessions and generate Route definitions based on Cluster nodes IP
    SxpClusterLib.Shutdown Tools Node
    SxpClusterLib.Create Virtual Interface
    SxpClusterLib.Setup SXP Cluster Session
    SxpClusterLib.Setup Device Session
    Retrieve Mac-addresses
    Setup Virtual IP

Retrieve Mac-addresses
    [Documentation]    Create list of ODL nodes mac-addresses
    ${mac_addresses} =    SxpClusterLib.Map Followers To Mac Addresses
    BuiltIn.Set Suite Variable    ${MAC_ADDRESS_TABLE}    ${mac_addresses}

Setup Virtual IP
    [Documentation]    Enable routing to cluster through virtual IP
    ${route} =    Sxp.Route Definition Xml    ${VIRTUAL_IP}    ${VIRTUAL_IP_MASK}    ${VIRTUAL_INTERFACE}
    ${routes} =    Sxp.Route Definitions Xml    ${route}
    SxpLib.Put Routing Configuration To Controller    ${routes}    ${CONTROLLER_SESSION}

Setup Nodes And Connections
    [Arguments]    ${peer_mode}
    [Documentation]    Setup and connect SXP cluster topology and one device
    SxpClusterLib.Check Shards Status
    SxpLib.Add Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}    retry_open_timer=2
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpLib.Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    SxpLib.Add Connection    version4    ${peer_mode}    ${VIRTUAL_IP}    64999    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}    retry_open_timer=5
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Check Cluster Node Started    ${CLUSTER_NODE_ID}
    SxpLib.Add Connection    version4    ${cluster_mode}    ${DEVICE_NODE_ID}    64999    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Clean Custom SXP Cluster Session
    [Documentation]    Clean up resources generated by test
    SxpLib.Clean Routing Configuration To Controller    ${CONTROLLER_SESSION}
    SxpClusterLib.Clean SXP Cluster Session
    SxpClusterLib.Delete Virtual Interface

Clean Custom SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait_Until_Keyword_Succeeds    60    1    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${EMPTY}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    SxpLib.Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Add Bindings To Node
    [Arguments]    ${node}    ${session}
    [Documentation]    Setup initial bindings to SXP device/controller ${node} with ${session}
    FOR    ${i}    IN RANGE    1    ${BINDINGS}
        SxpLib.Add Bindings    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}
    END

Isolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Isolate cluster node specified by ${controller_index} and find new owner
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait_Until_Keyword_Succeeds    60    1    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${running_members}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${new_owner} =    SxpClusterLib.Get Owner Controller    ${running_member}
    BuiltIn.Set Test Variable    ${NEW_OWNER}    ${new_owner}

Check Connections
    [Arguments]    ${controller_index}    ${peer_mode}
    [Documentation]    Check that connection is established between device and the cluster
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    BuiltIn.Wait Until Keyword Succeeds    480x    1s    SxpClusterLib.Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=ClusterManagement__session_${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    480x    1s    Check Device is Connected    ${DEVICE_NODE_ID}    ${peer_mode}    session=${DEVICE_SESSION}

Check Device is Connected
    [Arguments]    ${node}    ${mode}    ${session}    ${version}=version4    ${port}=64999
    [Documentation]    Check if SXP device is connected to the cluster. It means it has connection to ${VIRTUAL_IP} in state "on"
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    SxpLib.Should Contain Connection    ${resp}    ${VIRTUAL_IP}    ${port}    ${mode}    ${version}    on

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Check that bindings were propagated to the peer ${node}
    ${resp} =    SxpLib.Get Bindings    node=${node}    session=${session}
    FOR    ${i}    IN RANGE    1    ${BINDINGS}
        SxpLib.Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32
    END
