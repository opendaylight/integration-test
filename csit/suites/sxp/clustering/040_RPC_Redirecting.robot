*** Settings ***
Documentation     SXP holds active SXP nodes only on the cluster owner node. Active SXP node holds its master database and datastore access. This implies that all RPC operation logic must be executed only on cluster owner node. In case RPC is send to another cluster node it must be redirected to owner to be properly executed. This suite contains tests for SxpControllerService and SxpConfigControllerService RPCs.
Suite Setup       SxpClusterLib.Setup SXP Cluster Session
Suite Teardown    SxpClusterLib.Clean SXP Cluster Session
Library           ../../../libraries/Common.py
Resource          ../../../libraries/SxpBindingOriginsLib.robot
Resource          ../../../libraries/SxpClusterLib.robot
Resource          ../../../libraries/SxpLib.robot

*** Test Cases ***
Test Add/Delete Node
    [Documentation]    Adding and then deleting SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node and delete-node RPC to the second cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_2

Test Add/Delete Binding
    [Documentation]    Adding and then deleting binding from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-bindings RPC to the second cluster node (requires master database) and delete-bindings RPC to the third cluster node (requires master database).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Bindings    1100    1.1.1.1/32    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    SxpLib.Delete Bindings    1100    1.1.1.1/32    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Domain
    [Documentation]    Adding and then deleting domain from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-domain RPC to the second cluster node (requires datastore access and master database) and delete-domain RPC to the third cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Domain    cluster    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    SxpLib.Delete Domain    cluster    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Connection
    [Documentation]    Adding and then deleting connection from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-node RPC to the first cluster node, add-connection RPC to the second cluster node (requires datastore access) and delete-connection RPC to the third cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Add Connection    version4    listener    ${CLUSTER_NODE_ID}    64999    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    SxpLib.Delete Connections    ${CLUSTER_NODE_ID}    64999    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Domain Filter
    [Documentation]    Adding and then deleting domain filter from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-domain-filter RPC to the first cluster node and delete-domain-filter RPC to the second cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    [Setup]    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}
    ${domain_1_xml} =    Sxp.Add Domains    domain-1
    ${domain_2_xml} =    Sxp.Add Domains    domain-2
    ${domains} =    Common.Combine Strings    ${domain_1_xml}    ${domain_2_xml}
    ${entry} =    Sxp.Get Filter Entry    10    permit    pl=20.0.0.0/8
    ${entries} =    Common.Combine Strings    ${entry}
    SxpLib.Add Domain Filter    domain-filter    ${domains}    ${entries}    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    SxpLib.Delete Domain Filter    domain-filter    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Filter
    [Documentation]    Adding, updating and then deleting filter from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-filter RPC to the first cluster node, update-filter RPC to the second cluster node (requires datastore access) and delete-filter RPC to the third cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    [Setup]    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}
    ${entry1} =    Sxp.Get Filter Entry    10    deny    pl=10.10.20.0/24
    ${entry2} =    Sxp.Get Filter Entry    20    permit    epl=10.10.0.0/16,le,24
    ${entry3} =    Sxp.Get Filter Entry    30    permit    sgt=30    pl=10.10.10.0/24
    ${entries} =    Common.Combine Strings    ${entry1}    ${entry2}    ${entry3}
    SxpLib.Add Filter    GROUP    outbound    ${entries}    node=${CLUSTER_NODE_ID}    policy=manual-update    session=ClusterManagement__session_1
    SxpLib.Update Filter    GROUP    outbound    ${entries}    node=${CLUSTER_NODE_ID}    policy=manual-update    session=ClusterManagement__session_2
    SxpLib.Delete Filter    GROUP    outbound    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Delete Peer Group
    [Documentation]    Adding and then deleting peer group from a SXP node is sucessfull only if all operations are done on cluster owner node. To verify that all RPCs are redirected to cluster owner send add-peer-group RPC to the first cluster node, get-peer-groups RPC to the second cluster node (requires datastore access) and delete-peer-group RPC to the third cluster node (requires datastore access).
    [Tags]    SXP Clustering Redirecting
    [Setup]    SxpLib.Add Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}
    SxpLib.Add PeerGroup    GROUP    peers=${EMPTY}    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_1
    ${resp} =    SxpLib.Get Peer Groups    ${CLUSTER_NODE_ID}    session=ClusterManagement__session_2
    @{groups} =    Sxp.Parse Peer Groups    ${resp}
    : FOR    ${group}    IN    @{groups}
    \    SxpLib.Delete Peer Group    ${group['name']}    node=${CLUSTER_NODE_ID}    session=ClusterManagement__session_3
    [Teardown]    SxpLib.Delete Node    ${CLUSTER_NODE_ID}    session=${CONTROLLER_SESSION}

Test Add/Update/Delete Binding Origin
    [Documentation]    Binding origin operations need to be executed on cluster owner because they rely on static map which is present solely on cluster owner. To test that binding origin RPCs are redirected to cluster owner first add binding origin to the first node then update it on the second node (requires up-to date binding origin map) and update it on the third node (requires up-to date binding origin map).
    [Tags]    SXP Clustering Redirecting
    SxpBindingOriginsLib.Add Binding Origin    CLUSTER    0    session=ClusterManagement__session_1
    SxpBindingOriginsLib.Update Binding Origin    CLUSTER    3    session=ClusterManagement__session_2
    SxpBindingOriginsLib.Delete Binding Origin    CLUSTER    session=ClusterManagement__session_3
    [Teardown]    SxpBindingOriginsLib.Revert To Default Binding Origins Configuration    session=${CONTROLLER_SESSION}
