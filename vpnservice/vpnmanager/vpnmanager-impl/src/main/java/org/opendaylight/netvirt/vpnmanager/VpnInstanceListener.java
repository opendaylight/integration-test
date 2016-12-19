/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;

import com.google.common.util.concurrent.ThreadFactoryBuilder;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NWUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnAfConfig;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.VpnTargets;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTarget;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.ExternalTunnelList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.external.tunnel.list.ExternalTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.DcGatewayIpList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.dc.gateway.ip.list.DcGatewayIp;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnTargetsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;

import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpntargets.VpnTargetBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpntargets.VpnTargetKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.Vpn;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.opendaylight.genius.mdsalutil.NwConstants.COOKIE_VM_FIB_TABLE;
import static org.opendaylight.genius.mdsalutil.NwConstants.L3VPN_SERVICE_NAME;

public class VpnInstanceListener extends AsyncDataTreeChangeListenerBase<VpnInstance, VpnInstanceListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(VpnInstanceListener.class);
    private final DataBroker dataBroker;
    private final IBgpManager bgpManager;
    private final IdManagerService idManager;
    private final VpnInterfaceManager vpnInterfaceManager;
    private final IFibManager fibManager;
    private final VpnOpDataSyncer vpnOpDataNotifier;
    private final IMdsalApiManager mdsalManager;
    private final short VPN_VNI_DEMUX_TABLE = 1850; //TODO Move existing L3VPN tables and make this table 20
    private static final int DEFAULT_FIB_FLOW_PRIORITY = 10;

    public VpnInstanceListener(final DataBroker dataBroker, final IBgpManager bgpManager,
                               final IdManagerService idManager,
                               final VpnInterfaceManager vpnInterfaceManager,
                               final IFibManager fibManager,
                               final VpnOpDataSyncer vpnOpDataSyncer,
                               final IMdsalApiManager mdsalManager) {
        super(VpnInstance.class, VpnInstanceListener.class);
        this.dataBroker = dataBroker;
        this.bgpManager = bgpManager;
        this.idManager = idManager;
        this.vpnInterfaceManager = vpnInterfaceManager;
        this.fibManager = fibManager;
        this.vpnOpDataNotifier = vpnOpDataSyncer;
        this.mdsalManager = mdsalManager;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<VpnInstance> getWildCardPath() {
        return InstanceIdentifier.create(VpnInstances.class).child(VpnInstance.class);
    }

    @Override
    protected VpnInstanceListener getDataTreeChangeListener() {
        return VpnInstanceListener.this;
    }

    private void waitForOpRemoval(String rd, String vpnName) {
        //wait till DCN for update on VPN Instance Op Data signals that vpn interfaces linked to this vpn instance is zero
        //TODO(vpnteam): Entire code would need refactoring to listen only on the parent object - VPNInstance
        VpnInstanceOpDataEntry vpnOpEntry = null;
        Long intfCount = 0L;
        Long currentIntfCount = 0L;
        Integer retryCount = 3;
        long timeout = VpnConstants.MIN_WAIT_TIME_IN_MILLISECONDS;
        Optional<VpnInstanceOpDataEntry> vpnOpValue = null;
        vpnOpValue = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                                  VpnUtil.getVpnInstanceOpDataIdentifier(rd));

        if ((vpnOpValue != null) && (vpnOpValue.isPresent())) {
            vpnOpEntry = vpnOpValue.get();
            List<VpnToDpnList> dpnToVpns = vpnOpEntry.getVpnToDpnList();
            if (dpnToVpns != null) {
                for (VpnToDpnList dpn : dpnToVpns) {
                    if (dpn.getVpnInterfaces() != null) {
                        intfCount = intfCount + dpn.getVpnInterfaces().size();
                    }
                }
            }
            //intfCount = vpnOpEntry.getVpnInterfaceCount();
            while (true) {
                if (intfCount > 0) {
                    // Minimum wait time of 5 seconds for one VPN Interface clearance (inclusive of full trace on)
                    timeout = intfCount * VpnConstants.MIN_WAIT_TIME_IN_MILLISECONDS;
                    // Maximum wait time of 90 seconds for all VPN Interfaces clearance (inclusive of full trace on)
                    if (timeout > VpnConstants.MAX_WAIT_TIME_IN_MILLISECONDS) {
                        timeout = VpnConstants.MAX_WAIT_TIME_IN_MILLISECONDS;
                    }
                    LOG.info("VPNInstance removal count of interface at {} for for rd {}, vpnname {}",
                            intfCount, rd, vpnName);
                }
                LOG.info("VPNInstance removal thread waiting for {} seconds for rd {}, vpnname {}",
                        (timeout / 1000), rd, vpnName);

                try {
                    Thread.sleep(timeout);
                } catch (InterruptedException e) {
                }

                // Check current interface count
                vpnOpValue = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(rd));
                if ((vpnOpValue != null) && (vpnOpValue.isPresent())) {
                    vpnOpEntry = vpnOpValue.get();
                    dpnToVpns = vpnOpEntry.getVpnToDpnList();
                    currentIntfCount = 0L;
                    if (dpnToVpns != null) {
                        for (VpnToDpnList dpn : dpnToVpns) {
                            if (dpn.getVpnInterfaces() != null) {
                                currentIntfCount = currentIntfCount + dpn.getVpnInterfaces().size();
                            }
                        }
                    }
                    if ((currentIntfCount == 0) || (currentIntfCount >= intfCount)) {
                        // Either the FibManager completed its job to cleanup all vpnInterfaces in VPN
                        // OR
                        // There is no progress by FibManager in removing all the interfaces even after good time!
                        // In either case, let us quit and take our chances.
                        //TODO(vpnteam): L3VPN refactoring to take care of this case.
                        if ((dpnToVpns == null) || dpnToVpns.size() <= 0) {
                            LOG.info("VPN Instance vpn {} rd {} ready for removal, exiting wait loop", vpnName, rd);
                            break;
                        } else {
                            if (retryCount > 0) {
                                retryCount--;
                                LOG.info("Retrying clearing vpn with vpnname {} rd {} since current interface count {} ", vpnName, rd, currentIntfCount);
                                if (currentIntfCount > 0) {
                                    intfCount = currentIntfCount;
                                } else {
                                    LOG.info("Current interface count is zero, but instance Op for vpn {} and rd {} not cleared yet. Waiting for 5 more seconds.", vpnName, rd);
                                    intfCount = 1L;
                                }
                            } else {
                                LOG.info("VPNInstance bailing out of wait loop as current interface count is {} and max retries exceeded for for vpnName {}, rd {}",
                                        currentIntfCount, vpnName, rd);
                                break;
                            }
                        }
                    }
                } else {
                    // There is no VPNOPEntry.  Something else happened on the system !
                    // So let us quit and take our chances.
                    //TODO(vpnteam): L3VPN refactoring to take care of this case.
                    break;
                }
            }
        }
        LOG.info("Returned out of waiting for  Op Data removal for rd {}, vpnname {}", rd, vpnName);
    }
    @Override
    protected void remove(InstanceIdentifier<VpnInstance> identifier, VpnInstance del) {
        LOG.trace("Remove VPN event key: {}, value: {}", identifier, del);
        final String vpnName = del.getVpnInstanceName();
        final String rd = del.getIpv4Family().getRouteDistinguisher();
        Optional<VpnInstanceOpDataEntry> vpnOpValue = null;

        //TODO(vpnteam): Entire code would need refactoring to listen only on the parent object - VPNInstance
        try {
            if ((rd != null) && (!rd.isEmpty())) {
                vpnOpValue = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(rd));
            } else {
                vpnOpValue = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(vpnName));
            }
        } catch (Exception e) {
            LOG.error("Exception when attempting to retrieve VpnInstanceOpDataEntry for VPN {}. ", vpnName, e);
            return;
        }

        if (vpnOpValue == null || !vpnOpValue.isPresent()) {
            LOG.error("Unable to retrieve VpnInstanceOpDataEntry for VPN {}. ", vpnName);
            return;
        }

        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob("VPN-" + vpnName,
                new DeleteVpnInstanceWorker(idManager, dataBroker, del));
    }

    private class DeleteVpnInstanceWorker implements Callable<List<ListenableFuture<Void>>> {
        IdManagerService idManager;
        DataBroker broker;
        VpnInstance vpnInstance;

        public DeleteVpnInstanceWorker(IdManagerService idManager,
                                       DataBroker broker,
                                       VpnInstance value) {
            this.idManager = idManager;
            this.broker = broker;
            this.vpnInstance = value;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            final String vpnName = vpnInstance.getVpnInstanceName();
            final String rd = vpnInstance.getIpv4Family().getRouteDistinguisher();
            final long vpnId = VpnUtil.getVpnId(broker, vpnName);
            WriteTransaction writeTxn = broker.newWriteOnlyTransaction();
            if ((rd != null) && (!rd.isEmpty())) {
                waitForOpRemoval(rd, vpnName);
            } else {
                waitForOpRemoval(vpnName, vpnName);
            }

            // Clean up VpnInstanceToVpnId from Config DS
            VpnUtil.removeVpnIdToVpnInstance(broker, vpnId, writeTxn);
            VpnUtil.removeVpnInstanceToVpnId(broker, vpnName, writeTxn);
            LOG.trace("Removed vpnIdentifier for  rd{} vpnname {}", rd, vpnName);
            if (rd != null) {
                synchronized (vpnName.intern()) {
                    fibManager.removeVrfTable(broker, rd, null);
                }
                try {
                    bgpManager.deleteVrf(rd, false);
                } catch (Exception e) {
                    LOG.error("Exception when removing VRF from BGP for RD {} in VPN {} exception " + e, rd, vpnName);
                }

                // Clean up VPNExtraRoutes Operational DS
                InstanceIdentifier<Vpn> vpnToExtraroute = VpnUtil.getVpnToExtrarouteIdentifier(rd);
                Optional<Vpn> optVpnToExtraroute = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, vpnToExtraroute);
                if (optVpnToExtraroute.isPresent()) {
                    VpnUtil.removeVpnExtraRouteForVpn(broker, rd, writeTxn);
                }

                // Clean up VPNInstanceOpDataEntry
                VpnUtil.removeVpnOpInstance(broker, rd, writeTxn);
            } else {
                // Clean up FIB Entries Config DS
                synchronized (vpnName.intern()) {
                    fibManager.removeVrfTable(broker, vpnName, null);
                }
                // Clean up VPNExtraRoutes Operational DS
                InstanceIdentifier<Vpn> vpnToExtraroute = VpnUtil.getVpnToExtrarouteIdentifier(vpnName);
                Optional<Vpn> optVpnToExtraroute = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, vpnToExtraroute);
                if (optVpnToExtraroute.isPresent()) {
                    VpnUtil.removeVpnExtraRouteForVpn(broker, vpnName, writeTxn);
                }

                // Clean up VPNInstanceOpDataEntry
                VpnUtil.removeVpnOpInstance(broker, vpnName, writeTxn);
            }
            // Clean up PrefixToInterface Operational DS
            VpnUtil.removePrefixToInterfaceForVpnId(broker, vpnId, writeTxn);

            // Clean up L3NextHop Operational DS
            VpnUtil.removeL3nexthopForVpnId(broker, vpnId, writeTxn);

            // Release the ID used for this VPN back to IdManager
            VpnUtil.releaseId(idManager, VpnConstants.VPN_IDPOOL_NAME, vpnName);

            List<ListenableFuture<Void>> futures = new ArrayList<>();
            futures.add(writeTxn.submit());
            return futures;
        }
    }

    @Override
    protected void update(InstanceIdentifier<VpnInstance> identifier,
                          VpnInstance original, VpnInstance update) {
        LOG.trace("Update VPN event key: {}, value: {}", identifier, update);
    }

    @Override
    protected void add(final InstanceIdentifier<VpnInstance> identifier, final VpnInstance value) {
        LOG.trace("Add VPN event key: {}, value: {}", identifier, value);
        final String vpnName = value.getVpnInstanceName();

        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob("VPN-" + vpnName,
                new AddVpnInstanceWorker(idManager, vpnInterfaceManager, dataBroker, value));
    }

    private class AddVpnInstanceWorker implements Callable<List<ListenableFuture<Void>>> {
        IdManagerService idManager;
        VpnInterfaceManager vpnInterfaceManager;
        VpnInstance vpnInstance;
        DataBroker broker;

        public AddVpnInstanceWorker(IdManagerService idManager,
                                    VpnInterfaceManager vpnInterfaceManager,
                                    DataBroker broker,
                                    VpnInstance value) {
            this.idManager = idManager;
            this.vpnInterfaceManager = vpnInterfaceManager;
            this.broker = broker;
            this.vpnInstance = value;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            // If another renderer(for eg : CSS) needs to be supported, check can be performed here
            // to call the respective helpers.
            final VpnAfConfig config = vpnInstance.getIpv4Family();
            final String rd = config.getRouteDistinguisher();
            WriteTransaction writeConfigTxn = broker.newWriteOnlyTransaction();
            WriteTransaction writeOperTxn = broker.newWriteOnlyTransaction();
            addVpnInstance(vpnInstance, writeConfigTxn, writeOperTxn);
            CheckedFuture<Void, TransactionCommitFailedException> checkFutures = writeOperTxn.submit();
            try {
                checkFutures.get();
            } catch (InterruptedException | ExecutionException e) {
                LOG.error("Error creating vpn {} ", vpnInstance.getVpnInstanceName());
                throw new RuntimeException(e.getMessage());
            }
            List<ListenableFuture<Void>> futures = new ArrayList<>();
            futures.add(writeConfigTxn.submit());
            ListenableFuture<List<Void>> listenableFuture = Futures.allAsList(futures);
            Futures.addCallback(listenableFuture,
                    new PostAddVpnInstanceWorker(config , vpnInstance.getVpnInstanceName()));

            final long vpnId = VpnUtil.getVpnId(dataBroker, vpnInstance.getVpnInstanceName());


            // bind service on each tunnel interface
            //TODO (KIRAN): Add a new listener to handle creation of new DC-GW binding and deletion of existing DC-GW.
            if (VpnUtil.isL3VpnOverVxLan(vpnInstance.getL3vni())) { //Handled for L3VPN Over VxLAN
                for ( String tunnelInterfaceName: getDcGatewayTunnelInterfaceNameList() )
                    bindService( vpnInstance.getVpnInstanceName(), tunnelInterfaceName );

                // install flow
                List<MatchInfo> mkMatches = new ArrayList<>();
                mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] { BigInteger.valueOf(vpnInstance.getL3vni()) }));

                BigInteger[] metadata = new BigInteger[] { MetaDataUtil.getVpnIdMetadata(vpnId), MetaDataUtil.METADATA_MASK_VRFID };

                List<Instruction> instructions =
                        Arrays.asList(new InstructionInfo(InstructionType.write_metadata, metadata).buildInstruction(0),
                                new InstructionInfo(InstructionType.goto_table,
                                        new long[] { NwConstants.L3_FIB_TABLE }).buildInstruction(1));

                String flowRef = getFibFlowRef( vpnInstance.getVpnInstanceName(), vpnId);
                Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.L3_GW_MAC_TABLE, flowRef, DEFAULT_FIB_FLOW_PRIORITY, flowRef, 0, 0,
                        COOKIE_VM_FIB_TABLE, mkMatches, instructions);


                for ( BigInteger dpnId: NWUtil.getOperativeDPNs( dataBroker ) )
                    mdsalManager.installFlow( dpnId, flowEntity );

                ///////////////////////
            }
            return futures;
        }
    }

    private void addVpnInstance(VpnInstance value, WriteTransaction writeConfigTxn,
                                WriteTransaction writeOperTxn) {
        VpnAfConfig config = value.getIpv4Family();
        String rd = config.getRouteDistinguisher();
        String vpnInstanceName = value.getVpnInstanceName();

        long vpnId = VpnUtil.getUniqueId(idManager, VpnConstants.VPN_IDPOOL_NAME, vpnInstanceName);
        if (vpnId == 0) {
            LOG.error("Unable to fetch label from Id Manager. Bailing out of adding operational data for Vpn Instance {}", value.getVpnInstanceName());
            LOG.error("Unable to fetch label from Id Manager. Bailing out of adding operational data for Vpn Instance {}", value.getVpnInstanceName());
            return;
        }
        LOG.info("VPN Id {} generated for VpnInstanceName {}", vpnId, vpnInstanceName);
        org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance
                vpnInstanceToVpnId = VpnUtil.getVpnInstanceToVpnId(vpnInstanceName, vpnId, (rd != null) ? rd
                : vpnInstanceName);

        if (writeConfigTxn != null) {
            writeConfigTxn.put(LogicalDatastoreType.CONFIGURATION,
                    VpnUtil.getVpnInstanceToVpnIdIdentifier(vpnInstanceName),
                    vpnInstanceToVpnId, true);
        } else {
             TransactionUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                     VpnUtil.getVpnInstanceToVpnIdIdentifier(vpnInstanceName),
                     vpnInstanceToVpnId, TransactionUtil.DEFAULT_CALLBACK);
        }

        VpnIds vpnIdToVpnInstance = VpnUtil.getVpnIdToVpnInstance(vpnId, value.getVpnInstanceName(),
                (rd != null) ? rd : value.getVpnInstanceName(), (rd != null)/*isExternalVpn*/);

        if (writeConfigTxn != null) {
            writeConfigTxn.put(LogicalDatastoreType.CONFIGURATION,
                    VpnUtil.getVpnIdToVpnInstanceIdentifier(vpnId),
                    vpnIdToVpnInstance, true);
        } else {
             TransactionUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                     VpnUtil.getVpnIdToVpnInstanceIdentifier(vpnId),
                     vpnIdToVpnInstance, TransactionUtil.DEFAULT_CALLBACK);
        }

        try {
            String cachedTransType = fibManager.getConfTransType();
            if (cachedTransType.equals("Invalid")) {
                try {
                    fibManager.setConfTransType("L3VPN", "VXLAN");
                } catch (Exception e) {
                    LOG.error("Exception caught setting the L3VPN tunnel transportType", e);
                }
            } else {
                LOG.trace("Configured tunnel transport type for L3VPN as {}", cachedTransType);
            }
        } catch (Exception e) {
            LOG.error("Error when trying to retrieve tunnel transport type for L3VPN ", e);
        }
        VpnInstanceOpDataEntryBuilder builder =
                new VpnInstanceOpDataEntryBuilder().setVpnId(vpnId)
                        .setVpnInstanceName(vpnInstanceName);

        if (rd == null) {
            builder.setVrfId(vpnInstanceName);
            if (writeOperTxn != null) {
                writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(vpnInstanceName),
                        builder.build(), true);
            } else {
                 TransactionUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL,
                         VpnUtil.getVpnInstanceOpDataIdentifier(vpnInstanceName),
                         builder.build(), TransactionUtil.DEFAULT_CALLBACK);
            }
        } else {
            builder.setVrfId(rd);
            if (value.getL3vni() != null) {
                builder.setL3vni(value.getL3vni());
            }
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpntargets.VpnTarget> opVpnTargetList = new ArrayList<>();
            VpnTargets vpnTargets = config.getVpnTargets();
            if (vpnTargets != null) {
                List<VpnTarget> vpnTargetList = vpnTargets.getVpnTarget();
                if (vpnTargetList != null) {
                    for (VpnTarget vpnTarget : vpnTargetList) {
                        VpnTargetBuilder vpnTargetBuilder = new VpnTargetBuilder().setKey(new VpnTargetKey(vpnTarget.getKey().getVrfRTValue()))
                                        .setVrfRTType(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn
                                                .instance.op.data.vpn.instance.op.data.entry.vpntargets.VpnTarget.VrfRTType
                                                .forValue(vpnTarget.getVrfRTType().getIntValue())).setVrfRTValue(vpnTarget.getVrfRTValue());
                        opVpnTargetList.add(vpnTargetBuilder.build());
                    }
                }
            }
            VpnTargetsBuilder vpnTargetsBuilder = new VpnTargetsBuilder().setVpnTarget(opVpnTargetList);
            builder.setVpnTargets(vpnTargetsBuilder.build());

            if (writeOperTxn != null) {
                writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(rd),
                        builder.build(), true);
            } else {
                 TransactionUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        VpnUtil.getVpnInstanceOpDataIdentifier(rd),
                        builder.build(), TransactionUtil.DEFAULT_CALLBACK);
            }
        }
        LOG.info("VpnInstanceOpData populated successfully for vpn {} rd {}", vpnInstanceName, rd);
    }

    private class PostAddVpnInstanceWorker implements FutureCallback<List<Void>> {
        VpnAfConfig config;
        String vpnName;

        public PostAddVpnInstanceWorker(VpnAfConfig config, String vpnName)  {
            this.config = config;
            this.vpnName = vpnName;
        }

        /**
         * @param voids
         * This implies that all the future instances have returned success. -- TODO: Confirm this
         */
        @Override
        public void onSuccess(List<Void> voids) {
            /*
            if rd is null, then its either a router vpn instance (or) a vlan external network vpn instance.
            if rd is non-null, then it is a bgpvpn instance
             */
            String rd = config.getRouteDistinguisher();
            if ((rd == null) || addBgpVrf(voids)) {
                notifyTask();
            }
        }

        private boolean addBgpVrf(List<Void> voids) {
            String rd = config.getRouteDistinguisher();
            List<VpnTarget> vpnTargetList = config.getVpnTargets().getVpnTarget();

            List<String> ertList = new ArrayList<String>();
            List<String> irtList = new ArrayList<String>();

            if (vpnTargetList != null) {
                for (VpnTarget vpnTarget : vpnTargetList) {
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.ExportExtcommunity) {
                        ertList.add(vpnTarget.getVrfRTValue());
                    }
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.ImportExtcommunity) {
                        irtList.add(vpnTarget.getVrfRTValue());
                    }
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.Both) {
                        ertList.add(vpnTarget.getVrfRTValue());
                        irtList.add(vpnTarget.getVrfRTValue());
                    }
                }
            } else {
                LOG.error("vpn target list is empty, cannot add BGP VPN {} VRF {}", this.vpnName, rd);
                return false;
            }
            try {
                bgpManager.addVrf(rd, irtList, ertList);
            } catch (Exception e) {
                LOG.error("Exception when adding VRF to BGP", e);
                return false;
            }
            vpnInterfaceManager.handleVpnsExportingRoutes(this.vpnName, rd);
            return true;
        }

        private void notifyTask() {
            vpnOpDataNotifier.notifyVpnOpDataReady(VpnOpDataSyncer.VpnOpDataType.vpnInstanceToId, vpnName);
            vpnOpDataNotifier.notifyVpnOpDataReady(VpnOpDataSyncer.VpnOpDataType.vpnOpData, vpnName);
        }
        /**
         *
         * @param throwable
         * This method is used to handle failure callbacks.
         * If more retry needed, the retrycount is decremented and mainworker is executed again.
         * After retries completed, rollbackworker is executed.
         * If rollbackworker fails, this is a double-fault. Double fault is logged and ignored.
         */

        @Override
        public void onFailure(Throwable throwable) {
            LOG.warn("Job: failed with exception: ", throwable);
        }
    }

    public boolean isVPNConfigured() {

        InstanceIdentifier<VpnInstances> vpnsIdentifier = InstanceIdentifier.builder(VpnInstances.class).build();
        Optional<VpnInstances> optionalVpns = TransactionUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                vpnsIdentifier);
        if (!optionalVpns.isPresent() ||
                optionalVpns.get().getVpnInstance() == null ||
                optionalVpns.get().getVpnInstance().isEmpty()) {
            LOG.trace("No VPNs configured.");
            return false;
        }
        LOG.trace("VPNs are configured on the system.");
        return true;
    }

    protected VpnInstanceOpDataEntry getVpnInstanceOpData(String rd) {
        InstanceIdentifier<VpnInstanceOpDataEntry> id = VpnUtil.getVpnInstanceOpDataIdentifier(rd);
        Optional<VpnInstanceOpDataEntry> vpnInstanceOpData =
                TransactionUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if(vpnInstanceOpData.isPresent()) {
            return vpnInstanceOpData.get();
        }
        return null;
    }

    private void bindService( final String vpnInstanceName, final String tunnelInterfaceName ) {
        final int priority = VpnConstants.DEFAULT_FLOW_PRIORITY;

        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
        dataStoreCoordinator.enqueueJob(tunnelInterfaceName,
                new Callable<List<ListenableFuture<Void>>>() {
                    @Override
                    public List<ListenableFuture<Void>> call() throws Exception {
                        WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
                        int instructionKey = 0;
                        List<Instruction> instructions = new ArrayList<Instruction>();

                        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(VPN_VNI_DEMUX_TABLE, ++instructionKey));

                        BoundServices
                                serviceInfo =
                                InterfaceUtils.getBoundServices(String.format("%s.%s.%s", "vpn",vpnInstanceName, tunnelInterfaceName),
                                        ServiceIndex.getIndex(L3VPN_SERVICE_NAME, VPN_VNI_DEMUX_TABLE), priority,
                                        NwConstants.COOKIE_VM_INGRESS_TABLE, instructions);
                        writeTxn.put(LogicalDatastoreType.CONFIGURATION,
                                InterfaceUtils.buildServiceId(tunnelInterfaceName, ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME, NwConstants.L3VPN_SERVICE_INDEX)), serviceInfo, true);
                        List<ListenableFuture<Void>> futures = new ArrayList<ListenableFuture<Void>>();
                        futures.add(writeTxn.submit());
                        return futures;
                    }
                });
    }


    private List<String> getDcGatewayTunnelInterfaceNameList()
    {
        List<String> tunnelInterfaceNameList = new ArrayList<>();

        InstanceIdentifier<DcGatewayIpList> dcGatewayIpListInstanceIdentifier = InstanceIdentifier.create(DcGatewayIpList.class);
        Optional<DcGatewayIpList> dcGatewayIpListOptional = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, dcGatewayIpListInstanceIdentifier);
        List<DcGatewayIp> dcGatewayIps = dcGatewayIpListOptional.get().getDcGatewayIp();

        InstanceIdentifier<ExternalTunnelList> externalTunnelListId = InstanceIdentifier.create(ExternalTunnelList.class);

        Optional<ExternalTunnelList> externalTunnelListOptional = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, externalTunnelListId);
        if (externalTunnelListOptional.isPresent()) {
            List<ExternalTunnel> externalTunnels = externalTunnelListOptional.get().getExternalTunnel();

            List<String> externalTunnelIpList = new ArrayList<>();
            for ( ExternalTunnel externalTunnel: externalTunnels )
                externalTunnelIpList.add( externalTunnel.getDestinationDevice() );

            List<String> dcGatewayIpList = new ArrayList<>();
            for ( DcGatewayIp dcGatewayIp: dcGatewayIps )
                dcGatewayIpList.add( dcGatewayIp.getIpAddress().getIpv4Address().toString() );

            // Find all externalTunnelIps present in dcGateWayIpList
            List<String> externalTunnelIpsInDcGatewayIpList = new ArrayList<>();
            for ( String externalTunnelIp: externalTunnelIpList )
                for ( String dcGateWayIp: dcGatewayIpList )
                    if ( externalTunnelIp.contentEquals(dcGateWayIp) )
                        externalTunnelIpsInDcGatewayIpList.add(externalTunnelIp);


            for ( String externalTunnelIpsInDcGatewayIp: externalTunnelIpsInDcGatewayIpList )
                for ( ExternalTunnel externalTunnel: externalTunnels )
                    if ( externalTunnel.getDestinationDevice().contentEquals( externalTunnelIpsInDcGatewayIp) )
                        tunnelInterfaceNameList.add(externalTunnel.getTunnelInterfaceName());

        }

        return tunnelInterfaceNameList;
    }

    private String getFibFlowRef(String vpnInstanceName, long vpnId ) {
        return new StringBuilder(64)
                .append(vpnInstanceName).append(NwConstants.FLOWID_SEPARATOR)
                .append(vpnId).toString();
    }
}
