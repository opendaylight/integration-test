*** Settings ***
Documentation     SXP holds active SXP nodes and their connections only on the cluster owner node. This implies that all RPC operation logic must be executed only on cluster owner node. In case RPC is send to another cluster node it must be redirected to owner to be properly executed.
Suite Setup       SxpClusterLib.Setup SXP Cluster Session
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Resource          ../../../libraries/SxpBindingOriginsLib.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Nodes and Binding RPCs Redirecting
    [Documentation]    In order to successfully insert bindings into a SXP node then the node must be created and bindings must be added. This is sucessfull only if all operations are done on cluster owner node (becasue binding addition needs SXP node master database to be present on executing cluster node). To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-bindings RPC to the second cluster node and retieve bindings from the third cluster node.
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Bindings    1100    1.1.1.1/32    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    ${resp} =    SxpLib.Get Bindings    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    SxpLib.Should Contain Binding    ${resp}    1100    1.1.1.1/32
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Binding Origins RPCs Redirecting
    [Documentation]    Binding origin operations need to be executed on cluster owner because they rely on static map which is present solely on cluster owner. To test that binding origin RPCs are redirected to cluster owner first add binding origin to the first node then remove it from the second node (requires up-to date binding origin map) and then add it again to the third node (requires up-to date binding origin map).
    [Tags]    SXP Clustering Redirecting
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0    session=ClusterManagement__session_1
    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER    session=ClusterManagement__session_2
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0    session=ClusterManagement__session_3
    [Teardown]    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER    session=${CONTROLLER_SESSION}
