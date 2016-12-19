/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.fibmanager;

import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.LinkedBlockingQueue;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.genius.utils.batching.ActionableResource;
import org.opendaylight.genius.utils.batching.ActionableResourceImpl;
import org.opendaylight.genius.utils.batching.ResourceBatchingManager;
import org.opendaylight.genius.utils.batching.ResourceHandler;
import org.opendaylight.genius.utils.batching.SubTransaction;
import org.opendaylight.genius.utils.batching.SubTransactionImpl;
import org.opendaylight.netvirt.fibmanager.NexthopManager.AdjacencyResult;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkDataComposite;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowCapableNode;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.Table;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.TableKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeMplsOverGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetTunnelTypeInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetTunnelTypeOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.LabelRouteMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.RouterInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.SubnetRoute;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.label.route.map.LabelRouteInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.label.route.map.LabelRouteInfoBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.label.route.map.LabelRouteInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.vpnnexthops.VpnNexthop;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.vpnnexthops.VpnNexthopBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.Adjacencies;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnToExtraroute;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.Prefixes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.PrefixesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.Vpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.VpnKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.vpn.Extraroute;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.vpn.ExtrarouteKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState.State;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.overlay.rev150105.TunnelTypeVxlan;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VrfEntryListener extends AsyncDataTreeChangeListenerBase<VrfEntry, VrfEntryListener> implements AutoCloseable, ResourceHandler {
    private static final Logger LOG = LoggerFactory.getLogger(VrfEntryListener.class);
    private static final String FLOWID_PREFIX = "L3.";
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private IVpnManager vpnmanager;
    private final NexthopManager nextHopManager;
    private ItmRpcService itmManager;
    private final OdlInterfaceRpcService interfaceManager;
    private final IdManagerService idManager;
    static final BigInteger COOKIE_VM_FIB_TABLE =  new BigInteger("8000003", 16);
    static final int DEFAULT_FIB_FLOW_PRIORITY = 10;
    private static final int LFIB_INTERVPN_PRIORITY = 1;
    private static final BigInteger METADATA_MASK_CLEAR = new BigInteger("000000FFFFFFFFFF", 16);
    private static final BigInteger CLEAR_METADATA = BigInteger.valueOf(0);
    public static final BigInteger COOKIE_TUNNEL = new BigInteger("9000000", 16);
    List<SubTransaction> transactionObjects;
    private static final int PERIODICITY = 500;
    private static Integer batchSize;
    private static Integer batchInterval;
    private static final int BATCH_SIZE = 1000;
    private static BlockingQueue<ActionableResource> vrfEntryBufferQ = new LinkedBlockingQueue<>();
    private final ResourceBatchingManager resourceBatchingManager;

    public VrfEntryListener(final DataBroker dataBroker, final IMdsalApiManager mdsalApiManager,
                            final NexthopManager nexthopManager, final OdlInterfaceRpcService interfaceManager,
                            final IdManagerService idManager) {
        super(VrfEntry.class, VrfEntryListener.class);
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalApiManager;
        this.nextHopManager = nexthopManager;
        this.interfaceManager = interfaceManager;
        this.idManager = idManager;

        batchSize = Integer.getInteger("batch.size");
        if (batchSize == null) {
            batchSize = BATCH_SIZE;
        }
        batchInterval = Integer.getInteger("batch.wait.time");
        if (batchInterval == null) {
            batchInterval = PERIODICITY;
        }
        resourceBatchingManager = ResourceBatchingManager.getInstance();
        resourceBatchingManager.registerBatchableResource("FIB-VRFENTRY",vrfEntryBufferQ, this);
        transactionObjects = new ArrayList<>();
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected VrfEntryListener getDataTreeChangeListener() { return VrfEntryListener.this; }

    @Override
    protected InstanceIdentifier<VrfEntry> getWildCardPath() {
        return InstanceIdentifier.create(FibEntries.class).child(VrfTables.class).child(VrfEntry.class);
    }

    @Override
    public DataBroker getResourceBroker() {
        return dataBroker;
    }

    public NexthopManager getNextHopManager() {
        return this.nextHopManager;
    }

    @Override
    protected void add(final InstanceIdentifier<VrfEntry> identifier, final VrfEntry vrfEntry) {
        Preconditions.checkNotNull(vrfEntry, "VrfEntry should not be null or empty.");
        String rd = identifier.firstKeyOf(VrfTables.class).getRouteDistinguisher();
        LOG.debug("ADD: Adding Fib Entry rd {} prefix {} nexthop {} label {}",
                rd, vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), vrfEntry.getLabel());
        if (vrfEntry.getEncapType().equals(VrfEntry.EncapType.Vxlan)) {
            LOG.info("EVPN flows need to be programmed.");
            EVPNVrfEntryProcessor EVPNVrfEntryProcessor = new EVPNVrfEntryProcessor(identifier, vrfEntry, dataBroker, this);
            EVPNVrfEntryProcessor.installFlows();
        } else {
            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.BGP) {
                createFibEntries(identifier, vrfEntry);
            } else {
                ActionableResource actResource = new ActionableResourceImpl(rd.toString() + vrfEntry.getDestPrefix());
                actResource.setAction(ActionableResource.CREATE);
                actResource.setInstanceIdentifier(identifier);
                actResource.setInstance(vrfEntry);
                vrfEntryBufferQ.add(actResource);
                leakRouteIfNeeded(identifier, vrfEntry, NwConstants.ADD_FLOW);
            }
        }
        LOG.info("ADD: Added Fib Entry rd {} prefix {} nexthop {} label {}",
                rd, vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), vrfEntry.getLabel());
    }

    @Override
    protected void remove(InstanceIdentifier<VrfEntry> identifier, VrfEntry vrfEntry) {
        Preconditions.checkNotNull(vrfEntry, "VrfEntry should not be null or empty.");
        String rd = identifier.firstKeyOf(VrfTables.class).getRouteDistinguisher();
        LOG.debug("REMOVE: Removing Fib Entry rd {} prefix {} nexthop {} label {}",
                rd, vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), vrfEntry.getLabel());
        if (vrfEntry.getEncapType().equals(VrfEntry.EncapType.Vxlan)) {
            LOG.info("EVPN flows to be deleted");
            EVPNVrfEntryProcessor EVPNVrfEntryProcessor = new EVPNVrfEntryProcessor(identifier, vrfEntry, dataBroker, this);
            EVPNVrfEntryProcessor.removeFlows();
        } else {
            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.BGP) {
                deleteFibEntries(identifier, vrfEntry);
            } else {
                ActionableResource actResource = new ActionableResourceImpl(rd.toString() + vrfEntry.getDestPrefix());
                actResource.setAction(ActionableResource.DELETE);
                actResource.setInstanceIdentifier(identifier);
                actResource.setInstance(vrfEntry);
                vrfEntryBufferQ.add(actResource);
                leakRouteIfNeeded(identifier, vrfEntry, NwConstants.DEL_FLOW);
            }
        }
        LOG.info("REMOVE: Removed Fib Entry rd {} prefix {} nexthop {} label {}",
                rd, vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), vrfEntry.getLabel());
    }

    @Override
    protected void update(InstanceIdentifier<VrfEntry> identifier, VrfEntry original, VrfEntry update) {
        Preconditions.checkNotNull(update, "VrfEntry should not be null or empty.");

        final String rd = identifier.firstKeyOf(VrfTables.class).getRouteDistinguisher();
        final VrfTablesKey vrfTableKey = identifier.firstKeyOf(VrfTables.class);
        LOG.debug("UPDATE: Updating Fib Entries to rd {} prefix {} nexthop {} label {}",
                rd, update.getDestPrefix(), update.getNextHopAddressList(), update.getLabel());
        // Handle BGP Routes first
        if (RouteOrigin.value(update.getOrigin()) == RouteOrigin.BGP) {
            ActionableResource actResource = new ActionableResourceImpl(rd.toString() + update.getDestPrefix());
            actResource.setAction(ActionableResource.UPDATE);
            actResource.setInstanceIdentifier(identifier);
            actResource.setInstance(update);
            actResource.setOldInstance(original);
            vrfEntryBufferQ.add(actResource);
            LOG.info("UPDATE: Updated Fib Entries to rd {} prefix {} nexthop {} label {}",
                    rd, update.getDestPrefix(), update.getNextHopAddressList(), update.getLabel());
            return;
        }

        // Handle Internal Routes next (ie., STATIC only)
          if (FibUtil.isControllerManagedNonInterVpnLinkRoute(RouteOrigin.value(update.getOrigin()))) {
            SubnetRoute subnetRoute = update.getAugmentation(SubnetRoute.class);
            /* Ignore SubnetRoute entry, as it will be driven by createFibEntries call down below */
            if (subnetRoute == null) {
                List<String> origNhList = original.getNextHopAddressList();
                List<String> updateNhList = update.getNextHopAddressList();
                //final SubnetRoute subnetRoute = update.getAugmentation(SubnetRoute.class);
                LOG.info("UPDATE: Original nexthop {} updateNextHop {} ", origNhList, updateNhList);

                // If original VRF Entry had nexthop null , but update VRF Entry
                // has nexthop , route needs to be created on remote Dpns
                if (((origNhList == null) || (origNhList.isEmpty()) &&
                        (updateNhList != null) && (!updateNhList.isEmpty()))) {
                    // TODO(vivek): Though ugly, Not handling this code now, as each
                    // tep add event will invoke flow addition
                    LOG.trace("Original VRF entry NH is null for destprefix {}. This event is IGNORED here.", update.getDestPrefix());
                    return;
                }

                // If original VRF Entry had valid nexthop , but update VRF Entry
                // has nexthop empty'ed out, route needs to be removed from remote Dpns
                if (((updateNhList == null) || (updateNhList.isEmpty()) &&
                        (origNhList != null) && (!origNhList.isEmpty()))) {
                    LOG.trace("Original VRF entry had valid NH for destprefix {}. This event is IGNORED here.", update.getDestPrefix());
                    return;
                }
            }
            createFibEntries(identifier, update);
            LOG.info("UPDATE: Updated Fib Entries to rd {} prefix {} nexthop {} label {}",
                    rd, update.getDestPrefix(), update.getNextHopAddressList(), update.getLabel());
            return;
        }

        /* Handl all other route origins */
        createFibEntries(identifier, update);

        LOG.info("UPDATE: Updated Fib Entries to rd {} prefix {} nexthop {} label {}",
                rd, update.getDestPrefix(), update.getNextHopAddressList(), update.getLabel());
    }

    @Override
    public void create(WriteTransaction tx, LogicalDatastoreType datastoreType, InstanceIdentifier identifier, Object vrfEntry, List<SubTransaction> transactionObjects) {
        this.transactionObjects = transactionObjects;
        if (vrfEntry instanceof VrfEntry) {
            createFibEntries(tx, identifier, (VrfEntry)vrfEntry);
        }
    }

    @Override
    public void delete(WriteTransaction tx, LogicalDatastoreType datastoreType, InstanceIdentifier identifier, Object vrfEntry, List<SubTransaction> transactionObjects) {
        this.transactionObjects = transactionObjects;
        if (vrfEntry instanceof VrfEntry) {
            deleteFibEntries(tx, identifier, (VrfEntry) vrfEntry);
        }
    }

    @Override
    public void update(WriteTransaction tx, LogicalDatastoreType datastoreType, InstanceIdentifier identifier, Object original,
                       Object update, List<SubTransaction> transactionObjects) {
        this.transactionObjects = transactionObjects;
        if ((original instanceof VrfEntry) && (update instanceof VrfEntry)) {
            createFibEntries(tx, identifier, (VrfEntry)update);
        }
    }

    @Override
    public int getBatchSize() {
        return batchSize;
    }

    @Override
    public int getBatchInterval() {
        return batchInterval;
    }

    @Override
    public LogicalDatastoreType getDatastoreType() {
        return LogicalDatastoreType.CONFIGURATION;
    }

    private void createFibEntries(final InstanceIdentifier<VrfEntry> vrfEntryIid, final VrfEntry vrfEntry) {
        final VrfTablesKey vrfTableKey = vrfEntryIid.firstKeyOf(VrfTables.class);

        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(vrfTableKey.getRouteDistinguisher());
        Preconditions.checkNotNull(vpnInstance, "Vpn Instance not available " + vrfTableKey.getRouteDistinguisher());
        Preconditions.checkNotNull(vpnInstance.getVpnId(), "Vpn Instance with rd " + vpnInstance.getVrfId() + " has null vpnId!");

        final Collection<VpnToDpnList> vpnToDpnList = vpnInstance.getVpnToDpnList();
        final Long vpnId = vpnInstance.getVpnId();
        final String rd = vrfTableKey.getRouteDistinguisher();
        SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
        if (subnetRoute != null) {
            final long elanTag = subnetRoute.getElantag();
            LOG.trace("SubnetRoute augmented vrfentry found for rd {} prefix {} with elantag {}",
                    rd, vrfEntry.getDestPrefix(), elanTag);
            if (vpnToDpnList != null) {
                DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                dataStoreCoordinator.enqueueJob("FIB-"+ rd.toString() + "-" + vrfEntry.getDestPrefix(),
                        new Callable<List<ListenableFuture<Void>>>() {
                            @Override
                            public List<ListenableFuture<Void>> call() throws Exception {
                                WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                                for (final VpnToDpnList curDpn : vpnToDpnList) {
                                    if (curDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                                        installSubnetRouteInFib(curDpn.getDpnId(), elanTag, rd, vpnId.longValue(), vrfEntry, tx);
                                    }
                                }
                                List<ListenableFuture<Void>> futures = new ArrayList<>();
                                futures.add(tx.submit());
                                return futures;
                            }
                        });
            }
            return;
        }
        // ping responder for router interfaces
        if (installRouterFibEntries(vrfEntry, vpnToDpnList, vpnId, NwConstants.ADD_FLOW)) {
            return;
        }

        final List<BigInteger> localDpnIdList = createLocalFibEntry(vpnInstance.getVpnId(), rd, vrfEntry);

        if (vpnToDpnList != null) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-"+ rd.toString() + "-" + vrfEntry.getDestPrefix(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                            for (VpnToDpnList vpnDpn : vpnToDpnList) {
                                if ( !localDpnIdList.contains(vpnDpn.getDpnId())) {
                                    if (vpnDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                                        createRemoteFibEntry(vpnDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, tx);
                                    }
                                }
                            }
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            futures.add(tx.submit());
                            return futures;
                        }
                    });
        }

        Optional<String> optVpnUuid = FibUtil.getVpnNameFromRd(dataBroker, rd);
        if ( optVpnUuid.isPresent() ) {
            Optional<InterVpnLinkDataComposite> optInterVpnLink = InterVpnLinkCache.getInterVpnLinkByVpnId(optVpnUuid.get());
            LOG.debug("InterVpnLink {} found in Cache: {}", optVpnUuid.get(), optInterVpnLink.isPresent());
            if ( optInterVpnLink.isPresent() ) {
                InterVpnLinkDataComposite interVpnLink = optInterVpnLink.get();
                String vpnUuid = optVpnUuid.get();
                String routeNexthop = vrfEntry.getNextHopAddressList().get(0);
                if ( interVpnLink.isIpAddrTheOtherVpnEndpoint(routeNexthop, vpnUuid) ) {
                    // This is an static route that points to the other endpoint of an InterVpnLink
                    // In that case, we should add another entry in FIB table pointing to LPortDispatcher table.
                    installIVpnLinkSwitchingFlows(interVpnLink, vpnUuid, vrfEntry, vpnId);
                    installInterVpnRouteInLFib(rd, vrfEntry);
                }
            }
        }
    }


    /*
      Please note that the following createFibEntries will be invoked only for BGP Imported Routes.
      The invocation of the following method is via create() callback from the MDSAL Batching Infrastructure
      provided by ResourceBatchingManager
     */
    private void createFibEntries(WriteTransaction writeTx, final InstanceIdentifier<VrfEntry> vrfEntryIid, final VrfEntry vrfEntry) {
        final VrfTablesKey vrfTableKey = vrfEntryIid.firstKeyOf(VrfTables.class);

        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(vrfTableKey.getRouteDistinguisher());
        Preconditions.checkNotNull(vpnInstance, "Vpn Instance not available " + vrfTableKey.getRouteDistinguisher());
        Preconditions.checkNotNull(vpnInstance.getVpnId(), "Vpn Instance with rd " + vpnInstance.getVrfId() + " has null vpnId!");

        final Collection<VpnToDpnList> vpnToDpnList = vpnInstance.getVpnToDpnList();
        final String rd = vrfTableKey.getRouteDistinguisher();
        if (vpnToDpnList != null) {
            for (VpnToDpnList vpnDpn : vpnToDpnList) {
                if (vpnDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                    createRemoteFibEntry(vpnDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, writeTx);
                }
            }
        }
    }

    // FIXME: Refactoring needed here.
    //        This kind of logic must be taken to an 'upper' layer like BgpManager or VpnManager
    private void leakRouteIfNeeded(final InstanceIdentifier<VrfEntry> vrfEntryIid, final VrfEntry vrfEntry,
                                   int addOrRemove) {
        Preconditions.checkNotNull(vrfEntry, "VrfEntry cannot be null or empty!");
        final VrfTablesKey vrfTableKey = vrfEntryIid.firstKeyOf(VrfTables.class);

        String rd = vrfTableKey.getRouteDistinguisher();
        VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
            if (vpnInstance == null) {
                LOG.error("Vpn Instance not available for external route with prefix {} label {} nexthop {}. Returning...", vrfEntry.getDestPrefix(), vrfEntry.getLabel(), vrfEntry.getNextHopAddressList());
                return;
            }
        } else {
            Preconditions.checkNotNull(vpnInstance,
                                       "Vpn Instance not available with rd " + vrfTableKey.getRouteDistinguisher());
        }
        String vpnUuid = vpnInstance.getVpnInstanceName();
        Preconditions.checkArgument(vpnUuid != null && !vpnUuid.isEmpty(),
                "Could not find suitable VPN UUID for Route-Distinguisher=" + rd);

        // if the new vrfEntry has been learned by Quagga BGP, its necessary to check if it's
        // there an interVpnLink for the involved vpn in order to make learn the new route to
        // the other part of the inter-vpn-link.

        // For leaking, we need the InterVpnLink to be active. For removal, we just need a InterVpnLink.
        Optional<InterVpnLink> interVpnLink =
            (addOrRemove == NwConstants.ADD_FLOW) ? FibUtil.getActiveInterVpnLinkFromRd(dataBroker, rd)
                                                  : FibUtil.getInterVpnLinkByRd(dataBroker, rd);
        if ( !interVpnLink.isPresent() ) {
            LOG.debug("Could not find an InterVpnLink for Route-Distinguisher={}", rd);
            return;
        }

        // Ok, at this point everything is ready for the leaking/removal... but should it be performed?
        // For removal, we remove all leaked routes, but we only leak a route if the corresponding flag is enabled.
        boolean proceed =
            (addOrRemove == NwConstants.DEL_FLOW) || ( RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP
                                                       && interVpnLink.get().isBgpRoutesLeaking() );

        if ( proceed ) {
            boolean isVpnFirstEndpoint = interVpnLink.get().getFirstEndpoint().getVpnUuid().getValue().equals(vpnUuid);

            String theOtherVpnId = isVpnFirstEndpoint ? interVpnLink.get().getSecondEndpoint().getVpnUuid().getValue()
                                                      : vpnUuid;
            String dstVpnRd = FibUtil.getVpnRd(dataBroker, theOtherVpnId);
            String endpointIp = isVpnFirstEndpoint ? interVpnLink.get().getFirstEndpoint().getIpAddress().toString()
                                                   : interVpnLink.get().getSecondEndpoint().getIpAddress().toString();

            InstanceIdentifier<VrfEntry> vrfEntryIidInOtherVpn =
                    InstanceIdentifier.builder(FibEntries.class)
                            .child(VrfTables.class, new VrfTablesKey(dstVpnRd))
                            .child(VrfEntry.class, new VrfEntryKey(vrfEntry.getDestPrefix()))
                            .build();
            if ( addOrRemove == NwConstants.ADD_FLOW ) {
                LOG.debug("Leaking route (destination={}, nexthop={}) from Vrf={} to Vrf={}",
                        vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), rd, dstVpnRd);
                String key = rd + FibConstants.SEPARATOR + vrfEntry.getDestPrefix();
                long label = FibUtil.getUniqueId(idManager, FibConstants.VPN_IDPOOL_NAME, key);
                VrfEntry newVrfEntry = new VrfEntryBuilder(vrfEntry).setNextHopAddressList(Arrays.asList(endpointIp))
                        .setLabel(label)
                        .setOrigin(RouteOrigin.INTERVPN.getValue())
                        .build();
                MDSALUtil.syncUpdate(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfEntryIidInOtherVpn, newVrfEntry);
            } else {
                LOG.debug("Removing leaked vrfEntry={}", vrfEntryIidInOtherVpn.toString());
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfEntryIidInOtherVpn);
            }
        }
    }

    private Prefixes updateVpnReferencesInLri(LabelRouteInfo lri, String vpnInstanceName, boolean isPresentInList) {
        LOG.debug("updating LRI : for label {} vpninstancename {}", lri.getLabel(), vpnInstanceName);
        PrefixesBuilder prefixBuilder = new PrefixesBuilder();
        prefixBuilder.setDpnId(lri.getDpnId());
        prefixBuilder.setVpnInterfaceName(lri.getVpnInterfaceName());
        prefixBuilder.setIpAddress(lri.getPrefix());
        // Increment the refCount here
        InstanceIdentifier<LabelRouteInfo> lriId = InstanceIdentifier.builder(LabelRouteMap.class)
                .child(LabelRouteInfo.class, new LabelRouteInfoKey((long)lri.getLabel())).build();
        LabelRouteInfoBuilder builder = new LabelRouteInfoBuilder(lri);
        if (!isPresentInList) {
            LOG.debug("vpnName {} is not present in LRI with label {}..", vpnInstanceName, lri.getLabel());
            List<String> vpnInstanceNames = lri.getVpnInstanceList();
            vpnInstanceNames.add(vpnInstanceName);
            builder.setVpnInstanceList(vpnInstanceNames);
            FibUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, lriId, builder.build(), FibUtil.DEFAULT_CALLBACK);
        } else {
            LOG.debug("vpnName {} is present in LRI with label {}..", vpnInstanceName, lri.getLabel());
        }
        return prefixBuilder.build();
    }

    private void installSubnetRouteInFib(final BigInteger dpnId, final long elanTag, final String rd,
                                         final long vpnId, final VrfEntry vrfEntry, WriteTransaction tx){
        Boolean wrTxPresent = true;
        if (tx == null) {
            wrTxPresent = false;
            tx = dataBroker.newWriteOnlyTransaction();
        }
        synchronized (vrfEntry.getLabel().toString().intern()) {
            LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
            if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) &&
                    vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {

                if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.SELF_IMPORTED) {
                    Optional<VpnInstanceOpDataEntry> vpnInstanceOpDataEntryOptional = FibUtil.getVpnInstanceOpData(dataBroker, rd);
                    if (vpnInstanceOpDataEntryOptional.isPresent()) {
                        String vpnInstanceName = vpnInstanceOpDataEntryOptional.get().getVpnInstanceName();
                        if (!lri.getVpnInstanceList().contains(vpnInstanceName)) {
                            updateVpnReferencesInLri(lri, vpnInstanceName, false);
                        }
                    }
                }
                LOG.debug("Fetched labelRouteInfo for label {} interface {} and got dpn {}",
                        vrfEntry.getLabel(), lri.getVpnInterfaceName(), lri.getDpnId());
            }
        }
        final List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        BigInteger subnetRouteMeta =  ((BigInteger.valueOf(elanTag)).shiftLeft(32)).or((BigInteger.valueOf(vpnId).shiftLeft(1)));
        instructions.add(new InstructionInfo(InstructionType.write_metadata,  new BigInteger[] { subnetRouteMeta, MetaDataUtil.METADATA_MASK_SUBNET_ROUTE }));
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.L3_SUBNET_ROUTE_TABLE }));
        makeConnectedRoute(dpnId,vpnId,vrfEntry,rd,instructions,NwConstants.ADD_FLOW, tx);

        if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.SELF_IMPORTED) {
            List<ActionInfo> actionsInfos = new ArrayList<ActionInfo>();
            // reinitialize instructions list for LFIB Table
            final List<InstructionInfo> LFIBinstructions = new ArrayList<InstructionInfo>();

            actionsInfos.add(new ActionInfo(ActionType.pop_mpls, new String[]{}));
            LFIBinstructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
            LFIBinstructions.add(new InstructionInfo(InstructionType.write_metadata,  new BigInteger[] { subnetRouteMeta, MetaDataUtil.METADATA_MASK_SUBNET_ROUTE }));
            LFIBinstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.L3_SUBNET_ROUTE_TABLE }));

            makeLFibTableEntry(dpnId,vrfEntry.getLabel(), LFIBinstructions, DEFAULT_FIB_FLOW_PRIORITY, NwConstants.ADD_FLOW, tx);
        }
        if (!wrTxPresent ) {
            tx.submit();
        }
    }

    /*
     * For a given route, it installs a flow in LFIB that sets the lportTag of the other endpoint and sends to
     * LportDispatcher table (via table 80)
     */
    private void installInterVpnRouteInLFib(final String rd, final VrfEntry vrfEntry) {
        // INTERVPN routes are routes in a Vpn1 that have been leaked to Vpn2. In DC-GW, this Vpn2 route is pointing
        // to a list of DPNs where Vpn2's VpnLink was instantiated. In these DPNs LFIB must be programmed so that the
        // packet is commuted from Vpn2 to Vpn1.
        Optional<String> vpnNameOpc = FibUtil.getVpnNameFromRd(dataBroker, rd);
        if ( !vpnNameOpc.isPresent() ) {
            LOG.warn("Could not find VpnInstanceName for Route-Distinguisher {}", rd);
            return;
        }

        String vpnName = vpnNameOpc.get();
        List<InterVpnLink> interVpnLinks = FibUtil.getAllInterVpnLinks(dataBroker);
        boolean interVpnLinkFound = false;
        for ( InterVpnLink interVpnLink : interVpnLinks ) {
            boolean vpnIs1stEndpoint = interVpnLink.getFirstEndpoint().getVpnUuid().getValue().equals(vpnName);
            boolean vpnIs2ndEndpoint = !vpnIs1stEndpoint
                    && interVpnLink.getSecondEndpoint().getVpnUuid().getValue().equals(vpnName);
            if ( vpnIs1stEndpoint || vpnIs2ndEndpoint ) {
                interVpnLinkFound = true;

                Optional<InterVpnLinkState> vpnLinkState = FibUtil.getInterVpnLinkState(dataBroker, interVpnLink.getName());
                if ( !vpnLinkState.isPresent()
                        || !vpnLinkState.get().getState().equals(InterVpnLinkState.State.Active) ) {
                    LOG.warn("InterVpnLink {}, linking VPN {} and {}, is not in Active state",
                            interVpnLink.getName(), interVpnLink.getFirstEndpoint().getVpnUuid().getValue(),
                            interVpnLink.getSecondEndpoint().getVpnUuid().getValue() );
                    return;
                }

                List<BigInteger> targetDpns = vpnIs1stEndpoint ? vpnLinkState.get().getFirstEndpointState().getDpId()
                                                               : vpnLinkState.get().getSecondEndpointState().getDpId();
                Long lportTag = vpnIs1stEndpoint ? vpnLinkState.get().getSecondEndpointState().getLportTag()
                                                 : vpnLinkState.get().getFirstEndpointState().getLportTag();

                LOG.trace("Installing flow in LFIB table for interVpnLink {}", interVpnLink.getName());

                for ( BigInteger dpId : targetDpns ) {
                    List<ActionInfo> actionsInfos = Arrays.asList(new ActionInfo(ActionType.pop_mpls, new String[]{}));

                    BigInteger[] metadata = new BigInteger[] {
                            MetaDataUtil.getMetaDataForLPortDispatcher(lportTag.intValue(), ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME, NwConstants.L3VPN_SERVICE_INDEX)),
                            MetaDataUtil.getMetaDataMaskForLPortDispatcher()
                    };
                    List<InstructionInfo> instructions =
                            Arrays.asList(new InstructionInfo(InstructionType.apply_actions, actionsInfos),
                                    new InstructionInfo(InstructionType.write_metadata, metadata),
                                    new InstructionInfo(InstructionType.goto_table,
                                            new long[] { NwConstants.L3_INTERFACE_TABLE }));

                    LOG.debug("Installing flow: VrfEntry=[prefix={} label={} nexthop={}] dpn {} for InterVpnLink {} in LFIB",
                              vrfEntry.getDestPrefix(), vrfEntry.getLabel(), vrfEntry.getNextHopAddressList(),
                              dpId, interVpnLink.getName());

                    makeLFibTableEntry(dpId, vrfEntry.getLabel(), instructions, LFIB_INTERVPN_PRIORITY,
                            NwConstants.ADD_FLOW, null);
                }

                break;
            }
        }

        if ( !interVpnLinkFound ) {
            LOG.warn("VrfEntry=[prefix={} label={} nexthop={}] for VPN {} has origin INTERVPN but no InterVpnLink could be found",
                    vrfEntry.getDestPrefix(), vrfEntry.getLabel(), vrfEntry.getNextHopAddressList(), rd);
        }
    }


    /*
     * Installs the flows in FIB table that, for a given route, do the switching from one VPN to the other.
     */
    private void installIVpnLinkSwitchingFlows(final InterVpnLinkDataComposite interVpnLink, final String vpnUuid,
                                               final VrfEntry vrfEntry, long vpnTag) {
        Preconditions.checkNotNull(interVpnLink, "InterVpnLink cannot be null");
        Preconditions.checkArgument(vrfEntry.getNextHopAddressList() != null
                && vrfEntry.getNextHopAddressList().size() == 1);
        String destination = vrfEntry.getDestPrefix();
        String nextHop = vrfEntry.getNextHopAddressList().get(0);
        String iVpnLinkName = interVpnLink.getInterVpnLinkName();

        // After having received a static route, we should check if the vpn is part of an inter-vpn-link.
        // In that case, we should populate the FIB table of the VPN pointing to LPortDisptacher table
        // using as metadata the LPortTag associated to that vpn in the inter-vpn-link.
        if ( interVpnLink.getState().or(State.Error) != State.Active ) {
            LOG.warn("Route to {} with nexthop={} cannot be installed because the interVpnLink {} is not active",
                    destination, nextHop, iVpnLinkName);
            return;
        }

        Optional<Long> optOtherEndpointLportTag = interVpnLink.getOtherEndpointLportTagByVpnName(vpnUuid);
        if ( !optOtherEndpointLportTag.isPresent() ) {
            LOG.warn("Could not find suitable LportTag for the endpoint opposite to vpn {} in interVpnLink {}",
                     vpnUuid, iVpnLinkName);
            return;
        }

        List<BigInteger> targetDpns = interVpnLink.getEndpointDpnsByVpnName(vpnUuid);
        if ( targetDpns.isEmpty() ) {
            LOG.warn("Could not find DPNs for endpoint opposite to vpn {} in interVpnLink {}", vpnUuid, iVpnLinkName);
            return;
        }

        BigInteger[] metadata = new BigInteger[] {
                MetaDataUtil.getMetaDataForLPortDispatcher(optOtherEndpointLportTag.get().intValue(),
                        ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME, NwConstants.L3VPN_SERVICE_INDEX)),
                MetaDataUtil.getMetaDataMaskForLPortDispatcher()
        };
        List<Instruction> instructions =
                Arrays.asList(new InstructionInfo(InstructionType.write_metadata, metadata).buildInstruction(0),
                              new InstructionInfo(InstructionType.goto_table,
                                                  new long[] { NwConstants.L3_INTERFACE_TABLE }).buildInstruction(1));

        String values[] = destination.split("/");
        String destPrefixIpAddress = values[0];
        int prefixLength = (values.length == 1) ? 0 : Integer.parseInt(values[1]);

        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] { MetaDataUtil.getVpnIdMetadata(vpnTag),
                                                                              MetaDataUtil.METADATA_MASK_VRFID }));
        matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] { NwConstants.ETHTYPE_IPV4 }));

        if (prefixLength != 0) {
            matches.add(new MatchInfo(MatchFieldType.ipv4_destination,
                                      new String[] { destPrefixIpAddress, Integer.toString(prefixLength) }));
        }

        int priority = DEFAULT_FIB_FLOW_PRIORITY + prefixLength;
        String flowRef = getInterVpnFibFlowRef(iVpnLinkName, destination, nextHop);
        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.L3_FIB_TABLE, flowRef, priority, flowRef, 0, 0,
                                                 COOKIE_VM_FIB_TABLE, matches, instructions);

        LOG.trace("Installing flow in FIB table for vpn {} interVpnLink {} nextHop {} key {}" ,
                  vpnUuid, interVpnLink.getInterVpnLinkName(), nextHop, flowRef);

        for ( BigInteger dpId : targetDpns ) {

            LOG.debug("Installing flow: VrfEntry=[prefix={} label={} nextHop={}] dpn {} for InterVpnLink {} in FIB",
                     vrfEntry.getDestPrefix(), vrfEntry.getLabel(), vrfEntry.getNextHopAddressList(),
                     dpId, interVpnLink.getInterVpnLinkName());

            mdsalManager.installFlow(dpId, flowEntity);
        }
    }


    private  <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }

    private List<BigInteger> getDpnIdForPrefix(DataBroker broker, Long vpnId, String rd, VrfEntry vrfEntry) {
        List<BigInteger> returnLocalDpnId = new ArrayList<BigInteger>();
        Prefixes localNextHopInfo = FibUtil.getPrefixToInterface(broker, vpnId, vrfEntry.getDestPrefix());

        if (localNextHopInfo == null) {
            //Is this fib route an extra route? If yes, get the nexthop which would be an adjacency in the vpn
            Extraroute extraRoute = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());
            if (extraRoute != null) {
                for (String nextHopIp : extraRoute.getNexthopIpList()) {
                    LOG.debug("NextHop IP for destination {} is {}", vrfEntry.getDestPrefix(), nextHopIp);
                    if (nextHopIp != null) {
                        localNextHopInfo = FibUtil.getPrefixToInterface(broker, vpnId, nextHopIp + "/32");
                        if (localNextHopInfo != null) {
                            returnLocalDpnId.add(localNextHopInfo.getDpnId());
                        }
                    }
                }
            }
        } else {
            returnLocalDpnId.add(localNextHopInfo.getDpnId());
        }

        return returnLocalDpnId;
    }

    private List<BigInteger> createLocalFibEntry(Long vpnId, String rd, VrfEntry vrfEntry) {
        List<BigInteger> returnLocalDpnId = new ArrayList<>();
        Prefixes localNextHopInfo = FibUtil.getPrefixToInterface(dataBroker, vpnId, vrfEntry.getDestPrefix());
        String localNextHopIP = vrfEntry.getDestPrefix();

        if (localNextHopInfo == null) {
            //Is this fib route an extra route? If yes, get the nexthop which would be an adjacency in the vpn
            Extraroute extraRoute = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());
            if (extraRoute != null) {
                for (String nextHopIp : extraRoute.getNexthopIpList()) {
                    LOG.debug("NextHop IP for destination {} is {}", vrfEntry.getDestPrefix(), nextHopIp);
                    if (nextHopIp != null) {
                        localNextHopInfo = FibUtil.getPrefixToInterface(dataBroker, vpnId, nextHopIp + "/32");
                        localNextHopIP = nextHopIp + "/32";
                        BigInteger dpnId = checkCreateLocalFibEntry(localNextHopInfo, localNextHopIP, vpnId, rd, vrfEntry, vpnId);
                        returnLocalDpnId.add(dpnId);
                    }
                }
            }
            if (localNextHopInfo == null) {
            /* imported routes case */
                synchronized (vrfEntry.getLabel().toString().intern()) {
                    LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                    if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) &&
                            vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.SELF_IMPORTED) {
                            Optional<VpnInstanceOpDataEntry> vpnInstanceOpDataEntryOptional = FibUtil.getVpnInstanceOpData(dataBroker, rd);
                            if (vpnInstanceOpDataEntryOptional.isPresent()) {
                                String vpnInstanceName = vpnInstanceOpDataEntryOptional.get().getVpnInstanceName();
                                if (lri.getVpnInstanceList().contains(vpnInstanceName)) {
                                    localNextHopInfo = updateVpnReferencesInLri(lri, vpnInstanceName, true);
                                    localNextHopIP = lri.getPrefix();
                                } else {
                                    localNextHopInfo = updateVpnReferencesInLri(lri, vpnInstanceName, false);
                                    localNextHopIP = lri.getPrefix();
                                }
                            }
                            if (localNextHopInfo != null) {
                                LOG.debug("Fetched labelRouteInfo for label {} interface {} and got dpn {}",
                                        vrfEntry.getLabel(), localNextHopInfo.getVpnInterfaceName(), lri.getDpnId());
                                BigInteger dpnId = checkCreateLocalFibEntry(localNextHopInfo, localNextHopIP, vpnId, rd, vrfEntry, lri.getParentVpnid());
                                returnLocalDpnId.add(dpnId);
                            }
                        }
                    }
                }
            }
        } else {
            BigInteger dpnId = checkCreateLocalFibEntry(localNextHopInfo, localNextHopIP, vpnId, rd, vrfEntry, vpnId);
            returnLocalDpnId.add(dpnId);
        }

        return returnLocalDpnId;
    }

    private BigInteger checkCreateLocalFibEntry(Prefixes localNextHopInfo, String localNextHopIP, final Long vpnId, final String rd,
                                                final VrfEntry vrfEntry, Long parentVpnId){
        if (localNextHopInfo != null) {
            final BigInteger dpnId = localNextHopInfo.getDpnId();
            if (!isVpnPresentInDpn(rd, dpnId)) {
                LOG.error("The vpnName with vpnId {} rd {} is not available on dpn {}", vpnId, rd, dpnId.toString());
                return BigInteger.ZERO;
            }

            final long groupId = nextHopManager.createLocalNextHop(parentVpnId, dpnId,
                    localNextHopInfo.getVpnInterfaceName(), localNextHopIP, vrfEntry.getDestPrefix());
            if (groupId == 0) {
                LOG.error("Unable to create Group for local prefix {} on rd {} for vpninterface {} on Node {}",
                        vrfEntry.getDestPrefix(), rd, localNextHopInfo.getVpnInterfaceName(), dpnId.toString());
                return BigInteger.ZERO;
            }
            List<ActionInfo> actionsInfos =
                    Arrays.asList(new ActionInfo(ActionType.group, new String[] { String.valueOf(groupId)}));
            final List<InstructionInfo> instructions =
                    Arrays.asList(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
            actionsInfos = Arrays.asList(new ActionInfo(ActionType.pop_mpls, new String[]{}),
                    new ActionInfo(ActionType.group, new String[] { String.valueOf(groupId) }) );
            final List<InstructionInfo> lfibinstructions = Arrays.asList(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.SELF_IMPORTED) {
                LOG.debug("Installing tunnel table entry on dpn {} for interface {} with label {}",
                        dpnId, localNextHopInfo.getVpnInterfaceName(), vrfEntry.getLabel());
            } else {
                LOG.debug("Route with rd {} prefix {} label {} nexthop {} for vpn {} is an imported route. LFib and Terminating table entries will not be created.", rd, vrfEntry.getDestPrefix(), vrfEntry.getLabel(), vrfEntry.getNextHopAddressList(), vpnId);
            }
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-"+ vpnId.toString() + "-" + dpnId.toString() + "-" + vrfEntry.getDestPrefix(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                            makeConnectedRoute(dpnId, vpnId, vrfEntry, rd, instructions, NwConstants.ADD_FLOW, tx);
                            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.SELF_IMPORTED) {
                                makeLFibTableEntry(dpnId, vrfEntry.getLabel(), lfibinstructions , DEFAULT_FIB_FLOW_PRIORITY, NwConstants.ADD_FLOW, tx);
                                makeTunnelTableEntry(dpnId, vrfEntry.getLabel(), groupId, tx);
                            }
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            futures.add(tx.submit());
                            return futures;
                        }
                    });
            return dpnId;
        }
        return BigInteger.ZERO;
    }

    private boolean isVpnPresentInDpn(String rd, BigInteger dpnId)  {
        InstanceIdentifier<VpnToDpnList> id = FibUtil.getVpnToDpnListIdentifier(rd, dpnId);
        Optional<VpnToDpnList> dpnInVpn = FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if (dpnInVpn.isPresent()) {
            return true;
        }
        return false;
    }

    private LabelRouteInfo getLabelRouteInfo(Long label) {
        InstanceIdentifier<LabelRouteInfo>lriIid = InstanceIdentifier.builder(LabelRouteMap.class)
                .child(LabelRouteInfo.class, new LabelRouteInfoKey((long)label)).build();
        Optional<LabelRouteInfo> opResult = read(dataBroker, LogicalDatastoreType.OPERATIONAL, lriIid);
        if (opResult.isPresent()) {
            return opResult.get();
        }
        return null;
    }

    private boolean deleteLabelRouteInfo(LabelRouteInfo lri, String vpnInstanceName) {
        LOG.debug("deleting LRI : for label {} vpninstancename {}", lri.getLabel(), vpnInstanceName);
        InstanceIdentifier<LabelRouteInfo> lriId = InstanceIdentifier.builder(LabelRouteMap.class)
                .child(LabelRouteInfo.class, new LabelRouteInfoKey((long) lri.getLabel())).build();
        if (lri == null) {
            return true;
        }
        List<String> vpnInstancesList = lri.getVpnInstanceList() != null ? lri.getVpnInstanceList() : new ArrayList<String>();
        if (vpnInstancesList.contains(vpnInstanceName)) {
            LOG.debug("vpninstance {} name is present", vpnInstanceName);
            vpnInstancesList.remove(vpnInstanceName);
        }
        if (vpnInstancesList.size() == 0) {
            LOG.debug("deleting LRI instance object for label {}", lri.getLabel());
            FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL, lriId);
            return true;
        } else {
            LOG.debug("updating LRI instance object for label {}", lri.getLabel());
            LabelRouteInfoBuilder builder = new LabelRouteInfoBuilder(lri).setVpnInstanceList(vpnInstancesList);
            FibUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, lriId, builder.build(), FibUtil.DEFAULT_CALLBACK);
        }
        return false;
    }

    void makeTunnelTableEntry(BigInteger dpId, long label, long groupId/*String egressInterfaceName*/,
                                      WriteTransaction tx) {
        List<ActionInfo> actionsInfos = new ArrayList<ActionInfo>();
        actionsInfos.add(new ActionInfo(ActionType.group, new String[] { String.valueOf(groupId) }));


        createTerminatingServiceActions(dpId, (int)label, actionsInfos, tx);

        LOG.debug("Terminating service Entry for dpID {} : label : {} egress : {} installed successfully",
                dpId, label, groupId);
    }

    public void createTerminatingServiceActions( BigInteger destDpId, int label, List<ActionInfo> actionsInfos,
                                                 WriteTransaction tx) {
        List<MatchInfo> mkMatches = new ArrayList<>();

        LOG.debug("create terminatingServiceAction on DpnId = {} and serviceId = {} and actions = {}", destDpId , label,actionsInfos);

        // Matching metadata
        // FIXME vxlan vni bit set is not working properly with OVS.need to revisit
        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] {BigInteger.valueOf(label)}));

        List<InstructionInfo> mkInstructions = new ArrayList<>();
        mkInstructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));

        FlowEntity terminatingServiceTableFlowEntity = MDSALUtil.buildFlowEntity(destDpId, NwConstants.INTERNAL_TUNNEL_TABLE,
                getTableMissFlowRef(destDpId, NwConstants.INTERNAL_TUNNEL_TABLE,label), 5, String.format("%s:%d","TST Flow Entry ",label),
                0, 0, COOKIE_TUNNEL.add(BigInteger.valueOf(label)),mkMatches, mkInstructions);

        FlowKey flowKey = new FlowKey( new FlowId(terminatingServiceTableFlowEntity.getFlowId()) );

        FlowBuilder flowbld = terminatingServiceTableFlowEntity.getFlowBuilder();

        Node nodeDpn = buildDpnNode(terminatingServiceTableFlowEntity.getDpnId());
        InstanceIdentifier<Flow> flowInstanceId = InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeDpn.getKey()).augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(terminatingServiceTableFlowEntity.getTableId())).child(Flow.class,flowKey).build();
        tx.put(LogicalDatastoreType.CONFIGURATION, flowInstanceId, flowbld.build(),true );
    }

    private void removeTunnelTableEntry(BigInteger dpId, long label, WriteTransaction tx) {
        FlowEntity flowEntity;
        LOG.debug("remove terminatingServiceActions called with DpnId = {} and label = {}", dpId , label);
        List<MatchInfo> mkMatches = new ArrayList<>();
        // Matching metadata
        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] {BigInteger.valueOf(label)}));
        flowEntity = MDSALUtil.buildFlowEntity(dpId,
                NwConstants.INTERNAL_TUNNEL_TABLE,
                getTableMissFlowRef(dpId, NwConstants.INTERNAL_TUNNEL_TABLE, (int)label),
                5, String.format("%s:%d","TST Flow Entry ",label), 0, 0,
                COOKIE_TUNNEL.add(BigInteger.valueOf(label)), mkMatches, null);
        Node nodeDpn = buildDpnNode(flowEntity.getDpnId());
        FlowKey flowKey = new FlowKey(new FlowId(flowEntity.getFlowId()));
        InstanceIdentifier<Flow> flowInstanceId = InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeDpn.getKey()).augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(flowEntity.getTableId())).child(Flow.class, flowKey).build();

        tx.delete(LogicalDatastoreType.CONFIGURATION, flowInstanceId);
        LOG.debug("Terminating service Entry for dpID {} : label : {} removed successfully", dpId, label);
    }

    /**
     * Delete local FIB entry
     * @param vpnId
     * @param rd
     * @param vrfEntry
     * @return
     */
    public List<BigInteger> deleteLocalFibEntry(Long vpnId, String rd, VrfEntry vrfEntry) {
        List<BigInteger> returnLocalDpnId = new ArrayList<>();
        VpnNexthop localNextHopInfo = nextHopManager.getVpnNexthop(vpnId, vrfEntry.getDestPrefix());
        String localNextHopIP = vrfEntry.getDestPrefix();

        if (localNextHopInfo == null) {
            //Is this fib route an extra route? If yes, get the nexthop which would be an adjacency in the vpn
            Extraroute extra_route = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());
            if (extra_route != null) {
                for (String nextHopIp : extra_route.getNexthopIpList()) {
                    LOG.debug("NextHop IP for destination {} is {}", vrfEntry.getDestPrefix(), nextHopIp);
                    if (nextHopIp != null) {
                        localNextHopInfo = nextHopManager.getVpnNexthop(vpnId, nextHopIp + "/32");
                        localNextHopIP = nextHopIp + "/32";
                        BigInteger dpnId = checkDeleteLocalFibEntry(localNextHopInfo, localNextHopIP,
                                vpnId, rd, vrfEntry, true /*isExtraRoute*/);
                        if (!dpnId.equals(BigInteger.ZERO)) {
                            returnLocalDpnId.add(dpnId);
                        }
                    }
                }
            }

            if (localNextHopInfo == null) {
              /* Imported VRF entry */
                LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) &&
                        vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                    VpnNexthopBuilder vpnNexthopBuilder = new VpnNexthopBuilder();
                    vpnNexthopBuilder.setDpnId(lri.getDpnId());
                    BigInteger dpnId = checkDeleteLocalFibEntry(vpnNexthopBuilder.build(), localNextHopIP,
                            vpnId, rd, vrfEntry, false /*isExtraRoute*/);
                    if (!dpnId.equals(BigInteger.ZERO)) {
                        returnLocalDpnId.add(dpnId);
                    }
                }
            }


        } else {
            BigInteger dpnId = checkDeleteLocalFibEntry(localNextHopInfo, localNextHopIP,
                    vpnId, rd, vrfEntry, false /*isExtraRoute*/);
            if (!dpnId.equals(BigInteger.ZERO)) {
                returnLocalDpnId.add(dpnId);
            }
        }

        return returnLocalDpnId;
    }

    private BigInteger checkDeleteLocalFibEntry(VpnNexthop localNextHopInfo, final String localNextHopIP,
                                                final Long vpnId, final String rd,
                                                final VrfEntry vrfEntry, final boolean isExtraRoute) {
        if (localNextHopInfo != null) {
            final BigInteger dpnId = localNextHopInfo.getDpnId();;
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-"+ vpnId.toString() + "-" + dpnId.toString() + "-" + vrfEntry.getDestPrefix(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                            makeConnectedRoute(dpnId, vpnId, vrfEntry, rd, null /* instructions */,
                                    NwConstants.DEL_FLOW, tx);
                            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.SELF_IMPORTED) {
                                makeLFibTableEntry(dpnId, vrfEntry.getLabel(), null /* instructions */,
                                        DEFAULT_FIB_FLOW_PRIORITY, NwConstants.DEL_FLOW, tx);
                                removeTunnelTableEntry(dpnId, vrfEntry.getLabel(), tx);
                            }
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            futures.add(tx.submit());
                            return futures;
                        }
                    });
            //TODO: verify below adjacency call need to be optimized (?)
            deleteLocalAdjacency(dpnId, vpnId, localNextHopIP, vrfEntry.getDestPrefix());
            return dpnId;
        }
        return BigInteger.ZERO;
    }

    private InstanceIdentifier<Extraroute> getVpnToExtrarouteIdentifier(String vrfId, String ipPrefix) {
        return InstanceIdentifier.builder(VpnToExtraroute.class)
                .child(Vpn.class, new VpnKey(vrfId)).child(Extraroute.class,
                        new ExtrarouteKey(ipPrefix)).build();
    }

    private Extraroute getVpnToExtraroute(String rd, String ipPrefix) {
        Optional<Extraroute> extraRouteInfo =
                FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, getVpnToExtrarouteIdentifier(rd, ipPrefix));
        return  extraRouteInfo.isPresent() ? extraRouteInfo.get() : null;

    }

    Class<? extends TunnelTypeBase> getTunnelType(String ifName) {
        try {
            Future<RpcResult<GetTunnelTypeOutput>> result = interfaceManager.getTunnelType(
                    new GetTunnelTypeInputBuilder().setIntfName(ifName).build());
            RpcResult<GetTunnelTypeOutput> rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to getTunnelInterfaceId returned with Errors {}", rpcResult.getErrors());
            } else {
                return rpcResult.getResult().getTunnelType();
            }

        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting tunnel interface Id for tunnel type", e);
        }

        return null;

    }
    private void createRemoteFibEntry(final BigInteger remoteDpnId, final long vpnId, final VrfTablesKey vrfTableKey,
                                      final VrfEntry vrfEntry, WriteTransaction tx) {
        Boolean wrTxPresent = true;
        if (tx == null) {
            wrTxPresent = false;
            tx = dataBroker.newWriteOnlyTransaction();
        }
        String rd = vrfTableKey.getRouteDistinguisher();
        LOG.debug(  "createremotefibentry: adding route {} for rd {} on remoteDpnId {}",
                vrfEntry.getDestPrefix(), rd, remoteDpnId);
        /********************************************/
        List<AdjacencyResult> adjacencyResults = resolveAdjacency(remoteDpnId, vpnId, vrfEntry, rd);

        if (adjacencyResults.isEmpty()) {
            LOG.error("Could not get interface for nexthop: {} in vpn {}",
                    vrfEntry.getNextHopAddressList(), rd);
            LOG.warn("Failed to add Route: {} in vpn: {}",
                    vrfEntry.getDestPrefix(), rd);
            return;
        }

        for (AdjacencyResult adjacencyResult : adjacencyResults) {
            List<InstructionInfo> instructions = new ArrayList<>();
            List<ActionInfo> actionInfos = new ArrayList<>();
            String egressInterface = adjacencyResult.getInterfaceName();
            if (Tunnel.class.equals(adjacencyResult.getInterfaceType())) {
                addTunnelInterfaceActions(egressInterface, vpnId, vrfEntry, actionInfos);
            } else {
                addRewriteDstMacAction(vpnId, vrfEntry, actionInfos);
            }
            List<ActionInfo> egressActions = nextHopManager.getEgressActionsForInterface(egressInterface);
            if (egressActions.isEmpty()) {
                LOG.error(
                        "Failed to retrieve egress action for prefix {} nextHop {} interface {}. Aborting remote FIB entry creation.",
                        vrfEntry.getDestPrefix(), vrfEntry.getNextHopAddressList(), egressInterface);
                return;
            }
            actionInfos.addAll(egressActions);
            instructions.add(new InstructionInfo(InstructionType.apply_actions, actionInfos));
            makeConnectedRoute(remoteDpnId, vpnId, vrfEntry, rd, instructions, NwConstants.ADD_FLOW, tx);
        }
        if(!wrTxPresent ){
            tx.submit();
        }
        LOG.debug("Successfully added FIB entry for prefix {} in vpnId {}", vrfEntry.getDestPrefix(), vpnId);
    }

    private void addRewriteDstMacAction(long vpnId, VrfEntry vrfEntry, List<ActionInfo> actionInfos) {
        String ipPrefix = vrfEntry.getDestPrefix();
        Prefixes prefixInfo = FibUtil.getPrefixToInterface(dataBroker, vpnId, ipPrefix);
        if (prefixInfo == null) {
            LOG.debug("No prefix info found for prefix {}", ipPrefix);
            return;
        }

        String ifName = prefixInfo.getVpnInterfaceName();
        if (ifName == null) {
            LOG.warn("Failed to get VPN interface for prefix {}", ipPrefix);
            return;
        }

        String macAddress = FibUtil.getMacAddressFromPrefix(dataBroker, ifName, ipPrefix);
        if (macAddress == null) {
            LOG.warn("No MAC address found for VPN interface {} prefix {}", ifName, ipPrefix);
            return;
        }

        actionInfos.add(new ActionInfo(ActionType.set_field_eth_dest, new String[] { macAddress }, actionInfos.size()));
    }

    private void addTunnelInterfaceActions(String tunnelInterface, long vpnId, VrfEntry vrfEntry,
            List<ActionInfo> actionInfos) {
        Class<? extends TunnelTypeBase> tunnel_type = getTunnelType(tunnelInterface);
        if (tunnel_type.equals(TunnelTypeMplsOverGre.class)) {
            LOG.debug("Push label action for prefix {}", vrfEntry.getDestPrefix());
            actionInfos.add(new ActionInfo(ActionType.push_mpls, new String[] { null }));
            actionInfos.add(new ActionInfo(ActionType.set_field_mpls_label,
                    new String[] { Long.toString(vrfEntry.getLabel()) }));
        } else {
            int label = vrfEntry.getLabel().intValue();
            BigInteger tunnelId;
            // FIXME vxlan vni bit set is not working properly with OVS.need to
            // revisit
            if (tunnel_type.equals(TunnelTypeVxlan.class)) {
                tunnelId = BigInteger.valueOf(label);
            } else {
                tunnelId = BigInteger.valueOf(label);
            }

            LOG.debug("adding set tunnel id action for label {}", label);
            actionInfos.add(new ActionInfo(ActionType.set_field_tunnel_id, new BigInteger[] { tunnelId }));
            addRewriteDstMacAction(vpnId, vrfEntry, actionInfos);
        }
    }

    private void delIntfFromDpnToVpnList(long vpnId, BigInteger dpnId, String intfName, String rd) {
        InstanceIdentifier<VpnToDpnList> id = FibUtil.getVpnToDpnListIdentifier(rd, dpnId);
        Optional<VpnToDpnList> dpnInVpn = FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if (dpnInVpn.isPresent()) {
            List<VpnInterfaces> vpnInterfaces = dpnInVpn.get().getVpnInterfaces();
            VpnInterfaces currVpnInterface = new VpnInterfacesBuilder().setInterfaceName(intfName).build();

            if (vpnInterfaces.remove(currVpnInterface)) {
                if (vpnInterfaces.isEmpty()) {
                    LOG.trace("Last vpn interface {} on dpn {} for vpn {}. Clean up fib in dpn", intfName, dpnId, rd);
                    FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
                    cleanUpDpnForVpn(dpnId, vpnId, rd, null);
                } else {
                    LOG.trace("Delete vpn interface {} from dpn {} to vpn {} list.", intfName, dpnId, rd);
                    FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL, id.child(
                            VpnInterfaces.class,
                            new VpnInterfacesKey(intfName)));
                }
            }
        }
    }

    void cleanUpOpDataForFib(Long vpnId, String rd, final VrfEntry vrfEntry) {
    /* Get interface info from prefix to interface mapping;
        Use the interface info to get the corresponding vpn interface op DS entry,
        remove the adjacency corresponding to this fib entry.
        If adjacency removed is the last adjacency, clean up the following:
         - vpn interface from dpntovpn list, dpn if last vpn interface on dpn
         - prefix to interface entry
         - vpn interface op DS
     */
        LOG.debug("Cleanup of prefix {} in VPN {}", vrfEntry.getDestPrefix(), vpnId);
        Prefixes prefixInfo = FibUtil.getPrefixToInterface(dataBroker, vpnId, vrfEntry.getDestPrefix());
        Extraroute extraRoute = null;
        if (prefixInfo == null) {
            extraRoute = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());
            if(extraRoute != null) {
                for (String nextHopIp : extraRoute.getNexthopIpList()) {
                    LOG.debug("NextHop IP for destination {} is {}", vrfEntry.getDestPrefix(), nextHopIp);

                    if (nextHopIp != null) {
                        prefixInfo = FibUtil.getPrefixToInterface(dataBroker, vpnId, nextHopIp + "/32");
                        checkCleanUpOpDataForFib(prefixInfo, vpnId, rd, vrfEntry, extraRoute);
                    }
                }
            }
            if (prefixInfo == null) {
                LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) &&
                        vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                    PrefixesBuilder prefixBuilder = new PrefixesBuilder();
                    prefixBuilder.setDpnId(lri.getDpnId());
                    prefixBuilder.setVpnInterfaceName(lri.getVpnInterfaceName());
                    prefixBuilder.setIpAddress(lri.getPrefix());
                    prefixInfo = prefixBuilder.build();
                    LOG.debug("Fetched labelRouteInfo for label {} interface {} and got dpn {}",
                            vrfEntry.getLabel(), prefixInfo.getVpnInterfaceName(), lri.getDpnId());
                    checkCleanUpOpDataForFib(prefixInfo, vpnId, rd, vrfEntry, extraRoute);
                }
            }
        } else {
            checkCleanUpOpDataForFib(prefixInfo, vpnId, rd, vrfEntry, extraRoute);
        }
    }

    private void checkCleanUpOpDataForFib(final Prefixes prefixInfo, final Long vpnId, final String rd,
                                          final VrfEntry vrfEntry, final Extraroute extraRoute) {

        if (prefixInfo == null) {
            LOG.debug("Cleanup VPN Data Failed as unable to find prefix Info for prefix {}", vrfEntry.getDestPrefix());
            return; //Don't have any info for this prefix (shouldn't happen); need to return
        }

        String ifName = prefixInfo.getVpnInterfaceName();
        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + ifName,
                new CleanupVpnInterfaceWorker(prefixInfo, vpnId, rd, vrfEntry, extraRoute));
    }

    private class CleanupVpnInterfaceWorker implements Callable<List<ListenableFuture<Void>>> {
        Prefixes prefixInfo;
        Long vpnId;
        String rd;
        VrfEntry vrfEntry;
        Extraroute extraRoute;

        public CleanupVpnInterfaceWorker(final Prefixes prefixInfo, final Long vpnId, final String rd,
                                         final VrfEntry vrfEntry, final Extraroute extraRoute) {
            this.prefixInfo = prefixInfo;
            this.vpnId = vpnId;
            this.rd= rd;
            this.vrfEntry= vrfEntry;
            this.extraRoute = extraRoute;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            // If another renderer(for eg : CSS) needs to be supported, check can be performed here
            // to call the respective helpers.

            //First Cleanup LabelRouteInfo
            //TODO (KIRAN) :Need to be handle in a better way
            if (vrfEntry.getEncapType().equals(VrfEntry.EncapType.Mplsgre)) {
                synchronized (vrfEntry.getLabel().toString().intern()) {
                    LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                    if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) &&
                            vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                        Optional<VpnInstanceOpDataEntry> vpnInstanceOpDataEntryOptional = FibUtil.getVpnInstanceOpData(dataBroker, rd);
                        String vpnInstanceName = "";
                        if (vpnInstanceOpDataEntryOptional.isPresent()) {
                            vpnInstanceName = vpnInstanceOpDataEntryOptional.get().getVpnInstanceName();
                        }
                        boolean lriRemoved = deleteLabelRouteInfo(lri, vpnInstanceName);
                        if (lriRemoved) {
                            String parentRd = lri.getParentVpnRd();
                            FibUtil.releaseId(idManager, FibConstants.VPN_IDPOOL_NAME,
                                    FibUtil.getNextHopLabelKey(parentRd, vrfEntry.getDestPrefix()));
                        }
                    } else {
                        FibUtil.releaseId(idManager, FibConstants.VPN_IDPOOL_NAME,
                                FibUtil.getNextHopLabelKey(rd, vrfEntry.getDestPrefix()));
                    }
                }
            }
            String ifName = prefixInfo.getVpnInterfaceName();
            Optional<VpnInterface> optvpnInterface = FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                    FibUtil.getVpnInterfaceIdentifier(ifName));
            if (optvpnInterface.isPresent()) {
                long associatedVpnId = FibUtil.getVpnId(dataBroker, optvpnInterface.get().getVpnInstanceName());
                if (vpnId != associatedVpnId) {
                    LOG.warn("Prefixes {} are associated with different vpn instance with id : {} rather than {}",
                            vrfEntry.getDestPrefix(), associatedVpnId, vpnId);
                    LOG.warn("Not proceeding with Cleanup op data for prefix {}", vrfEntry.getDestPrefix());
                    return null;
                } else {
                    LOG.debug("Processing cleanup of prefix {} associated with vpn {}",
                            vrfEntry.getDestPrefix(), associatedVpnId);
                }
            }
            if (extraRoute != null) {
                FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        FibUtil.getVpnToExtrarouteIdentifier(rd, vrfEntry.getDestPrefix()));
            }
            Optional<Adjacencies> optAdjacencies = FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                    FibUtil.getAdjListPath(ifName));
            int numAdj = 0;
            if (optAdjacencies.isPresent()) {
                numAdj = optAdjacencies.get().getAdjacency().size();
            }
            //remove adjacency corr to prefix
            if (numAdj > 1) {
                LOG.info("cleanUpOpDataForFib: remove adjacency for prefix: {} {}", vpnId, vrfEntry.getDestPrefix());
                FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        FibUtil.getAdjacencyIdentifier(ifName, vrfEntry.getDestPrefix()));
            }
            if ((numAdj - 1) == 0) { //there are no adjacencies left for this vpn interface, clean up
                //clean up the vpn interface from DpnToVpn list
                LOG.trace("Clean up vpn interface {} from dpn {} to vpn {} list.", ifName, prefixInfo.getDpnId(), rd);
                FibUtil.delete(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        FibUtil.getVpnInterfaceIdentifier(ifName));
            }
            return null;
        }
    }

    private void deleteFibEntries(final InstanceIdentifier<VrfEntry> identifier, final VrfEntry vrfEntry) {
        final VrfTablesKey vrfTableKey = identifier.firstKeyOf(VrfTables.class);
        final String rd  = vrfTableKey.getRouteDistinguisher();
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(vrfTableKey.getRouteDistinguisher());
        if (vpnInstance == null) {
            LOG.error("VPN Instance for rd {} is not available from VPN Op Instance Datastore", rd);
            return;
        }
        final Collection<VpnToDpnList> vpnToDpnList = vpnInstance.getVpnToDpnList();
        long elanTag = 0L;
        SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
        if (subnetRoute != null) {
            elanTag = subnetRoute.getElantag();
            LOG.trace("SubnetRoute augmented vrfentry found for rd {} prefix {} with elantag {}",
                    rd, vrfEntry.getDestPrefix(), elanTag);
            if (vpnToDpnList != null) {
                DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                dataStoreCoordinator.enqueueJob("FIB-" + rd.toString() + "-" + vrfEntry.getDestPrefix(),
                        new Callable<List<ListenableFuture<Void>>>() {
                            @Override
                            public List<ListenableFuture<Void>> call() throws Exception {
                                WriteTransaction tx = dataBroker.newWriteOnlyTransaction();

                                for (final VpnToDpnList curDpn : vpnToDpnList) {

                                    makeConnectedRoute(curDpn.getDpnId(), vpnInstance.getVpnId(), vrfEntry,
                                            vrfTableKey.getRouteDistinguisher(), null, NwConstants.DEL_FLOW, tx);
                                    if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.SELF_IMPORTED) {
                                        makeLFibTableEntry(curDpn.getDpnId(), vrfEntry.getLabel(), null,
                                                DEFAULT_FIB_FLOW_PRIORITY, NwConstants.DEL_FLOW, tx);
                                    }
                                }
                                List<ListenableFuture<Void>> futures = new ArrayList<>();
                                futures.add(tx.submit());
                                return futures;
                            }
                        });
            }
            synchronized (vrfEntry.getLabel().toString().intern()) {
                LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix()) && vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                    Optional<VpnInstanceOpDataEntry> vpnInstanceOpDataEntryOptional = FibUtil.getVpnInstanceOpData(dataBroker, rd);
                    String vpnInstanceName = "";
                    if (vpnInstanceOpDataEntryOptional.isPresent()) {
                        vpnInstanceName = vpnInstanceOpDataEntryOptional.get().getVpnInstanceName();
                    }
                    boolean lriRemoved = this.deleteLabelRouteInfo(lri, vpnInstanceName);
                    if (lriRemoved) {
                        String parentRd = lri.getParentVpnRd();
                        FibUtil.releaseId(idManager, FibConstants.VPN_IDPOOL_NAME,
                                FibUtil.getNextHopLabelKey(parentRd, vrfEntry.getDestPrefix()));
                        LOG.trace("deleteFibEntries: Released subnetroute label {} for rd {} prefix {} as labelRouteInfo cleared", vrfEntry.getLabel(), rd,
                                vrfEntry.getDestPrefix());
                    }
                } else {
                    FibUtil.releaseId(idManager, FibConstants.VPN_IDPOOL_NAME,
                            FibUtil.getNextHopLabelKey(rd, vrfEntry.getDestPrefix()));
                    LOG.trace("deleteFibEntries: Released subnetroute label {} for rd {} prefix {}", vrfEntry.getLabel(), rd,
                            vrfEntry.getDestPrefix());
                }
            }
            return;
        }
        if (installRouterFibEntries(vrfEntry, vpnToDpnList, vpnInstance.getVpnId(), NwConstants.DEL_FLOW)) {
            return;
        }

        final List<BigInteger> localDpnIdList = deleteLocalFibEntry(vpnInstance.getVpnId(),
                vrfTableKey.getRouteDistinguisher(), vrfEntry);
        if (vpnToDpnList != null) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + rd.toString() + "-" + vrfEntry.getDestPrefix(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            WriteTransaction tx = dataBroker.newWriteOnlyTransaction();

                            if (localDpnIdList.size() <= 0) {
                                for (VpnToDpnList curDpn : vpnToDpnList) {
                                    if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
                                        if (curDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                                            deleteRemoteRoute(BigInteger.ZERO, curDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, tx);
                                        }
                                    } else {
                                        deleteRemoteRoute(BigInteger.ZERO, curDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, tx);
                                    }
                                }
                            } else {
                                for (BigInteger localDpnId : localDpnIdList) {
                                    for (VpnToDpnList curDpn : vpnToDpnList) {
                                        if (!curDpn.getDpnId().equals(localDpnId)) {
                                            if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
                                                if (curDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                                                    deleteRemoteRoute(localDpnId, curDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, tx);
                                                }
                                            } else {
                                                deleteRemoteRoute(localDpnId, curDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, tx);
                                            }
                                        }
                                    }
                                }
                            }
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            futures.add(tx.submit());
                            return futures;
                        }
                    });
        }

        //The flow/group entry has been deleted from config DS; need to clean up associated operational
        //DS entries in VPN Op DS, VpnInstanceOpData and PrefixToInterface to complete deletion
        cleanUpOpDataForFib(vpnInstance.getVpnId(), vrfTableKey.getRouteDistinguisher(), vrfEntry);

        // Remove all fib entries configured due to interVpnLink, when nexthop is the opposite endPoint
        // of the interVpnLink.
        Optional<String> optVpnUuid = FibUtil.getVpnNameFromRd(this.dataBroker, rd);
        if ( optVpnUuid.isPresent() ) {
            String vpnUuid = optVpnUuid.get();
            List<String> routeNexthoplist = vrfEntry.getNextHopAddressList();
            if(routeNexthoplist.isEmpty()) {
                LOG.trace("NextHopList is empty for VrfEntry {}", vrfEntry);
                return;
            }
            String routeNexthop = routeNexthoplist.get(0);
            Optional<InterVpnLinkDataComposite> optInterVpnLink = InterVpnLinkCache.getInterVpnLinkByVpnId(vpnUuid);
            if ( optInterVpnLink.isPresent() ) {
                InterVpnLinkDataComposite interVpnLink = optInterVpnLink.get();
                if ( interVpnLink.isIpAddrTheOtherVpnEndpoint(routeNexthop, vpnUuid))
                {
                    // This is route that points to the other endpoint of an InterVpnLink
                    // In that case, we should look for the FIB table pointing to LPortDispatcher table and remove it.
                    removeInterVPNLinkRouteFlows(interVpnLink.getInterVpnLinkName(),
                                                 interVpnLink.isFirstEndpointVpnName(rd),
                                                 vrfEntry);
                }
            }
        }

    }

    /*
      Please note that the following deleteFibEntries will be invoked only for BGP Imported Routes.
      The invocation of the following method is via delete() callback from the MDSAL Batching Infrastructure
      provided by ResourceBatchingManager
     */
    private void deleteFibEntries(WriteTransaction writeTx, final InstanceIdentifier<VrfEntry> identifier, final VrfEntry vrfEntry) {
        final VrfTablesKey vrfTableKey = identifier.firstKeyOf(VrfTables.class);

        final String rd  = vrfTableKey.getRouteDistinguisher();
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(vrfTableKey.getRouteDistinguisher());
        if (vpnInstance == null) {
            LOG.debug("VPN Instance for rd {} is not available from VPN Op Instance Datastore", rd);
            return;
        }
        final Collection<VpnToDpnList> vpnToDpnList = vpnInstance.getVpnToDpnList();
        if (vpnToDpnList != null) {
            for (VpnToDpnList curDpn : vpnToDpnList) {
                if (curDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                    deleteRemoteRoute(BigInteger.ZERO, curDpn.getDpnId(), vpnInstance.getVpnId(), vrfTableKey, vrfEntry, writeTx);
                }
            }
        }
    }

    public void deleteRemoteRoute(final BigInteger localDpnId, final BigInteger remoteDpnId,
                                  final long vpnId, final VrfTablesKey vrfTableKey,
                                  final VrfEntry vrfEntry, WriteTransaction tx) {

        Boolean wrTxPresent = true;
        if (tx == null) {
            wrTxPresent = false;
            tx = dataBroker.newWriteOnlyTransaction();
        }

        LOG.debug("deleting remote route: prefix={}, vpnId={} localDpnId {} remoteDpnId {}", vrfEntry.getDestPrefix(), vpnId, localDpnId, remoteDpnId);
        String rd = vrfTableKey.getRouteDistinguisher();

        if(localDpnId != null) {
            // localDpnId is not known when clean up happens for last vm for a vpn on a dpn
            deleteFibEntry(remoteDpnId, vpnId, vrfEntry, rd, tx);
            return;
        }

        // below two reads are kept as is, until best way is found to identify dpnID
        VpnNexthop localNextHopInfo = nextHopManager.getVpnNexthop(vpnId, vrfEntry.getDestPrefix());
        Extraroute extraRoute = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());

        if (localNextHopInfo == null && extraRoute != null) {
            // Is this fib route an extra route? If yes, get the nexthop which would be an adjacency in the vpn
            for (String nextHopIp : extraRoute.getNexthopIpList()) {
                localNextHopInfo = nextHopManager.getVpnNexthop(vpnId, nextHopIp);
                checkDpnDeleteFibEntry(localNextHopInfo, remoteDpnId, vpnId, vrfEntry, rd, tx);
            }
        } else {
            checkDpnDeleteFibEntry(localNextHopInfo, remoteDpnId, vpnId, vrfEntry, rd, tx);
        }
        if(!wrTxPresent ){
            tx.submit();
        }
    }

    private boolean checkDpnDeleteFibEntry(VpnNexthop localNextHopInfo, BigInteger remoteDpnId, long vpnId,
                                           VrfEntry vrfEntry, String rd, WriteTransaction tx){
        boolean isRemoteRoute = true;
        if (localNextHopInfo != null) {
            isRemoteRoute = !remoteDpnId.equals(localNextHopInfo.getDpnId());
        }
        if (isRemoteRoute) {
            deleteFibEntry(remoteDpnId, vpnId, vrfEntry, rd, tx);
            return true;
        } else {
            LOG.debug("Did not delete FIB entry: rd={}, vrfEntry={}, as it is local to dpnId={}", rd, vrfEntry.getDestPrefix(), remoteDpnId);
            return false;
        }
    }

    private void deleteFibEntry(BigInteger remoteDpnId, long vpnId, VrfEntry vrfEntry, String rd, WriteTransaction tx){
        makeConnectedRoute(remoteDpnId, vpnId, vrfEntry, rd, null, NwConstants.DEL_FLOW, tx);
        LOG.debug("Successfully delete FIB entry: vrfEntry={}, vpnId={}", vrfEntry.getDestPrefix(), vpnId);
    }

    private long get
            (byte[] rawIpAddress) {
        return (((rawIpAddress[0] & 0xFF) << (3 * 8)) + ((rawIpAddress[1] & 0xFF) << (2 * 8))
                + ((rawIpAddress[2] & 0xFF) << (1 * 8)) + (rawIpAddress[3] & 0xFF)) & 0xffffffffL;
    }

    public void makeConnectedRoute(BigInteger dpId, long vpnId, VrfEntry vrfEntry, String rd,
                                    List<InstructionInfo> instructions, int addOrRemove, WriteTransaction tx) {
        Boolean wrTxPresent = true;
        if (tx == null) {
            wrTxPresent = false;
            tx = dataBroker.newWriteOnlyTransaction();
        }

        LOG.trace("makeConnectedRoute: vrfEntry {}", vrfEntry);
        String values[] = vrfEntry.getDestPrefix().split("/");
        String ipAddress = values[0];
        int prefixLength = (values.length == 1) ? 0 : Integer.parseInt(values[1]);
        if (addOrRemove == NwConstants.ADD_FLOW) {
            LOG.debug("Adding route to DPN {} for rd {} prefix {} ", dpId, rd, vrfEntry.getDestPrefix());
        } else {
            LOG.debug("Removing route from DPN {} for rd {} prefix {}", dpId, rd, vrfEntry.getDestPrefix());
        }
        InetAddress destPrefix;
        try {
            destPrefix = InetAddress.getByName(ipAddress);
        } catch (UnknownHostException e) {
            LOG.error("Failed to get destPrefix for prefix {} ", vrfEntry.getDestPrefix(), e);
            return;
        }

        List<MatchInfo> matches = new ArrayList<>();

        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(vpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        if (destPrefix instanceof Inet4Address) {
            matches.add(new MatchInfo(MatchFieldType.eth_type,
                    new long[] { NwConstants.ETHTYPE_IPV4 }));
            if(prefixLength != 0) {
                matches.add(new MatchInfo(MatchFieldType.ipv4_destination, new String[] {
                        destPrefix.getHostAddress(), Integer.toString(prefixLength)}));
            }
        } else {
            matches.add(new MatchInfo(MatchFieldType.eth_type,
                    new long[] { NwConstants.ETHTYPE_IPV6 }));
            if(prefixLength != 0) {
                matches.add(new MatchInfo(MatchFieldType.ipv6_destination, new String[] {
                        destPrefix.getHostAddress() + "/" + Integer.toString(prefixLength)}));
            }
        }

        int priority = DEFAULT_FIB_FLOW_PRIORITY + prefixLength;
        String flowRef = getFlowRef(dpId, NwConstants.L3_FIB_TABLE, rd, priority, destPrefix);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_FIB_TABLE, flowRef, priority, flowRef, 0, 0,
                COOKIE_VM_FIB_TABLE, matches, instructions);

        Flow flow = flowEntity.getFlowBuilder().build();
        String flowId = flowEntity.getFlowId();
        FlowKey flowKey = new FlowKey( new FlowId(flowId));
        Node nodeDpn = buildDpnNode(dpId);

        InstanceIdentifier<Flow> flowInstanceId = InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeDpn.getKey()).augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(flow.getTableId())).child(Flow.class, flowKey).build();

        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
            SubTransaction subTransaction = new SubTransactionImpl();
            if (addOrRemove == NwConstants.ADD_FLOW) {
                subTransaction.setInstanceIdentifier(flowInstanceId);
                subTransaction.setInstance(flow);
                subTransaction.setAction(SubTransaction.CREATE);
            } else {
                subTransaction.setInstanceIdentifier(flowInstanceId);
                subTransaction.setAction(SubTransaction.DELETE);
            }
            transactionObjects.add(subTransaction);
        }

        if (addOrRemove == NwConstants.ADD_FLOW) {
            tx.put(LogicalDatastoreType.CONFIGURATION, flowInstanceId,flow, true);
        } else {
            tx.delete(LogicalDatastoreType.CONFIGURATION, flowInstanceId);
        }

        if(!wrTxPresent ){
            tx.submit();
        }
    }

    //TODO: How to handle the below code, its a copy paste from MDSALManager.java
    Node buildDpnNode(BigInteger dpnId) {
        NodeId nodeId = new NodeId("openflow:" + dpnId);
        Node nodeDpn = new NodeBuilder().setId(nodeId).setKey(new NodeKey(nodeId)).build();

        return nodeDpn;
    }

    private void makeLFibTableEntry(BigInteger dpId, long label, List<InstructionInfo> instructions, int priority,
                                    int addOrRemove, WriteTransaction tx) {
        Boolean wrTxPresent = true;
        if (tx == null) {
            wrTxPresent = false;
            tx = dataBroker.newWriteOnlyTransaction();
        }

        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_MPLS_UC }));
        matches.add(new MatchInfo(MatchFieldType.mpls_label, new String[]{Long.toString(label)}));

        // Install the flow entry in L3_LFIB_TABLE
        String flowRef = getFlowRef(dpId, NwConstants.L3_LFIB_TABLE, label, priority);

        FlowEntity flowEntity;
        flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_LFIB_TABLE, flowRef, priority, flowRef, 0, 0,
                NwConstants.COOKIE_VM_LFIB_TABLE, matches, instructions);
        Flow flow = flowEntity.getFlowBuilder().build();
        String flowId = flowEntity.getFlowId();
        FlowKey flowKey = new FlowKey( new FlowId(flowId));
        Node nodeDpn = buildDpnNode(dpId);
        InstanceIdentifier<Flow> flowInstanceId = InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeDpn.getKey()).augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(flow.getTableId())).child(Flow.class, flowKey).build();

        if (addOrRemove == NwConstants.ADD_FLOW) {
            tx.put(LogicalDatastoreType.CONFIGURATION, flowInstanceId,flow, true);
        } else {
            tx.delete(LogicalDatastoreType.CONFIGURATION, flowInstanceId);
        }
        if(!wrTxPresent ){
            tx.submit();
        }

        LOG.debug("LFIB Entry for dpID {} : label : {} instructions {} : key {} {} successfully",
                  dpId, label, instructions, flowKey, (NwConstants.ADD_FLOW == addOrRemove) ? "ADDED" : "REMOVED");
    }

    void deleteLocalAdjacency(final BigInteger dpId, final long vpnId, final String ipAddress,
                                      final String ipPrefixAddress) {
        LOG.trace("deleteLocalAdjacency called with dpid {}, vpnId{}, ipAddress {}",dpId, vpnId, ipAddress);
        try {
            nextHopManager.removeLocalNextHop(dpId, vpnId, ipAddress, ipPrefixAddress);
        } catch (NullPointerException e) {
            LOG.trace("", e);
        }
    }

    public void populateFibOnNewDpn(final BigInteger dpnId, final long vpnId, final String rd,
            final FutureCallback<List<Void>> callback) {
        LOG.trace("New dpn {} for vpn {} : populateFibOnNewDpn", dpnId, rd);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (!vrfTable.isPresent()) {
            LOG.warn("VRF Table not yet available for RD {}", rd);
            if (callback != null) {
                List<ListenableFuture<Void>> futures = new ArrayList<>();
                ListenableFuture<List<Void>> listenableFuture = Futures.allAsList(futures);
                Futures.addCallback(listenableFuture, callback);
            }
            return;
        }
        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" +  dpnId.toString(),
                new Callable<List<ListenableFuture<Void>>>() {
            @Override
            public List<ListenableFuture<Void>> call() throws Exception {
                List<ListenableFuture<Void>> futures = new ArrayList<>();
                synchronized (vpnInstance.getVpnInstanceName().intern()) {
                    WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                    for (final VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                        SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
                        if (subnetRoute != null) {
                            long elanTag = subnetRoute.getElantag();
                            installSubnetRouteInFib(dpnId, elanTag, rd, vpnId, vrfEntry, tx);
                            continue;
                        }
                        RouterInterface routerInt = vrfEntry.getAugmentation(RouterInterface.class);
                        if (routerInt != null) {
                            LOG.trace( "Router augmented vrfentry found rd:{}, uuid:{}, ip:{}, mac:{}",
                                    rd, routerInt.getUuid(), vrfEntry.getDestPrefix(), vrfEntry.getMacAddress());
                            installRouterFibEntry(vrfEntry, dpnId, vpnId, routerInt.getUuid(), vrfEntry.getDestPrefix(),
                                    new MacAddress(vrfEntry.getMacAddress()), NwConstants.ADD_FLOW);
                            continue;
                        }
                        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.SELF_IMPORTED) { //Handle local flow creation for imports
                            LabelRouteInfo lri = getLabelRouteInfo(vrfEntry.getLabel());
                            if (lri != null && lri.getPrefix().equals(vrfEntry.getDestPrefix())
                                    && vrfEntry.getNextHopAddressList().contains(lri.getNextHopIpList().get(0))) {
                                if (lri.getDpnId().equals(dpnId)) {
                                    createLocalFibEntry(vpnId, rd, vrfEntry);
                                    continue;
                                }
                            }
                        }
                        // Passing null as we don't know the dpn
                        // to which prefix is attached at this point
                        createRemoteFibEntry(dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, tx);
                    }
                    //TODO: if we have 100K entries in FIB, can it fit in one Tranasaction (?)
                    futures.add(tx.submit());
                }
                if (callback != null) {
                    ListenableFuture<List<Void>> listenableFuture = Futures.allAsList(futures);
                    Futures.addCallback(listenableFuture, callback);
                }
                return futures;
            }
        });
    }


    public void populateExternalRoutesOnDpn(final BigInteger dpnId, final long vpnId, final String rd,
                                            final String localNextHopIp, final String remoteNextHopIp) {
        LOG.trace("populateExternalRoutesOnDpn : dpn {}, vpn {}, rd {}, localNexthopIp {} , remoteNextHopIp {} ",
                dpnId, vpnId, rd, localNextHopIp, remoteNextHopIp);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (vrfTable.isPresent()) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + dpnId.toString(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            synchronized (vpnInstance.getVpnInstanceName().intern()) {
                                WriteTransaction writeCfgTxn = dataBroker.newWriteOnlyTransaction();
                                for (VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                                    if(!vrfEntry.getNextHopAddressList().isEmpty()) {
                                        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
                                            if (remoteNextHopIp.trim().equals(vrfEntry.getNextHopAddressList().get(0).trim())) {
                                                LOG.trace(" creating remote FIB entry for prefix {} rd {}", vrfEntry.getDestPrefix(), rd);
                                                createRemoteFibEntry(dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, writeCfgTxn);
                                            }
                                        }
                                    }
                                }
                                futures.add(writeCfgTxn.submit());
                            }
                            return futures;
                        }
                    });
        }
    }

    public void populateInternalRoutesOnDpn(final BigInteger dpnId, final long vpnId, final String rd,
                                            final String localNextHopIp, final String remoteNextHopIp) {
        LOG.trace("populateInternalRoutesOnDpn : dpn {}, vpn {}, rd {}, localNexthopIp {} , remoteNextHopIp {} ",
                dpnId, vpnId, rd, localNextHopIp, remoteNextHopIp);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (vrfTable.isPresent()) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + dpnId.toString(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            synchronized (vpnInstance.getVpnInstanceName().intern()) {
                                WriteTransaction writeCfgTxn = dataBroker.newWriteOnlyTransaction();
                                for (VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                                    // Handle Internal Routes only (i.e., STATIC for now)
                                    if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.STATIC) {
                                        SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
                                        /* Ignore SubnetRoute entry */
                                        if (subnetRoute == null) {
                                            if(!vrfEntry.getNextHopAddressList().isEmpty()) {
                                                if (remoteNextHopIp.trim().equals(vrfEntry.getNextHopAddressList().get(0).trim())) {
                                                    LOG.trace(" creating remote FIB entry for prefix {} rd {} on Dpn {}", vrfEntry.getDestPrefix(), rd, dpnId);
                                                    createRemoteFibEntry(dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, writeCfgTxn);
                                                }
                                            }
                                        }
                                    }
                                }
                                futures.add(writeCfgTxn.submit());
                            }
                            return futures;
                        }
                    });
        }
    }

    public void manageRemoteRouteOnDPN(final boolean action,
                                       final BigInteger localDpnId,
                                       final long vpnId,
                                       final String  rd,
                                       final String destPrefix,
                                       final String destTepIp) {
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);

        if (vpnInstance == null) {
            LOG.error("VpnInstance for rd {} not present for prefix {}", rd, destPrefix);
            return;
        }
        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + localDpnId.toString(),
                new Callable<List<ListenableFuture<Void>>>() {
                    @Override
                    public List<ListenableFuture<Void>> call() throws Exception {
                        List<ListenableFuture<Void>> futures = new ArrayList<>();
                        synchronized (vpnInstance.getVpnInstanceName().intern()) {
                            WriteTransaction writeTransaction = dataBroker.newWriteOnlyTransaction();
                            VrfTablesKey vrfTablesKey = new VrfTablesKey(rd);
                            VrfEntry vrfEntry = getVrfEntry(dataBroker, rd, destPrefix);
                            if (vrfEntry == null)
                                return futures;
                            LOG.trace("manageRemoteRouteOnDPN :: action {}, DpnId {}, vpnId {}, rd {}, destPfx {}",
                                    action, localDpnId, vpnId, rd, destPrefix);
                            List<String> nhList = new ArrayList<String>();
                            List<String> nextHopAddressList = vrfEntry.getNextHopAddressList();
                            VrfEntry modVrfEntry;
                            if (nextHopAddressList == null || (nextHopAddressList.isEmpty())) {
                                nhList = Arrays.asList(destTepIp);
                                modVrfEntry = new VrfEntryBuilder(vrfEntry).setNextHopAddressList(nhList).build();
                            } else {
                                modVrfEntry = vrfEntry;
                            }

                            if (action == true) {
                                LOG.trace("manageRemoteRouteOnDPN updated(add)  vrfEntry :: {}", modVrfEntry);
                                createRemoteFibEntry(localDpnId, vpnId, vrfTablesKey, modVrfEntry, writeTransaction);
                            } else {
                                LOG.trace("manageRemoteRouteOnDPN updated(remove)  vrfEntry :: {}", modVrfEntry);
                                deleteRemoteRoute(null, localDpnId, vpnId, vrfTablesKey, modVrfEntry, writeTransaction);
                            }
                            futures.add(writeTransaction.submit());
                        }
                        return futures;
                    }
                });
    }

    public void cleanUpDpnForVpn(final BigInteger dpnId, final long vpnId, final String rd,
                                 final FutureCallback<List<Void>> callback) {
        LOG.trace("cleanUpDpnForVpn: Remove dpn {} for vpn {} : cleanUpDpnForVpn", dpnId, rd);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (vrfTable.isPresent()) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + dpnId.toString(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            synchronized (vpnInstance.getVpnInstanceName().intern()) {
                                WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
                                for (final VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                                    /* Handle subnet routes here */
                                    SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
                                    if (subnetRoute != null) {
                                        LOG.trace("Cleaning subnetroute {} on dpn {} for vpn {} : cleanUpDpnForVpn", vrfEntry.getDestPrefix(),
                                                dpnId, rd);
                                        makeConnectedRoute(dpnId, vpnId, vrfEntry, rd, null, NwConstants.DEL_FLOW, tx);
                                        makeLFibTableEntry(dpnId, vrfEntry.getLabel(), null, DEFAULT_FIB_FLOW_PRIORITY, NwConstants.DEL_FLOW, tx);
                                        LOG.trace("cleanUpDpnForVpn: Released subnetroute label {} for rd {} prefix {}", vrfEntry.getLabel(), rd,
                                                vrfEntry.getDestPrefix());
                                        continue;
                                    }
                                    // ping responder for router interfaces
                                    RouterInterface routerInt = vrfEntry.getAugmentation(RouterInterface.class);
                                    if (routerInt != null) {
                                        LOG.trace("Router augmented vrfentry found for rd:{}, uuid:{}, ip:{}, mac:{}",
                                                rd, routerInt.getUuid(), vrfEntry.getDestPrefix(), vrfEntry.getMacAddress());
                                        installRouterFibEntry(vrfEntry, dpnId, vpnId, routerInt.getUuid(), vrfEntry.getDestPrefix(),
                                                new MacAddress(vrfEntry.getMacAddress()), NwConstants.DEL_FLOW);
                                        continue;
                                    }
                                    // Passing null as we don't know the dpn
                                    // to which prefix is attached at this point
                                    deleteRemoteRoute(null, dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, tx);
                                }
                                futures.add(tx.submit());
                                if (callback != null) {
                                    ListenableFuture<List<Void>> listenableFuture = Futures.allAsList(futures);
                                    Futures.addCallback(listenableFuture, callback);
                                }
                            }
                            return futures;
                        }
                    });
        }
    }

    public void cleanUpExternalRoutesOnDpn(final BigInteger dpnId, final long vpnId, final String rd,
                                           final String localNextHopIp, final String remoteNextHopIp) {
        LOG.trace(  "cleanUpExternalRoutesOnDpn : cleanup remote routes on dpn {} for vpn {}, rd {}, " +
                        " localNexthopIp {} , remoteNexhtHopIp {}",
                dpnId, vpnId, rd, localNextHopIp, remoteNextHopIp);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (vrfTable.isPresent()) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + dpnId.toString(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            synchronized (vpnInstance.getVpnInstanceName().intern()) {
                                WriteTransaction writeTransaction = dataBroker.newWriteOnlyTransaction();
                                for (VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                                    if(!vrfEntry.getNextHopAddressList().isEmpty()) {
                                        if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.BGP) {
                                            if (remoteNextHopIp.trim().equals(vrfEntry.getNextHopAddressList().get(0).trim())) {
                                                LOG.trace(" deleting remote FIB entry {}", vrfEntry);
                                                deleteRemoteRoute(null, dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, writeTransaction);
                                            }
                                        }
                                    }
                                }
                                futures.add(writeTransaction.submit());
                            }
                            return futures;
                        }
                    });

        }
    }
    public void cleanUpInternalRoutesOnDpn(final BigInteger dpnId, final long vpnId, final String rd,
                                           final String localNextHopIp, final String remoteNextHopIp) {
        LOG.trace(  "cleanUpInternalRoutesOnDpn : cleanup remote routes on dpn {} for vpn {}, rd {}, " +
                        " localNexthopIp {} , remoteNexhtHopIp {}",
                dpnId, vpnId, rd, localNextHopIp, remoteNextHopIp);
        InstanceIdentifier<VrfTables> id = buildVrfId(rd);
        final VpnInstanceOpDataEntry vpnInstance = getVpnInstance(rd);
        final Optional<VrfTables> vrfTable = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (vrfTable.isPresent()) {
            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
            dataStoreCoordinator.enqueueJob("FIB-" + vpnId + "-" + dpnId.toString(),
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            List<ListenableFuture<Void>> futures = new ArrayList<>();
                            synchronized (vpnInstance.getVpnInstanceName().intern()) {
                                WriteTransaction writeTransaction = dataBroker.newWriteOnlyTransaction();
                                for (VrfEntry vrfEntry : vrfTable.get().getVrfEntry()) {
                                    // Handle Internal Routes only (i.e, STATIC for now)
                                    if (RouteOrigin.value(vrfEntry.getOrigin()) == RouteOrigin.STATIC) {
                                        SubnetRoute subnetRoute = vrfEntry.getAugmentation(SubnetRoute.class);
                                        /* Ignore SubnetRoute entry */
                                        if (subnetRoute == null) {
                                            if (!vrfEntry.getNextHopAddressList().isEmpty()) {
                                                if (remoteNextHopIp.trim().equals(vrfEntry.getNextHopAddressList().get(0).trim())) {
                                                    LOG.trace(" deleting remote FIB entry {}", vrfEntry);
                                                    deleteRemoteRoute(null, dpnId, vpnId, vrfTable.get().getKey(), vrfEntry, writeTransaction);
                                                }
                                            }
                                        }
                                    }
                                }
                                futures.add(writeTransaction.submit());
                            }
                            return futures;
                        }
                    });
        }
    }

    public static InstanceIdentifier<VrfTables> buildVrfId(String rd) {
        InstanceIdentifierBuilder<VrfTables> idBuilder =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd));
        InstanceIdentifier<VrfTables> id = idBuilder.build();
        return id;
    }

    private String getFlowRef(BigInteger dpnId, short tableId, long label, int priority) {
        return new StringBuilder(64).append(FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR).append(label).append(NwConstants.FLOWID_SEPARATOR)
                .append(priority).toString();
    }

    String getFlowRef(BigInteger dpnId, short tableId, String rd, int priority, InetAddress destPrefix) {
        return new StringBuilder(64).append(FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR)
                .append(rd).append(NwConstants.FLOWID_SEPARATOR)
                .append(priority).append(NwConstants.FLOWID_SEPARATOR)
                .append(destPrefix.getHostAddress()).toString();
    }

    private String getInterVpnFibFlowRef(String interVpnLinkName, String prefix, String nextHop ) {
        return new StringBuilder(64).append(FLOWID_PREFIX)
                .append(interVpnLinkName).append(NwConstants.FLOWID_SEPARATOR)
                .append(prefix).append(NwConstants.FLOWID_SEPARATOR)
                .append(nextHop).toString();
    }

    protected List<AdjacencyResult> resolveAdjacency(final BigInteger remoteDpnId, final long vpnId,
                                            final VrfEntry vrfEntry, String rd) {
        List<AdjacencyResult> adjacencyList = new ArrayList<>();
        List<String> prefixIpList = new ArrayList<>();
        LOG.trace("resolveAdjacency called with remotedDpnId {}, vpnId{}, VrfEntry {}",
                remoteDpnId, vpnId, vrfEntry);
        try {
            if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.BGP) {
                Extraroute extra_route = getVpnToExtraroute(rd, vrfEntry.getDestPrefix());
                if (extra_route == null) {
                    prefixIpList = Arrays.asList(vrfEntry.getDestPrefix());
                } else {
                    prefixIpList = new ArrayList<>();
                    for (String extraRouteIp : extra_route.getNexthopIpList()) {
                        prefixIpList.add(extraRouteIp + "/32");
                    }
                }
            } else {
                prefixIpList = Arrays.asList(vrfEntry.getDestPrefix());
            }

            for (String prefixIp : prefixIpList) {
                for (String nextHopIp : vrfEntry.getNextHopAddressList()) {
                    LOG.debug("NextHop IP for destination {} is {}", prefixIp, nextHopIp);
                    AdjacencyResult adjacencyResult = nextHopManager.getRemoteNextHopPointer(remoteDpnId, vpnId,
                            prefixIp, nextHopIp);
                    if (adjacencyResult != null && !adjacencyList.contains(adjacencyResult)) {
                        adjacencyList.add(adjacencyResult);
                    }
                }
            }
        } catch (NullPointerException e) {
            LOG.trace("", e);
        }
        return adjacencyList;
    }

    protected VpnInstanceOpDataEntry getVpnInstance(String rd) {
        InstanceIdentifier<VpnInstanceOpDataEntry> id =
                InstanceIdentifier.create(VpnInstanceOpData.class)
                        .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(rd));
        Optional<VpnInstanceOpDataEntry> vpnInstanceOpData =
                FibUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        return vpnInstanceOpData.isPresent() ? vpnInstanceOpData.get() : null;
    }

    String getTableMissFlowRef(BigInteger dpnId, short tableId, int tableMiss) {
        return new StringBuffer().append(FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR).append(tableMiss)
                .append(FLOWID_PREFIX).toString();
    }

    /*
     * Install flow entry in protocol table to forward mpls
     * coming through gre tunnel to LFIB table.
     */
    private void makeProtocolTableFlow(BigInteger dpnId, int addOrRemove) {
        final BigInteger COOKIE_PROTOCOL_TABLE = new BigInteger("1070000", 16);
        // Instruction to goto L3 InterfaceTable
        List<InstructionInfo> instructions = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[] {NwConstants.L3_LFIB_TABLE}));
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_MPLS_UC }));
        FlowEntity flowEntityToLfib = MDSALUtil.buildFlowEntity(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE,
                getTableMissFlowRef(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE,
                        NwConstants.L3_LFIB_TABLE),
                DEFAULT_FIB_FLOW_PRIORITY,
                "Protocol Table For LFIB",
                0, 0,
                COOKIE_PROTOCOL_TABLE,
                matches, instructions);

        if (addOrRemove == NwConstants.ADD_FLOW) {
            LOG.debug("Invoking MDSAL to install Protocol Entries for dpn {}", dpnId);
            mdsalManager.installFlow(flowEntityToLfib);
        } else {
            mdsalManager.removeFlow(flowEntityToLfib);
        }
    }

    public List<String> printFibEntries() {
        List<String> result = new ArrayList<>();
        result.add(String.format("   %-7s  %-20s  %-20s  %-7s  %-7s", "RD", "Prefix", "NextHop", "Label", "Origin"));
        result.add("-------------------------------------------------------------------");
        InstanceIdentifier<FibEntries> id = InstanceIdentifier.create(FibEntries.class);
        Optional<FibEntries> fibEntries = FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (fibEntries.isPresent()) {
            List<VrfTables> vrfTables = fibEntries.get().getVrfTables();
            for (VrfTables vrfTable : vrfTables) {
                for (VrfEntry vrfEntry : vrfTable.getVrfEntry()) {
                    for (String nextHop : vrfEntry.getNextHopAddressList()) {
                        result.add(String.format("   %-7s  %-20s  %-20s  %-7s  %-7s",
                                vrfTable.getRouteDistinguisher(),
                                vrfEntry.getDestPrefix(), nextHop, vrfEntry.getLabel(), vrfEntry.getOrigin()));
                    }
                    if (vrfEntry.getNextHopAddressList().isEmpty()) {
                        result.add(String.format("   %-7s  %-20s  %-20s  %-7s  %-7s",
                                vrfTable.getRouteDistinguisher(),
                                vrfEntry.getDestPrefix(), "local", vrfEntry.getLabel(), vrfEntry.getOrigin()));
                    }
                }
            }
        }
        return result;
    }


    private VrfEntry getVrfEntry(DataBroker broker, String rd, String ipPrefix) {
        InstanceIdentifier<VrfEntry> vrfEntryId =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).
                        child(VrfEntry.class, new VrfEntryKey(ipPrefix)).build();
        Optional<VrfEntry> vrfEntry = read(broker, LogicalDatastoreType.CONFIGURATION, vrfEntryId);
        if (vrfEntry.isPresent())  {
            return vrfEntry.get();
        }
        return null;
    }

    private InstanceIdentifier<VrfEntry> getVrfEntryId(String rd, String ipPrefix) {
        InstanceIdentifier<VrfEntry> vrfEntryId =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).
                        child(VrfEntry.class, new VrfEntryKey(ipPrefix)).build();
        return vrfEntryId;
    }

    protected Boolean isIpv4Address(String ipAddress) {
        try {
            InetAddress address = InetAddress.getByName(ipAddress);
            if (address instanceof Inet4Address) {
                return true;
            }
        } catch (UnknownHostException e) {
            LOG.warn("Invalid ip address {}", ipAddress, e);
            return false;
        }
        return false;
    }

    protected Boolean installRouterFibEntries(final VrfEntry vrfEntry, final Collection<VpnToDpnList> vpnToDpnList,
            long vpnId, int addOrRemove) {
        RouterInterface routerInt = vrfEntry.getAugmentation(RouterInterface.class);
        if (routerInt != null && vpnToDpnList != null) {
            String routerId = routerInt.getUuid();
            String macAddress = vrfEntry.getMacAddress();
            String ipValue = vrfEntry.getDestPrefix();
            LOG.trace("createFibEntries - Router augmented vrfentry found for for router uuid:{}, ip:{}, mac:{}",
                    routerId, ipValue, macAddress);
            for (VpnToDpnList vpnDpn : vpnToDpnList) {
                if (vpnDpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                    installRouterFibEntry(vrfEntry, vpnDpn.getDpnId(), vpnId, routerId, ipValue,
                            new MacAddress(macAddress), addOrRemove);
                }
            }
            return true;
        }
        return false;
    }

    public void installRouterFibEntry(final VrfEntry vrfEntry, BigInteger dpnId, long vpnId, String routerUuid,
                                      String routerInternalIp, MacAddress routerMac, int addOrRemove) {
        String[] subSplit = routerInternalIp.split("/");
        if (!isIpv4Address(subSplit[0])) {
            // Ping responder using OpenFlow rules is only supported for IPv4, hence skipping.
            return;
        }

        String addRemoveStr = (addOrRemove == NwConstants.ADD_FLOW) ? "ADD_FLOW" : "DELETE_FLOW";
        LOG.trace("{}: bulding Echo Flow entity for dpid:{}, router_ip:{}, vpnId:{}, subSplit:{} ", addRemoveStr,
                dpnId, routerInternalIp, vpnId, subSplit[0]);

        List<MatchInfo> matches = new ArrayList<>();

        matches.add(new MatchInfo(MatchFieldType.ip_proto, new long[] { IPProtocols.ICMP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { MetaDataUtil.getVpnIdMetadata(vpnId), MetaDataUtil.METADATA_MASK_VRFID }));
        matches.add(new MatchInfo(MatchFieldType.icmp_v4, new long[] { (short) 8, (short) 0 }));
        matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] { NwConstants.ETHTYPE_IPV4 }));
        matches.add(new MatchInfo(MatchFieldType.ipv4_destination, new String[] { subSplit[0], "32" }));

        List<ActionInfo> actionsInfos = new ArrayList<>();

        // Set Eth Src and Eth Dst
        actionsInfos.add(new ActionInfo(ActionType.move_src_dst_eth, new String[] {}));
        actionsInfos.add(new ActionInfo(ActionType.set_field_eth_src, new String[] { routerMac.getValue() }));

        // Move Ip Src to Ip Dst
        actionsInfos.add(new ActionInfo(ActionType.move_src_dst_ip, new String[] {}));
        actionsInfos.add(new ActionInfo(ActionType.set_source_ip, new String[] { subSplit[0], "32" }));

        // Set the ICMP type to 0 (echo reply)
        actionsInfos.add(new ActionInfo(ActionType.set_icmp_type, new String[] { "0" }));

        actionsInfos.add(new ActionInfo(ActionType.nx_load_in_port, new BigInteger[]{ BigInteger.ZERO }));

        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit,
                new String[] { Short.toString(NwConstants.L3_FIB_TABLE) }));

        List<InstructionInfo> instructions = new ArrayList<>();

        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));

        int priority = FibConstants.DEFAULT_FIB_FLOW_PRIORITY + FibConstants.DEFAULT_PREFIX_LENGTH;
        String flowRef = getFlowRef(dpnId, NwConstants.L3_FIB_TABLE, vrfEntry.getLabel(), priority);

        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpnId, NwConstants.L3_FIB_TABLE, flowRef, priority, flowRef,
                0, 0, NwConstants.COOKIE_VM_FIB_TABLE, matches, instructions);

        if (addOrRemove == NwConstants.ADD_FLOW) {
            mdsalManager.installFlow(flowEntity);
        } else {
            mdsalManager.removeFlow(flowEntity);
        }
    }

    public void removeInterVPNLinkRouteFlows(final String interVpnLinkName,
                                             final boolean isVpnFirstEndPoint,
                                             final VrfEntry vrfEntry)
    {
        Preconditions.checkArgument(vrfEntry.getNextHopAddressList() != null
                                    && vrfEntry.getNextHopAddressList().size() == 1);
        Optional<InterVpnLinkState> interVpnLinkState = FibUtil.getInterVpnLinkState(dataBroker, interVpnLinkName);

        if ( !interVpnLinkState.isPresent()) {
            LOG.warn("Could not find State for InterVpnLink {}", interVpnLinkName);
            return;
        }

        List<BigInteger> targetDpns =
            isVpnFirstEndPoint ? interVpnLinkState.get().getFirstEndpointState().getDpId()
            : interVpnLinkState.get().getSecondEndpointState().getDpId();

        String nextHop = vrfEntry.getNextHopAddressList().get(0);

        // delete from FIB
        //
        String flowRef = getInterVpnFibFlowRef(interVpnLinkName, vrfEntry.getDestPrefix(), nextHop);
        FlowKey flowKey = new FlowKey(new FlowId(flowRef));
        Flow flow = new FlowBuilder().setKey(flowKey).setId(new FlowId(flowRef)).setTableId(NwConstants.L3_FIB_TABLE)
            .setFlowName(flowRef).build();

        LOG.trace("Removing flow in FIB table for interVpnLink {} key {}",
                  interVpnLinkName, flowRef);

        for ( BigInteger dpId : targetDpns ) {
            LOG.debug("Removing flow: VrfEntry=[prefix={} label={} nexthop={}] dpn {} for InterVpnLink {} in FIB",
                      vrfEntry.getDestPrefix(), vrfEntry.getLabel(), nextHop,
                      dpId, interVpnLinkName);

            mdsalManager.removeFlow(dpId, flow);
        }

        // delete from LFIB
        //
        LOG.trace("Removing flow in FIB table for interVpnLink {}", interVpnLinkName);

        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        for ( BigInteger dpId : targetDpns ) {
            LOG.debug("Removing flow: VrfEntry=[prefix={} label={} nexthop={}] dpn {} for InterVpnLink {} in LFIB",
                      vrfEntry.getDestPrefix(), vrfEntry.getLabel(), nextHop,
                      dpId, interVpnLinkName);
            makeLFibTableEntry(dpId, vrfEntry.getLabel(), null /* no instructions */,
                               LFIB_INTERVPN_PRIORITY, NwConstants.DEL_FLOW, tx);
        }
        tx.submit();
    }
}
