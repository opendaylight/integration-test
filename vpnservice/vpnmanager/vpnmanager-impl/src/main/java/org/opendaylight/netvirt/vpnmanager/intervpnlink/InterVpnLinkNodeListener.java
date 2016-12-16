/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.ListenableFuture;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.vpnmanager.VpnFootprintService;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLinkBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;

/**
 * Listens for Nodes going down, in order to check if the InterVpnLink must be
 * moved to some other DPN
 *
 */
public class InterVpnLinkNodeListener extends AsyncDataTreeChangeListenerBase<Node, InterVpnLinkNodeListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkNodeListener.class);

    // TODO: Remove when included in ovsdb's SouthboundUtils
    public static final TopologyId FLOW_TOPOLOGY_ID = new TopologyId(new Uri("flow:1"));

    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private final VpnFootprintService vpnFootprintService;


    public InterVpnLinkNodeListener(final DataBroker dataBroker, final IMdsalApiManager mdsalMgr,
                                    final VpnFootprintService vpnFootprintService) {
        super(Node.class, InterVpnLinkNodeListener.class);
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalMgr;
        this.vpnFootprintService = vpnFootprintService;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Node> getWildCardPath(){
        return InstanceIdentifier.create(NetworkTopology.class)
                                 .child(Topology.class, new TopologyKey(FLOW_TOPOLOGY_ID))
                                 .child(Node.class);
    }

    @Override
    protected InterVpnLinkNodeListener getDataTreeChangeListener() {
        return InterVpnLinkNodeListener.this;
    }

    @Override
    protected void add(InstanceIdentifier<Node> identifier, Node add) {
        NodeId nodeId = add.getNodeId();
        String[] node =  nodeId.getValue().split(":");
        if(node.length < 2) {
            LOG.warn("Unexpected nodeId {}", nodeId.getValue());
            return;
        }
        BigInteger dpId = new BigInteger(node[1]);
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        coordinator.enqueueJob("IVpnLink" + dpId.toString(),
                               new InterVpnLinkNodeAddTask(dataBroker, mdsalManager, vpnFootprintService, dpId));
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
        LOG.trace("Node {} has been deleted", identifier.firstKeyOf(Node.class).toString());
        NodeId nodeId = del.getNodeId();
        String[] node =  nodeId.getValue().split(":");
        if(node.length < 2) {
            LOG.warn("Unexpected nodeId {}", nodeId.getValue());
            return;
        }
        BigInteger dpId = new BigInteger(node[1]);
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        coordinator.enqueueJob("IVpnLink" + dpId.toString(), new InterVpnLinkNodeWorker(dataBroker, dpId));

    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
    }

    protected class InterVpnLinkNodeWorker implements Callable<List<ListenableFuture<Void>>> {

        private DataBroker broker;
        private BigInteger dpnId;

        public InterVpnLinkNodeWorker(final DataBroker broker, final BigInteger dpnId) {
            this.broker = broker;
            this.dpnId = dpnId;
        }
        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            List<ListenableFuture<Void>> result = new ArrayList<>();

            List<InterVpnLink> allInterVpnLinks = InterVpnLinkUtil.getAllInterVpnLinks(broker);
            for ( InterVpnLink interVpnLink : allInterVpnLinks ) {
                Optional<InterVpnLinkState> optIVpnLinkState =
                        InterVpnLinkUtil.getInterVpnLinkState(broker, interVpnLink.getName());
                if ( !optIVpnLinkState.isPresent() ) {
                    LOG.warn("Could not find State info for InterVpnLink={}", interVpnLink.getName());
                    continue;
                }

                InterVpnLinkState interVpnLinkState = optIVpnLinkState.get();
                if ( interVpnLinkState.getFirstEndpointState().getDpId().contains(dpnId)
                     || interVpnLinkState.getSecondEndpointState().getDpId().contains(dpnId) ) {
                    // InterVpnLink affected by Node DOWN.
                    // Lets move the InterVpnLink to some other place. Basically, remove it and create it again
                    InstanceIdentifier<InterVpnLink> interVpnLinkIid =
                            InterVpnLinkUtil.getInterVpnLinkPath(interVpnLink.getName());
                    // Remove it
                    MDSALUtil.syncDelete(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinkIid);
                    // Create it again, but first we have to wait for everything to be removed from dataplane
                    Long timeToWait = Long.getLong("wait.time.sync.install", 1500L);
                    try {
                        Thread.sleep(timeToWait);
                    } catch (InterruptedException e) {
                        LOG.warn("Interrupted while waiting for Flows removal sync.", e);
                    }

                    InterVpnLink interVpnLink2 = new InterVpnLinkBuilder(interVpnLink).build();
                    WriteTransaction tx = broker.newWriteOnlyTransaction();
                    tx.put(LogicalDatastoreType.CONFIGURATION, interVpnLinkIid, interVpnLink2, true);
                    CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
                    result.add(futures);
                }
            }

            return result;
        }

    }

}
