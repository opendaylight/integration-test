*** Settings ***
Documentation     Test suite to test cluster binding propagation
Suite Setup       SxpClusterLib.Setup SXP Cluster Session With Device
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Variables ***
${RUNNING_MEMBER}    ${EMPTY}

*** Test Cases ***
Isolation of SXP service follower Test Speaker Part
    [Documentation]    Test SXP binding propagation from device to cluster after cluster owner is isolated
    [Setup]    Setup Custom SXP Cluster    speaker
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${controller_index}
    Isolate SXP Controller    ${controller_index}    ${INADDR_ANY}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${RUNNING_MEMBER}
    UnIsolate SXP Controller    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${controller_index}
    [Teardown]    SxpClusterLib.Clean SXP Cluster

Isolation of SXP noservice follower Test Speaker Part
    [Documentation]    Test SXP binding propagation from device to cluster after cluster (not owner) node is isolated
    [Setup]    Setup Custom SXP Cluster    speaker
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${controller_index}
    Isolate SXP Controller    ${controller_index}    ${INADDR_ANY}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${RUNNING_MEMBER}
    UnIsolate SXP Controller    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${INADDR_ANY}    ClusterManagement__session_${controller_index}
    [Teardown]    SxpClusterLib.Clean SXP Cluster

Isolation of SXP service follower Test Listener Part
    [Documentation]    Test SXP binding propagation from cluster to device after cluster owner is isolated
    [Setup]    Setup Custom SXP Cluster    listener    ${INADDR_ANY}    ${CONTROLLER_SESSION}
    ${controller_index} =    SxpClusterLib.Get Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    UnIsolate SXP Controller    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    [Teardown]    SxpClusterLib.Clean SXP Cluster

Isolation of SXP noservice follower Test Listener Part
    [Documentation]    Test SXP binding propagation from cluster to device after cluster (not owner) node is isolated
    [Setup]    Setup Custom SXP Cluster    listener    ${INADDR_ANY}    ${CONTROLLER_SESSION}
    ${controller_index} =    SxpClusterLib.Get Not Owner Controller
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    Isolate SXP Controller    ${controller_index}    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    UnIsolate SXP Controller    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    Check Bindings    ${DEVICE_NODE_ID}    ${DEVICE_SESSION}
    [Teardown]    SxpClusterLib.Clean SXP Cluster

*** Keywords ***
Setup Custom SXP Cluster
    [Arguments]    ${mode}    ${node}=${DEVICE_NODE_ID}    ${session}=${DEVICE_SESSION}
    [Documentation]    Setup custom SXP cluster topology with ${NUM_ODL_SYSTEM} nodes and one device
    SxpClusterLib.Check Shards Status
    SxpClusterLib.Setup SXP Cluster    ${mode}
    FOR    ${i}    IN RANGE    1    25
        SxpLib.Add Bindings    ${i}0    ${i}.${i}.${i}.${i}/32    node=${node}    session=${session}
    END

Isolate SXP Controller
    [Arguments]    ${controller_index}    ${node}    ${session}=ClusterManagement__session_${controller_index}
    [Documentation]    Isolate one of cluster nodes and perform check that device is connected
    @{running_members} =    ClusterManagement.Isolate_Member_From_List_Or_All    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${running_members}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    ${running_member} =    Collections.Get From List    ${running_members}    0
    BuiltIn.Set Test Variable    ${RUNNING_MEMBER}    ${running_member}
    BuiltIn.Wait Until Keyword Succeeds    240x    1s    ClusterManagement.Sync_Status_Should_Be_False    ${controller_index}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

UnIsolate SXP Controller
    [Arguments]    ${controller_index}
    [Documentation]    Un-Isolate one of cluster nodes and perform check that device is connected
    ClusterManagement.Flush_Iptables_From_List_Or_All
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    ClusterManagement.Verify_Members_Are_Ready    member_index_list=${EMPTY}    verify_cluster_sync=True    verify_restconf=True
    ...    verify_system_status=False    service_list=${EMPTY_LIST}
    BuiltIn.Wait Until Keyword Succeeds    120x    1s    SxpClusterLib.Check Device is Connected    ${DEVICE_NODE_ID}    session=${DEVICE_SESSION}

Check Bindings
    [Arguments]    ${node}    ${session}
    [Documentation]    Checks that bindings were propagated to Peer
    ${resp} =    SxpLib.Get Bindings    node=${node}    session=${session}
    FOR    ${i}    IN RANGE    1    25
        SxpLib.Should Contain Binding    ${resp}    ${i}0    ${i}.${i}.${i}.${i}/32
    END
