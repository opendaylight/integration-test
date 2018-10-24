*** Settings ***
Documentation     SXP holds active SXP nodes and their connections only on the cluster owner node. This implies that all RPC operation logic must be executed only on cluster owner node. In case RPC is send to another cluster node it must be redirected to owner to be properly executed.
Suite Setup       SxpClusterLib.Setup SXP Cluster Session
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Resource          ../../../libraries/SxpBindingOriginsLib.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Add/Delete Binding
    [Documentation]    Adding and then deleting binding from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-bindings RPC to the second cluster node (requires datastore access) and delete-bindings RPC to the third cluster node (requires master database).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Bindings    1100    1.1.1.1/32    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    SxpLib.Delete Bindings    1100    1.1.1.1/32    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Domain
    [Documentation]    Adding and then deleting domain from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-domain RPC to the second cluster node (requires datastore access and master database) and delete-domain RPC to the third cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Domain    cluster    node={CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    SxpLib.Delete Domain    cluster    node={CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Update/Delete Binding Origin
    [Documentation]    Binding origin operations need to be executed on cluster owner because they rely on static map which is present solely on cluster owner. To test that binding origin RPCs are redirected to cluster owner first add binding origin to the first node then update it on the second node (requires up-to date binding origin map) and update it on the third node (requires up-to date binding origin map).
    [Tags]    SXP Clustering Redirecting
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0    session=ClusterManagement__session_1
    SxpBindingOriginsLib.Update Binding Origin    CLUSTER    3    session=ClusterManagement__session_2
    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER    session=ClusterManagement__session_3
    [Teardown]    SxpBindingOriginsLib.Revert To Default Binding Origins Configuration    session=${CONTROLLER_SESSION}
