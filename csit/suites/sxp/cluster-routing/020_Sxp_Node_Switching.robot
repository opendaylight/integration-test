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

*** Test Cases ***
Isolation Of SXP Service Follower W/O Bindings Listener Test
    [Documentation]    Device is listener. Connection between device and cluster must be established despite of cluster owner isolation
    [Setup]    Setup Nodes And Connections    listener
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    listener
    ${active_follower} =    Isolate SXP Controller    ${cluster_owner}    listener
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Check Connections    ${active_follower}    listener
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower W/O Bindings Speaker Test
    [Documentation]    Device is speaker. Connection between device and cluster must be established despite of cluster owner isolation
    [Setup]    Setup Nodes And Connections    speaker
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Check Connections    ${cluster_owner}    speaker
    ${active_follower} =    Isolate SXP Controller    ${cluster_owner}    speaker
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Check Connections    ${active_follower}    speaker
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower Listener Test
    [Documentation]    Device is listener. Cluster owner is isolated but bindings must be propagated to the device throught virtual IP
    [Setup]    Setup Nodes And Connections    listener
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Add Bindings To Node    ${CLUSTER_NODE_ID}    ClusterManagement__session_${cluster_owner}
    Check Connections    ${cluster_owner}    ${DEVICE_NODE_ID}    listener
    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    ${active_follower} =    Isolate SXP Controller With Bindings    ${cluster_owner}    ${DEVICE_NODE_ID}    listener
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Check Connections    ${active_follower}    ${DEVICE_NODE_ID}    listener
    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    [Teardown]    Clean Custom SXP Cluster

Isolation Of SXP Service Follower Speaker Test
    [Documentation]    Device is speaker. Cluster owner is isolated but bindings must be propagated to the cluster throught virtual IP
    [Setup]    Setup Nodes And Connections    speaker
    ${cluster_owner} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${cluster_owner}
    Add Bindings To Node    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    Check Connections    ${cluster_owner}    ${CLUSTER_NODE_ID}    speaker
    Check Bindings    ${CLUSTER_NODE_ID}    ClusterManagement__session_${cluster_owner}
    ${active_follower} =    Isolate SXP Controller With Bindings    ${cluster_owner}    ${CLUSTER_NODE_ID}    speaker
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${active_follower}
    Check Connections    ${cluster_owner}    ${CLUSTER_NODE_ID}    speaker
    Check Bindings    ${CLUSTER_NODE_ID}    ClusterManagement__session_${cluster_owner}
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
    SxpLib.Add Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    20    1    SxpLib.Check Node Started    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    SxpLib.Add Connection    version4    ${peer_mode}    ${VIRTUAL_IP}    64999    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    20    1    SxpLib.Check Node started    ${CLUSTER_NODE_ID}    system=${ODL_SYSTEM_1_IP}    session=${CONTROLLER_SESSION}
    SxpLib.Add Connection    version4    ${cluster_mode}    ${DEVICE_NODE_ID}    64999    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Clean Custom SXP Cluster Session
    [Documentation]    Cleans up resources generated by test
    SxpLib.Clean Routing Configuration To Controller    ${CONTROLLER_SESSION}
    SxpClusterLib.Clean SXP Cluster Session
    SxpClusterLib.Delete Virtual Interface

Clean Custom SXP Cluster
    [Documentation]    Disconnect SXP cluster topology
    ClusterManagement.Isolate_Member_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Check_Cluster_Is_In_Sync
    SxpLib.Delete Node    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}
    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Add Bindings To Node
    [Arguments]    ${node}    ${session}
    [Documentation]    Setup initial bindings to SXP device
    : FOR    ${i}    IN RANGE    1    ${BINDINGS}
    \    SxpLib.Add Bindings    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}

Isolate SXP Controller
    [Arguments]    ${controller_index}    ${peer_mode}
    [Documentation]    Isolate one of cluster nodes and perform check that Device is still connected
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${active_follower} =    SxpClusterLib.Get Owner Controller    ${running_member}
    [Return]    ${active_follower}

Isolate SXP Controller With Bindings
    [Arguments]    ${controller_index}    ${node}    ${peer_mode}
    [Documentation]    Isolate cluster owner and perform check that bindings are propagated
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    240    1    SxpClusterLib.Ip Addres Should Not Be Routed To Follower    ${MAC_ADDRESS_TABLE}    ${VIRTUAL_IP}    ${controller_index}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    ${active_follower} =    SxpClusterLib.Get Owner Controller    ${running_member}
    [Return]    ${active_follower}

Check Connections
    [Arguments]    ${controller_index}    ${peer_mode}
    [Documentation]    Check that connection is established between device and the cluster
    ${cluster_mode} =    Sxp.Get Opposing Mode    ${peer_mode}
    BuiltIn.Wait Until Keyword Succeeds    60    1    SxpClusterLib.Check Cluster is Connected    ${CLUSTER_NODE_ID}    mode=${cluster_mode}    session=ClusterManagement__session_${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    60    1    Check Device is Connected    ${DEVICE_NODE_ID}    ${VIRTUAL_IP}    ${peer_mode}
    ...    session=${DEVICE_SESSION}

Check Device is Connected
    [Arguments]    ${node}    ${remote_ip}    ${mode}=any    ${version}=version4    ${port}=64999    ${session}=session
    [Documentation]    Checks if SXP device is connected to the cluster. It means it has connection to ${VIRTUAL_IP} in state "on"
    ${resp} =    SxpLib.Get Connections    node=${node}    session=${session}
    SxpLib.Should Contain Connection    ${resp}    ${remote_ip}    ${port}    ${mode}    ${version}    on

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Checks that bindings were propagated to the peer
    ${resp}    SxpLib.Get Bindings    node=${node}    session=${session}
    : FOR    ${i}    IN RANGE    1    ${BINDINGS}
    \    SxpLib.Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32
