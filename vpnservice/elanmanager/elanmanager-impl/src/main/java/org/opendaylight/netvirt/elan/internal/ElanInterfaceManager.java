/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import com.google.common.util.concurrent.ListenableFuture;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentMap;

import org.apache.commons.lang3.StringUtils;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.itm.globals.ITMConstants;
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
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.elan.ElanException;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.utils.ElanConstants;
import org.opendaylight.netvirt.elan.utils.ElanForwardingEntriesHandler;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.external.tunnel.list.ExternalTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.group.buckets.Bucket;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.groups.Group;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface.EtreeInterfaceType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeLeafTagName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanDpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanForwardingTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan._interface.forwarding.entries.ElanInterfaceMac;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan._interface.forwarding.entries.ElanInterfaceMacBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan._interface.forwarding.entries.ElanInterfaceMacKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.ElanDpnInterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.forwarding.tables.MacTable;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.forwarding.tables.MacTableKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstanceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.state.Elan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.state.ElanBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.state.ElanKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Class in charge of handling creations, modifications and removals of
 * ElanInterfaces.
 *
 * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface
 */
@SuppressWarnings("deprecation")
public class ElanInterfaceManager extends AsyncDataTreeChangeListenerBase<ElanInterface, ElanInterfaceManager>
        implements AutoCloseable {

    private final DataBroker broker;
    private final IMdsalApiManager mdsalManager;
    private final IInterfaceManager interfaceManager;
    private final IdManagerService idManager;
    private final ElanForwardingEntriesHandler elanForwardingEntriesHandler;
    private ElanL2GatewayUtils elanL2GatewayUtils;
    private ElanUtils elanUtils;

    private static final long WAIT_TIME_FOR_SYNC_INSTALL = Long.getLong("wait.time.sync.install", 300L);

    private Map<String, ConcurrentLinkedQueue<ElanInterface>> unProcessedElanInterfaces = new ConcurrentHashMap<>();

    private static final Logger LOG = LoggerFactory.getLogger(ElanInterfaceManager.class);

    public ElanInterfaceManager(final DataBroker dataBroker,
                                final IdManagerService managerService,
                                final IMdsalApiManager mdsalApiManager,
                                IInterfaceManager interfaceManager,
                                final ElanForwardingEntriesHandler elanForwardingEntriesHandler) {
        super(ElanInterface.class, ElanInterfaceManager.class);
        this.broker = dataBroker;
        this.idManager = managerService;
        this.mdsalManager = mdsalApiManager;
        this.interfaceManager = interfaceManager;
        this.elanForwardingEntriesHandler = elanForwardingEntriesHandler;
    }

    public void setElanUtils(ElanUtils elanUtils) {
        this.elanUtils = elanUtils;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
        this.elanForwardingEntriesHandler.setElanUtils(elanUtils);
    }

    @Override
    public void init() {
        registerListener(LogicalDatastoreType.CONFIGURATION, broker);
    }

    @Override
    protected InstanceIdentifier<ElanInterface> getWildCardPath() {
        return InstanceIdentifier.create(ElanInterfaces.class).child(ElanInterface.class);
    }

    @Override
    protected void remove(InstanceIdentifier<ElanInterface> identifier, ElanInterface del) {
        String interfaceName = del.getName();
        ElanInstance elanInfo = ElanUtils.getElanInstanceByName(broker, del.getElanInstanceName());
        /*
         * Handling in case the elan instance is deleted.If the Elan instance is
         * deleted, there is no need to explicitly delete the elan interfaces
         */
        if (elanInfo == null) {
            return;
        }
        InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
        String elanInstanceName = elanInfo.getElanInstanceName();
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        InterfaceRemoveWorkerOnElan configWorker = new InterfaceRemoveWorkerOnElan(elanInstanceName, elanInfo,
                interfaceName, interfaceInfo, false, this);
        coordinator.enqueueJob(elanInstanceName, configWorker, ElanConstants.JOB_MAX_RETRIES);
    }

    public void removeElanInterface(List<ListenableFuture<Void>> futures, ElanInstance elanInfo, String interfaceName,
            InterfaceInfo interfaceInfo, boolean isInterfaceStateRemoved) {
        String elanName = elanInfo.getElanInstanceName();
        boolean isLastElanInterface = false;
        boolean isLastInterfaceOnDpn = false;
        BigInteger dpId = null;
        long elanTag = elanInfo.getElanTag();
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        WriteTransaction deleteFlowGroupTx = broker.newWriteOnlyTransaction();
        Elan elanState = removeElanStateForInterface(elanInfo, interfaceName, tx);
        if (elanState == null) {
            return;
        }
        List<String> elanInterfaces = elanState.getElanInterfaces();
        if (elanInterfaces.size() == 0) {
            isLastElanInterface = true;
        }
        if (interfaceInfo != null) {
            dpId = interfaceInfo.getDpId();
            DpnInterfaces dpnInterfaces = removeElanDpnInterfaceFromOperationalDataStore(elanName, dpId, interfaceName,
                    elanTag, tx);
            /*
             * If there are not elan ports, remove the unknown dmac, terminating
             * service table flows, remote/local bc group
             */
            if (dpnInterfaces == null || dpnInterfaces.getInterfaces() == null
                    || dpnInterfaces.getInterfaces().isEmpty()) {
                // No more Elan Interfaces in this DPN
                LOG.debug("deleting the elan: {} present on dpId: {}", elanInfo.getElanInstanceName(), dpId);
                removeDefaultTermFlow(dpId, elanInfo.getElanTag());
                removeUnknownDmacFlow(dpId, elanInfo, deleteFlowGroupTx, elanInfo.getElanTag());
                removeEtreeUnknownDmacFlow(dpId, elanInfo, deleteFlowGroupTx);
                removeElanBroadcastGroup(elanInfo, interfaceInfo, deleteFlowGroupTx);
                removeLocalBroadcastGroup(elanInfo, interfaceInfo, deleteFlowGroupTx);
                removeEtreeBroadcastGrups(elanInfo, interfaceInfo, deleteFlowGroupTx);
                if (ElanUtils.isVxlan(elanInfo)) {
                    unsetExternalTunnelTable(dpId, elanInfo);
                }
                isLastInterfaceOnDpn = true;
            } else {
                setupLocalBroadcastGroups(elanInfo, dpnInterfaces, interfaceInfo);
            }
        }
        futures.add(ElanUtils.waitForTransactionToComplete(tx));
        futures.add(ElanUtils.waitForTransactionToComplete(deleteFlowGroupTx));
        if (isLastInterfaceOnDpn && dpId != null && ElanUtils.isVxlan(elanInfo)) {
            setElanBCGrouponOtherDpns(elanInfo, dpId);
        }
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        InterfaceRemoveWorkerOnElanInterface removeInterfaceWorker = new InterfaceRemoveWorkerOnElanInterface(
                interfaceName, elanInfo, interfaceInfo, isInterfaceStateRemoved, this, isLastElanInterface);
        coordinator.enqueueJob(interfaceName, removeInterfaceWorker, ElanConstants.JOB_MAX_RETRIES);
    }

    private void removeEtreeUnknownDmacFlow(BigInteger dpId, ElanInstance elanInfo,
            WriteTransaction deleteFlowGroupTx) {
        EtreeLeafTagName etreeLeafTag = elanUtils.getEtreeLeafTagByElanTag(elanInfo.getElanTag());
        if (etreeLeafTag != null) {
            long leafTag = etreeLeafTag.getEtreeLeafTag().getValue();
            removeUnknownDmacFlow(dpId, elanInfo, deleteFlowGroupTx, leafTag);
        }
    }

    private void removeEtreeBroadcastGrups(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        removeLeavesEtreeBroadcastGroup(elanInfo, interfaceInfo, deleteFlowGroupTx);
        removeLeavesLocalBroadcastGroup(elanInfo, interfaceInfo, deleteFlowGroupTx);
    }

    private void removeLeavesLocalBroadcastGroup(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
        if (etreeInstance != null) {
            BigInteger dpnId = interfaceInfo.getDpId();
            long groupId = ElanUtils.getEtreeLeafLocalBCGId(etreeInstance.getEtreeLeafTagVal().getValue());
            List<Bucket> listBuckets = new ArrayList<>();
            int bucketId = 0;
            listBuckets.add(getLocalBCGroupBucketInfo(interfaceInfo, bucketId));
            Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                    MDSALUtil.buildBucketLists(listBuckets));
            LOG.trace("deleted the localBroadCast Group:{}", group);
            mdsalManager.removeGroupToTx(dpnId, group, deleteFlowGroupTx);
        }
    }

    private void removeLeavesEtreeBroadcastGroup(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
        if (etreeInstance != null) {
            long etreeTag = etreeInstance.getEtreeLeafTagVal().getValue();
            int bucketId = 0;
            int actionKey = 0;
            List<Bucket> listBuckets = new ArrayList<>();
            List<Action> listAction = new ArrayList<>();
            listAction.add(new ActionInfo(ActionType.group,
                    new String[] { String.valueOf(ElanUtils.getEtreeLeafLocalBCGId(etreeTag)) }, ++actionKey)
                            .buildAction());
            listBuckets.add(MDSALUtil.buildBucket(listAction, MDSALUtil.GROUP_WEIGHT, bucketId, MDSALUtil.WATCH_PORT,
                    MDSALUtil.WATCH_GROUP));
            bucketId++;
            listBuckets.addAll(getRemoteBCGroupBucketInfos(elanInfo, bucketId, interfaceInfo, etreeTag));
            BigInteger dpnId = interfaceInfo.getDpId();
            long groupId = ElanUtils.getEtreeLeafRemoteBCGId(etreeTag);
            Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                    MDSALUtil.buildBucketLists(listBuckets));
            LOG.trace("deleting the remoteBroadCast group:{}", group);
            mdsalManager.removeGroupToTx(dpnId, group, deleteFlowGroupTx);
        }
    }

    private Elan removeElanStateForInterface(ElanInstance elanInfo, String interfaceName, WriteTransaction tx) {
        String elanName = elanInfo.getElanInstanceName();
        Elan elanState = ElanUtils.getElanByName(broker, elanName);
        if (elanState == null) {
            return elanState;
        }
        List<String> elanInterfaces = elanState.getElanInterfaces();
        elanInterfaces.remove(interfaceName);
        if (elanInterfaces.isEmpty()) {
            tx.delete(LogicalDatastoreType.OPERATIONAL, ElanUtils.getElanInstanceOperationalDataPath(elanName));
            tx.delete(LogicalDatastoreType.OPERATIONAL, ElanUtils.getElanMacTableOperationalDataPath(elanName));
            tx.delete(LogicalDatastoreType.OPERATIONAL,
                    ElanUtils.getElanInfoEntriesOperationalDataPath(elanInfo.getElanTag()));
        } else {
            Elan updateElanState = new ElanBuilder().setElanInterfaces(elanInterfaces).setName(elanName)
                    .setKey(new ElanKey(elanName)).build();
            tx.put(LogicalDatastoreType.OPERATIONAL, ElanUtils.getElanInstanceOperationalDataPath(elanName),
                    updateElanState);
        }
        return elanState;
    }

    private void deleteElanInterfaceFromConfigDS(String interfaceName, WriteTransaction tx) {
        // removing the ElanInterface from the config data_store if interface is
        // not present in Interface config DS
        if (interfaceManager.getInterfaceInfoFromConfigDataStore(interfaceName) == null) {
            tx.delete(LogicalDatastoreType.CONFIGURATION,
                    ElanUtils.getElanInterfaceConfigurationDataPathId(interfaceName));
        }
    }

    void removeEntriesForElanInterface(List<ListenableFuture<Void>> futures, ElanInstance elanInfo,
            InterfaceInfo interfaceInfo, String interfaceName, boolean isInterfaceStateRemoved,
            boolean isLastElanInterface) {
        String elanName = elanInfo.getElanInstanceName();
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        WriteTransaction deleteFlowGroupTx = broker.newWriteOnlyTransaction();
        InstanceIdentifier<ElanInterfaceMac> elanInterfaceId = ElanUtils
                .getElanInterfaceMacEntriesOperationalDataPath(interfaceName);
        LOG.debug("Removing the Interface:{} from elan:{}", interfaceName, elanName);
        if (interfaceInfo != null) {
            Optional<ElanInterfaceMac> existingElanInterfaceMac = elanUtils.read(broker,
                    LogicalDatastoreType.OPERATIONAL, elanInterfaceId);
            if (existingElanInterfaceMac.isPresent()) {
                List<PhysAddress> macAddresses = new ArrayList<>();
                List<MacEntry> existingMacEntries = existingElanInterfaceMac.get().getMacEntry();
                List<MacEntry> macEntries = new ArrayList<>();
                if (existingMacEntries != null && !existingMacEntries.isEmpty()) {
                    macEntries.addAll(existingMacEntries);
                }
                if (!macEntries.isEmpty()) {
                    for (MacEntry macEntry : macEntries) {
                        LOG.debug("removing the  mac-entry:{} present on elanInterface:{}",
                                macEntry.getMacAddress().getValue(), interfaceName);
                        InstanceIdentifier<MacTable> elanMacTableId = ElanUtils
                                .getElanMacTableOperationalDataPath(elanName);
                        Optional<MacTable> existingElanMacTable =
                                elanUtils.read(broker, LogicalDatastoreType.OPERATIONAL, elanMacTableId);
                        if (!isLastElanInterface && existingElanMacTable.isPresent()) {
                            tx.delete(LogicalDatastoreType.OPERATIONAL,
                                    ElanUtils.getMacEntryOperationalDataPath(elanName, macEntry.getMacAddress()));
                        }
                        elanUtils.deleteMacFlows(elanInfo, interfaceInfo, macEntry, deleteFlowGroupTx);
                        macAddresses.add(macEntry.getMacAddress());
                    }

                    // Removing all those MACs from External Devices belonging
                    // to this ELAN
                    if (ElanUtils.isVxlan(elanInfo)) {
                        elanL2GatewayUtils.removeMacsFromElanExternalDevices(elanInfo, macAddresses);
                    }
                }
            }
            removeDefaultTermFlow(interfaceInfo.getDpId(), interfaceInfo.getInterfaceTag());
            removeFilterEqualsTable(elanInfo, interfaceInfo, deleteFlowGroupTx);
        } else {
            // Interface does not exist in ConfigDS, so lets remove everything
            // about that interface related to Elan
            ElanInterfaceMac elanInterfaceMac = elanUtils.getElanInterfaceMacByInterfaceName(interfaceName);
            if (elanInterfaceMac != null && elanInterfaceMac.getMacEntry() != null) {
                List<MacEntry> macEntries = elanInterfaceMac.getMacEntry();
                for (MacEntry macEntry : macEntries) {
                    tx.delete(LogicalDatastoreType.OPERATIONAL,
                            ElanUtils.getMacEntryOperationalDataPath(elanName, macEntry.getMacAddress()));
                }
            }
        }
        tx.delete(LogicalDatastoreType.OPERATIONAL, elanInterfaceId);
        if (!isInterfaceStateRemoved) {
            unbindService(elanInfo, interfaceName, tx);
        }
        deleteElanInterfaceFromConfigDS(interfaceName, tx);
        futures.add(ElanUtils.waitForTransactionToComplete(tx));
        futures.add(ElanUtils.waitForTransactionToComplete(deleteFlowGroupTx));
    }

    private DpnInterfaces removeElanDpnInterfaceFromOperationalDataStore(String elanName, BigInteger dpId,
            String interfaceName, long elanTag, WriteTransaction tx) {
        DpnInterfaces dpnInterfaces = elanUtils.getElanInterfaceInfoByElanDpn(elanName, dpId);
        if (dpnInterfaces != null) {
            List<String> interfaceLists = dpnInterfaces.getInterfaces();
            interfaceLists.remove(interfaceName);

            if (interfaceLists == null || interfaceLists.isEmpty()) {
                deleteAllRemoteMacsInADpn(elanName, dpId, elanTag);
                deleteElanDpnInterface(elanName, dpId, tx);
            } else {
                dpnInterfaces = updateElanDpnInterfacesList(elanName, dpId, interfaceLists, tx);
            }
        }
        return dpnInterfaces;
    }

    private void deleteAllRemoteMacsInADpn(String elanName, BigInteger dpId, long elanTag) {
        List<DpnInterfaces> dpnInterfaces = elanUtils.getInvolvedDpnsInElan(elanName);
        for (DpnInterfaces dpnInterface : dpnInterfaces) {
            BigInteger currentDpId = dpnInterface.getDpId();
            if (!currentDpId.equals(dpId)) {
                for (String elanInterface : dpnInterface.getInterfaces()) {
                    ElanInterfaceMac macs = elanUtils.getElanInterfaceMacByInterfaceName(elanInterface);
                    if (macs == null || macs.getMacEntry() == null) {
                        continue;
                    }
                    for (MacEntry mac : macs.getMacEntry()) {
                        removeTheMacFlowInTheDPN(dpId, elanTag, currentDpId, mac);
                        removeEtreeMacFlowInTheDPN(dpId, elanTag, currentDpId, mac);
                    }
                }
            }
        }
    }

    private void removeEtreeMacFlowInTheDPN(BigInteger dpId, long elanTag, BigInteger currentDpId, MacEntry mac) {
        EtreeLeafTagName etreeLeafTag = elanUtils.getEtreeLeafTagByElanTag(elanTag);
        if (etreeLeafTag != null) {
            removeTheMacFlowInTheDPN(dpId, etreeLeafTag.getEtreeLeafTag().getValue(), currentDpId, mac);
        }
    }

    private void removeTheMacFlowInTheDPN(BigInteger dpId, long elanTag, BigInteger currentDpId, MacEntry mac) {
        mdsalManager
                .removeFlow(dpId,
                        MDSALUtil.buildFlow(NwConstants.ELAN_DMAC_TABLE,
                                ElanUtils.getKnownDynamicmacFlowRef(NwConstants.ELAN_DMAC_TABLE, dpId, currentDpId,
                                        mac.getMacAddress().getValue(), elanTag)));
    }

    @Override
    protected void update(InstanceIdentifier<ElanInterface> identifier, ElanInterface original, ElanInterface update) {
        // updating the static-Mac Entries for the existing elanInterface
        String elanName = update.getElanInstanceName();
        String interfaceName = update.getName();
        List<PhysAddress> existingPhysAddress = original.getStaticMacEntries();
        List<PhysAddress> updatedPhysAddress = update.getStaticMacEntries();
        if (updatedPhysAddress != null && !updatedPhysAddress.isEmpty()) {
            List<PhysAddress> existingClonedPhyAddress = new ArrayList<>();
            if (existingPhysAddress != null && !existingPhysAddress.isEmpty()) {
                existingClonedPhyAddress.addAll(0, existingPhysAddress);
                existingPhysAddress.removeAll(updatedPhysAddress);
                updatedPhysAddress.removeAll(existingClonedPhyAddress);
                // removing the PhyAddress which are not presented in the
                // updated List
                for (PhysAddress physAddress : existingPhysAddress) {
                    removeInterfaceStaticMacEntires(elanName, interfaceName, physAddress);
                }
            }
            // Adding the new PhysAddress which are presented in the updated
            // List
            if (updatedPhysAddress.size() > 0) {
                for (PhysAddress physAddress : updatedPhysAddress) {
                    InstanceIdentifier<MacEntry> macId = getMacEntryOperationalDataPath(elanName, physAddress);
                    Optional<MacEntry> existingMacEntry = elanUtils.read(broker,
                            LogicalDatastoreType.OPERATIONAL, macId);
                    WriteTransaction tx = broker.newWriteOnlyTransaction();
                    if (existingMacEntry.isPresent()) {
                        elanForwardingEntriesHandler.updateElanInterfaceForwardingTablesList(
                                elanName, interfaceName, existingMacEntry.get().getInterface(), existingMacEntry.get(),
                                tx);
                    } else {
                        elanForwardingEntriesHandler.addElanInterfaceForwardingTableList(
                                ElanUtils.getElanInstanceByName(broker, elanName), interfaceName, physAddress, tx);
                    }
                    ElanUtils.waitForTransactionToComplete(tx);
                }
            }
        } else if (existingPhysAddress != null && !existingPhysAddress.isEmpty()) {
            for (PhysAddress physAddress : existingPhysAddress) {
                removeInterfaceStaticMacEntires(elanName, interfaceName, physAddress);
            }
        }
    }

    @Override
    protected void add(InstanceIdentifier<ElanInterface> identifier, ElanInterface elanInterfaceAdded) {
        String elanInstanceName = elanInterfaceAdded.getElanInstanceName();
        String interfaceName = elanInterfaceAdded.getName();
        InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
        if (interfaceInfo == null) {
            LOG.warn("Interface {} is removed from Interface Oper DS due to port down ", interfaceName);
            return;
        }
        ElanInstance elanInstance = ElanUtils.getElanInstanceByName(broker, elanInstanceName);

        if (elanInstance == null) {
            elanInstance = new ElanInstanceBuilder().setElanInstanceName(elanInstanceName)
                    .setDescription(elanInterfaceAdded.getDescription()).build();
            // Add the ElanInstance in the Configuration data-store
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            List<String> elanInterfaces = new ArrayList<>();
            elanInterfaces.add(interfaceName);
            ElanUtils.updateOperationalDataStore(broker, idManager,
                    elanInstance, elanInterfaces, tx);
            ElanUtils.waitForTransactionToComplete(tx);
            elanInstance = ElanUtils.getElanInstanceByName(broker, elanInstanceName);
        }

        Long elanTag = elanInstance.getElanTag();
        // If elan tag is not updated, then put the elan interface into
        // unprocessed entry map and entry. Let entries
        // in this map get processed during ELAN update DCN.
        if (elanTag == null) {
            ConcurrentLinkedQueue<ElanInterface> elanInterfaces = unProcessedElanInterfaces.get(elanInstanceName);
            if (elanInterfaces == null) {
                elanInterfaces = new ConcurrentLinkedQueue<>();
            }
            elanInterfaces.add(elanInterfaceAdded);
            unProcessedElanInterfaces.put(elanInstanceName, elanInterfaces);
            return;
        }
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        InterfaceAddWorkerOnElan addWorker = new InterfaceAddWorkerOnElan(elanInstanceName, elanInterfaceAdded,
                interfaceInfo, elanInstance, this);
        coordinator.enqueueJob(elanInstanceName, addWorker, ElanConstants.JOB_MAX_RETRIES);
    }

    void handleunprocessedElanInterfaces(ElanInstance elanInstance) throws ElanException {
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        Queue<ElanInterface> elanInterfaces = unProcessedElanInterfaces.get(elanInstance.getElanInstanceName());
        if (elanInterfaces == null || elanInterfaces.isEmpty()) {
            return;
        }
        for (ElanInterface elanInterface : elanInterfaces) {
            String interfaceName = elanInterface.getName();
            InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
            addElanInterface(futures, elanInterface, interfaceInfo, elanInstance);
        }
    }

    void programRemoteDmacFlow(ElanInstance elanInstance, InterfaceInfo interfaceInfo,
            WriteTransaction writeFlowGroupTx) throws ElanException {
        ElanDpnInterfacesList elanDpnInterfacesList = elanUtils
                .getElanDpnInterfacesList(elanInstance.getElanInstanceName());
        List<DpnInterfaces> dpnInterfaceLists = null;
        if (elanDpnInterfacesList != null) {
            dpnInterfaceLists = elanDpnInterfacesList.getDpnInterfaces();
        }
        if (dpnInterfaceLists == null) {
            dpnInterfaceLists = new ArrayList<>();
        }
        for (DpnInterfaces dpnInterfaces : dpnInterfaceLists) {
            if (dpnInterfaces.getDpId().equals(interfaceInfo.getDpId())) {
                continue;
            }
            List<String> remoteElanInterfaces = dpnInterfaces.getInterfaces();
            for (String remoteIf : remoteElanInterfaces) {
                ElanInterfaceMac elanIfMac = elanUtils.getElanInterfaceMacByInterfaceName(remoteIf);
                InterfaceInfo remoteInterface = interfaceManager.getInterfaceInfo(remoteIf);
                if (elanIfMac == null) {
                    continue;
                }
                List<MacEntry> remoteMacEntries = elanIfMac.getMacEntry();
                if (remoteMacEntries != null) {
                    for (MacEntry macEntry : remoteMacEntries) {
                        PhysAddress physAddress = macEntry.getMacAddress();
                        elanUtils.setupRemoteDmacFlow(interfaceInfo.getDpId(), remoteInterface.getDpId(),
                                remoteInterface.getInterfaceTag(), elanInstance.getElanTag(), physAddress.getValue(),
                                elanInstance.getElanInstanceName(), writeFlowGroupTx, remoteIf, elanInstance);
                    }
                }
            }
        }
    }

    void addElanInterface(List<ListenableFuture<Void>> futures, ElanInterface elanInterface,
            InterfaceInfo interfaceInfo, ElanInstance elanInstance) throws ElanException {
        Preconditions.checkNotNull(elanInstance, "elanInstance cannot be null");
        Preconditions.checkNotNull(interfaceInfo, "interfaceInfo cannot be null");
        Preconditions.checkNotNull(elanInterface, "elanInterface cannot be null");

        String interfaceName = elanInterface.getName();
        String elanInstanceName = elanInterface.getElanInstanceName();

        Elan elanInfo = ElanUtils.getElanByName(broker, elanInstanceName);
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        if (elanInfo == null) {
            List<String> elanInterfaces = new ArrayList<>();
            elanInterfaces.add(interfaceName);
            ElanUtils.updateOperationalDataStore(broker, idManager,
                    elanInstance, elanInterfaces, tx);
        } else {
            createElanStateList(elanInstanceName, interfaceName, tx);
        }
        boolean isFirstInterfaceInDpn = false;
        // Specific actions to the DPN where the ElanInterface has been added,
        // for example, programming the
        // External tunnel table if needed or adding the ElanInterface to the
        // DpnInterfaces in the operational DS.
        BigInteger dpId = interfaceInfo != null ? dpId = interfaceInfo.getDpId() : null;
        DpnInterfaces dpnInterfaces = null;
        if (dpId != null && !dpId.equals(ElanConstants.INVALID_DPN)) {
            InstanceIdentifier<DpnInterfaces> elanDpnInterfaces = ElanUtils
                    .getElanDpnInterfaceOperationalDataPath(elanInstanceName, dpId);
            Optional<DpnInterfaces> existingElanDpnInterfaces = elanUtils.read(broker,
                    LogicalDatastoreType.OPERATIONAL, elanDpnInterfaces);
            if (!existingElanDpnInterfaces.isPresent()) {
                isFirstInterfaceInDpn = true;
                // ELAN's 1st ElanInterface added to this DPN
                dpnInterfaces = createElanInterfacesList(elanInstanceName, interfaceName, dpId, tx);
                // The 1st ElanInterface in a DPN must program the Ext Tunnel
                // table, but only if Elan has VNI
                if (ElanUtils.isVxlan(elanInstance)) {
                    setExternalTunnelTable(dpId, elanInstance);
                }
                elanL2GatewayUtils.installElanL2gwDevicesLocalMacsInDpn(dpId, elanInstance, interfaceName);
            } else {
                List<String> elanInterfaces = existingElanDpnInterfaces.get().getInterfaces();
                elanInterfaces.add(interfaceName);
                if (elanInterfaces.size() == 1) { // 1st dpn interface
                    elanL2GatewayUtils.installElanL2gwDevicesLocalMacsInDpn(dpId, elanInstance, interfaceName);
                }
                dpnInterfaces = updateElanDpnInterfacesList(elanInstanceName, dpId, elanInterfaces, tx);
            }
        }

        // add code to install Local/Remote BC group, unknow DMAC entry,
        // terminating service table flow entry
        // call bindservice of interfacemanager to create ingress table flow
        // enty.
        // Add interface to the ElanInterfaceForwardingEntires Container
        createElanInterfaceTablesList(interfaceName, tx);
        if (interfaceInfo != null) {
            installEntriesForFirstInterfaceonDpn(elanInstance, interfaceInfo, dpnInterfaces, isFirstInterfaceInDpn, tx);
        }
        futures.add(ElanUtils.waitForTransactionToComplete(tx));
        if (isFirstInterfaceInDpn && ElanUtils.isVxlan(elanInstance)) {
            //update the remote-DPNs remoteBC group entry with Tunnels
            setElanBCGrouponOtherDpns(elanInstance, dpId);
        }

        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        InterfaceAddWorkerOnElanInterface addWorker = new InterfaceAddWorkerOnElanInterface(interfaceName,
                elanInterface, interfaceInfo, elanInstance, isFirstInterfaceInDpn, this);
        coordinator.enqueueJob(interfaceName, addWorker, ElanConstants.JOB_MAX_RETRIES);
    }

    void setupEntriesForElanInterface(List<ListenableFuture<Void>> futures, ElanInstance elanInstance,
            ElanInterface elanInterface, InterfaceInfo interfaceInfo, boolean isFirstInterfaceInDpn)
            throws ElanException {
        String elanInstanceName = elanInstance.getElanInstanceName();
        String interfaceName = elanInterface.getName();
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        BigInteger dpId = interfaceInfo.getDpId();
        WriteTransaction writeFlowGroupTx = broker.newWriteOnlyTransaction();
        installEntriesForElanInterface(elanInstance, interfaceInfo, isFirstInterfaceInDpn, tx, writeFlowGroupTx);
        List<PhysAddress> staticMacAddresses = elanInterface.getStaticMacEntries();
        if (staticMacAddresses != null) {
            boolean isInterfaceOperational = isOperational(interfaceInfo);
            for (PhysAddress physAddress : staticMacAddresses) {
                InstanceIdentifier<MacEntry> macId = getMacEntryOperationalDataPath(elanInstanceName, physAddress);
                Optional<MacEntry> existingMacEntry = elanUtils.read(broker,
                        LogicalDatastoreType.OPERATIONAL, macId);
                if (existingMacEntry.isPresent()) {
                    elanForwardingEntriesHandler.updateElanInterfaceForwardingTablesList(
                            elanInstanceName, interfaceName, existingMacEntry.get().getInterface(),
                            existingMacEntry.get(), tx);
                } else {
                    elanForwardingEntriesHandler
                            .addElanInterfaceForwardingTableList(elanInstance, interfaceName, physAddress, tx);
                }

                if (isInterfaceOperational) {
                    // Setting SMAC, DMAC, UDMAC in this DPN and also in other
                    // DPNs
                    elanUtils.setupMacFlows(elanInstance, interfaceInfo, ElanConstants.STATIC_MAC_TIMEOUT,
                            physAddress.getValue(), writeFlowGroupTx);
                }
            }

            if (isInterfaceOperational) {
                // Add MAC in TOR's remote MACs via OVSDB. Outside of the loop
                // on purpose.
                elanL2GatewayUtils.scheduleAddDpnMacInExtDevices(elanInstance.getElanInstanceName(), dpId,
                        staticMacAddresses);
            }
        }
        futures.add(ElanUtils.waitForTransactionToComplete(tx));
        futures.add(ElanUtils.waitForTransactionToComplete(writeFlowGroupTx));
    }

    protected void removeInterfaceStaticMacEntires(String elanInstanceName, String interfaceName,
            PhysAddress physAddress) {
        InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
        InstanceIdentifier<MacEntry> macId = getMacEntryOperationalDataPath(elanInstanceName, physAddress);
        Optional<MacEntry> existingMacEntry = elanUtils.read(broker,
                LogicalDatastoreType.OPERATIONAL, macId);

        if (!existingMacEntry.isPresent()) {
            return;
        }

        MacEntry macEntry = new MacEntryBuilder().setMacAddress(physAddress).setInterface(interfaceName)
                .setKey(new MacEntryKey(physAddress)).build();
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        elanForwardingEntriesHandler.deleteElanInterfaceForwardingEntries(
                ElanUtils.getElanInstanceByName(broker, elanInstanceName), interfaceInfo, macEntry, tx);
        elanForwardingEntriesHandler.deleteElanInterfaceMacForwardingEntries(interfaceName,
                physAddress, tx);
        ElanUtils.waitForTransactionToComplete(tx);
    }

    private InstanceIdentifier<MacEntry> getMacEntryOperationalDataPath(String elanName, PhysAddress physAddress) {
        return InstanceIdentifier.builder(ElanForwardingTables.class).child(MacTable.class, new MacTableKey(elanName))
                .child(MacEntry.class, new MacEntryKey(physAddress)).build();
    }

    private void installEntriesForElanInterface(ElanInstance elanInstance, InterfaceInfo interfaceInfo,
            boolean isFirstInterfaceInDpn, WriteTransaction tx, WriteTransaction writeFlowGroupTx)
            throws ElanException {
        if (!isOperational(interfaceInfo)) {
            return;
        }
        BigInteger dpId = interfaceInfo.getDpId();
        elanUtils.setupTermDmacFlows(interfaceInfo, mdsalManager, writeFlowGroupTx);
        setupFilterEqualsTable(elanInstance, interfaceInfo, writeFlowGroupTx);
        if (isFirstInterfaceInDpn) {
            // Terminating Service , UnknownDMAC Table.
            setupTerminateServiceTable(elanInstance, dpId, writeFlowGroupTx);
            setupUnknownDMacTable(elanInstance, dpId, writeFlowGroupTx);
            /*
             * Install remote DMAC flow. This is required since this DPN is
             * added later to the elan instance and remote DMACs of other
             * interfaces in this elan instance are not present in the current
             * dpn.
             */
            programRemoteDmacFlow(elanInstance, interfaceInfo, writeFlowGroupTx);
        }
        // bind the Elan service to the Interface
        bindService(elanInstance,
                ElanUtils.getElanInterfaceByElanInterfaceName(broker, interfaceInfo.getInterfaceName()), tx);
    }

    public void installEntriesForFirstInterfaceonDpn(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            DpnInterfaces dpnInterfaces, boolean isFirstInterfaceInDpn, WriteTransaction tx) {
        if (!isOperational(interfaceInfo)) {
            return;
        }
        // LocalBroadcast Group creation with elan-Interfaces
        setupLocalBroadcastGroups(elanInfo, dpnInterfaces, interfaceInfo);
        if (isFirstInterfaceInDpn) {
            LOG.trace("waitTimeForSyncInstall is {}", WAIT_TIME_FOR_SYNC_INSTALL);
            BigInteger dpId = interfaceInfo.getDpId();
            // RemoteBroadcast Group creation
            try {
                Thread.sleep(WAIT_TIME_FOR_SYNC_INSTALL);
            } catch (InterruptedException e1) {
                LOG.warn("Error while waiting for local BC group for ELAN {} to install", elanInfo);
            }
            setupElanBroadcastGroups(elanInfo, dpnInterfaces, dpId);
            try {
                Thread.sleep(WAIT_TIME_FOR_SYNC_INSTALL);
            } catch (InterruptedException e1) {
                LOG.warn("Error while waiting for local BC group for ELAN {} to install", elanInfo);
            }
        }
    }

    public void setupFilterEqualsTable(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction writeFlowGroupTx) {
        int ifTag = interfaceInfo.getInterfaceTag();
        Flow flow = MDSALUtil.buildFlowNew(NwConstants.ELAN_FILTER_EQUALS_TABLE,
                getFlowRef(NwConstants.ELAN_FILTER_EQUALS_TABLE, ifTag), 9, elanInfo.getElanInstanceName(), 0, 0,
                ElanConstants.COOKIE_ELAN_FILTER_EQUALS.add(BigInteger.valueOf(ifTag)),
                getTunnelIdMatchForFilterEqualsLPortTag(ifTag),
                elanUtils.getInstructionsInPortForOutGroup(interfaceInfo.getInterfaceName()));

        mdsalManager.addFlowToTx(interfaceInfo.getDpId(), flow, writeFlowGroupTx);

        Flow flowEntry = MDSALUtil.buildFlowNew(NwConstants.ELAN_FILTER_EQUALS_TABLE,
                getFlowRef(NwConstants.ELAN_FILTER_EQUALS_TABLE, 1000 + ifTag), 10, elanInfo.getElanInstanceName(), 0,
                0, ElanConstants.COOKIE_ELAN_FILTER_EQUALS.add(BigInteger.valueOf(ifTag)),
                getMatchesForFilterEqualsLPortTag(ifTag), MDSALUtil.buildInstructionsDrop());

        mdsalManager.addFlowToTx(interfaceInfo.getDpId(), flowEntry, writeFlowGroupTx);
    }

    public void removeFilterEqualsTable(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        int ifTag = interfaceInfo.getInterfaceTag();
        Flow flow = MDSALUtil.buildFlowNew(NwConstants.ELAN_FILTER_EQUALS_TABLE,
                getFlowRef(NwConstants.ELAN_FILTER_EQUALS_TABLE, ifTag), 9, elanInfo.getElanInstanceName(), 0, 0,
                ElanConstants.COOKIE_ELAN_FILTER_EQUALS.add(BigInteger.valueOf(ifTag)),
                getTunnelIdMatchForFilterEqualsLPortTag(ifTag),
                elanUtils.getInstructionsInPortForOutGroup(interfaceInfo.getInterfaceName()));

        mdsalManager.removeFlowToTx(interfaceInfo.getDpId(), flow, deleteFlowGroupTx);

        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.ELAN_FILTER_EQUALS_TABLE,
                getFlowRef(NwConstants.ELAN_FILTER_EQUALS_TABLE, 1000 + ifTag), 10, elanInfo.getElanInstanceName(), 0,
                0, ElanConstants.COOKIE_ELAN_FILTER_EQUALS.add(BigInteger.valueOf(ifTag)),
                getMatchesForFilterEqualsLPortTag(ifTag), MDSALUtil.buildInstructionsDrop());

        mdsalManager.removeFlowToTx(interfaceInfo.getDpId(), flowEntity, deleteFlowGroupTx);
    }

    private List<Bucket> getRemoteBCGroupBucketInfos(ElanInstance elanInfo, int bucketKeyStart,
            InterfaceInfo interfaceInfo, long elanTag) {
        return getRemoteBCGroupBuckets(elanInfo, null, interfaceInfo.getDpId(), bucketKeyStart, elanTag);
    }

    private List<Bucket> getRemoteBCGroupBuckets(ElanInstance elanInfo, DpnInterfaces dpnInterfaces, BigInteger dpnId,
            int bucketId, long elanTag) {
        List<Bucket> listBucketInfo = new ArrayList<>();
        ElanDpnInterfacesList elanDpns = elanUtils.getElanDpnInterfacesList(elanInfo.getElanInstanceName());
        listBucketInfo.addAll(getRemoteBCGroupTunnelBuckets(elanDpns, dpnId, bucketId, elanTag));
        listBucketInfo.addAll(getRemoteBCGroupExternalPortBuckets(elanDpns, dpnInterfaces, dpnId,
            getNextAvailableBucketId(listBucketInfo.size())));
        listBucketInfo.addAll(getRemoteBCGroupBucketsOfElanL2GwDevices(elanInfo, dpnId,
            getNextAvailableBucketId(listBucketInfo.size())));
        return listBucketInfo;
    }

    private int getNextAvailableBucketId(int bucketSize) {
        return (bucketSize + 1);
    }

    @SuppressWarnings("checkstyle:IllegalCatch")
    private List<Bucket> getRemoteBCGroupTunnelBuckets(ElanDpnInterfacesList elanDpns, BigInteger dpnId, int bucketId,
            long elanTag) {
        List<Bucket> listBucketInfo = new ArrayList<>();
        if (elanDpns != null) {
            for (DpnInterfaces dpnInterface : elanDpns.getDpnInterfaces()) {
                if (elanUtils.isDpnPresent(dpnInterface.getDpId()) && !Objects.equals(dpnInterface.getDpId(), dpnId)
                        && dpnInterface.getInterfaces() != null && !dpnInterface.getInterfaces().isEmpty()) {
                    try {
                        List<Action> listActionInfo = elanUtils.getInternalTunnelItmEgressAction(dpnId,
                                dpnInterface.getDpId(), elanTag);
                        if (listActionInfo.isEmpty()) {
                            continue;
                        }
                        listBucketInfo.add(MDSALUtil.buildBucket(listActionInfo, MDSALUtil.GROUP_WEIGHT, bucketId,
                                MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
                        bucketId++;
                    } catch (Exception ex) {
                        LOG.error("Logical Group Interface not found between source Dpn - {}, destination Dpn - {} ",
                                dpnId, dpnInterface.getDpId(), ex);
                    }
                }
            }
        }
        return listBucketInfo;
    }

    private List<Bucket> getRemoteBCGroupExternalPortBuckets(ElanDpnInterfacesList elanDpns,
            DpnInterfaces dpnInterfaces, BigInteger dpnId, int bucketId) {
        DpnInterfaces currDpnInterfaces = dpnInterfaces != null ? dpnInterfaces : getDpnInterfaces(elanDpns, dpnId);
        if (currDpnInterfaces == null || !elanUtils.isDpnPresent(currDpnInterfaces.getDpId())
                || currDpnInterfaces.getInterfaces() == null || currDpnInterfaces.getInterfaces().isEmpty()) {
            return Collections.emptyList();
        }

        List<Bucket> listBucketInfo = new ArrayList<>();
        for (String interfaceName : currDpnInterfaces.getInterfaces()) {
            if (interfaceManager.isExternalInterface(interfaceName)) {
                List<Action> listActionInfo = elanUtils.getExternalPortItmEgressAction(interfaceName);
                if (!listActionInfo.isEmpty()) {
                    listBucketInfo.add(MDSALUtil.buildBucket(listActionInfo, MDSALUtil.GROUP_WEIGHT, bucketId,
                            MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
                    bucketId++;
                }
            }
        }
        return listBucketInfo;
    }

    private DpnInterfaces getDpnInterfaces(ElanDpnInterfacesList elanDpns, BigInteger dpnId) {
        if (elanDpns != null) {
            for (DpnInterfaces dpnInterface : elanDpns.getDpnInterfaces()) {
                if (dpnInterface.getDpId().equals(dpnId)) {
                    return dpnInterface;
                }
            }
        }
        return null;
    }

    @SuppressWarnings("checkstyle:IllegalCatch")
    private void setElanBCGrouponOtherDpns(ElanInstance elanInfo, BigInteger dpId) {
        int elanTag = elanInfo.getElanTag().intValue();
        long groupId = ElanUtils.getElanRemoteBCGId(elanTag);
        int bucketId = 0;
        ElanDpnInterfacesList elanDpns = elanUtils.getElanDpnInterfacesList(elanInfo.getElanInstanceName());
        if (elanDpns != null) {
            List<DpnInterfaces> dpnInterfaceses = elanDpns.getDpnInterfaces();
            for (DpnInterfaces dpnInterface : dpnInterfaceses) {
                List<Bucket> remoteListBucketInfo = new ArrayList<>();
                if (elanUtils.isDpnPresent(dpnInterface.getDpId()) && !Objects.equals(dpnInterface.getDpId(),dpId)
                        && dpnInterface.getInterfaces() != null && !dpnInterface.getInterfaces().isEmpty()) {
                    List<Action> listAction = new ArrayList<>();
                    int actionKey = 0;
                    listAction.add(new ActionInfo(ActionType.group,
                            new String[] { String.valueOf(ElanUtils.getElanLocalBCGId(elanTag)) }, ++actionKey)
                                    .buildAction());
                    remoteListBucketInfo.add(MDSALUtil.buildBucket(listAction, MDSALUtil.GROUP_WEIGHT, bucketId,
                            MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
                    bucketId++;
                    for (DpnInterfaces otherFes : dpnInterfaceses) {
                        if (elanUtils.isDpnPresent(otherFes.getDpId()) && !Objects.equals(otherFes.getDpId(),
                            dpnInterface.getDpId()) && otherFes.getInterfaces() != null
                            && !otherFes.getInterfaces().isEmpty()) {
                            try {
                                List<Action> remoteListActionInfo = elanUtils.getInternalTunnelItmEgressAction(
                                        dpnInterface.getDpId(), otherFes.getDpId(), elanTag);
                                if (!remoteListActionInfo.isEmpty()) {
                                    remoteListBucketInfo
                                            .add(MDSALUtil.buildBucket(remoteListActionInfo, MDSALUtil.GROUP_WEIGHT,
                                                    bucketId, MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
                                    bucketId++;
                                }
                            } catch (Exception ex) {
                                LOG.error("setElanBCGrouponOtherDpns failed due to Exception caught; "
                                        + "Logical Group Interface not found between source Dpn - {}, "
                                        + "destination Dpn - {} ", dpnInterface.getDpId(), otherFes.getDpId(), ex);
                                return;
                            }
                        }
                    }
                    List<Bucket> elanL2GwDevicesBuckets = getRemoteBCGroupBucketsOfElanL2GwDevices(elanInfo, dpId,
                            bucketId);
                    remoteListBucketInfo.addAll(elanL2GwDevicesBuckets);

                    if (remoteListBucketInfo.size() == 0) {
                        LOG.debug("No ITM is present on Dpn - {} ", dpnInterface.getDpId());
                        continue;
                    }
                    Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                            MDSALUtil.buildBucketLists(remoteListBucketInfo));
                    mdsalManager.syncInstallGroup(dpnInterface.getDpId(), group,
                            ElanConstants.DELAY_TIME_IN_MILLISECOND);
                }
            }
            try {
                Thread.sleep(WAIT_TIME_FOR_SYNC_INSTALL);
            } catch (InterruptedException e1) {
                LOG.warn("Error while waiting for remote BC group on other DPNs for ELAN {} to install", elanInfo);
            }
        }
    }

    /**
     * Returns the bucket info with the given interface as the only bucket.
     */
    private Bucket getLocalBCGroupBucketInfo(InterfaceInfo interfaceInfo, int bucketIdStart) {
        return MDSALUtil.buildBucket(getInterfacePortActions(interfaceInfo), MDSALUtil.GROUP_WEIGHT, bucketIdStart,
                MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP);
    }

    private List<MatchInfo> buildMatchesForVni(Long vni) {
        List<MatchInfo> mkMatches = new ArrayList<>();
        MatchInfo match = new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] { BigInteger.valueOf(vni) });
        mkMatches.add(match);
        return mkMatches;
    }

    private List<Instruction> getInstructionsForOutGroup(long groupId) {
        List<Instruction> mkInstructions = new ArrayList<>();
        List<Action> actions = new ArrayList<>();
        actions.add(new ActionInfo(ActionType.group, new String[] { Long.toString(groupId) }).buildAction());
        mkInstructions.add(MDSALUtil.getWriteActionsInstruction(actions, 0));
        return mkInstructions;
    }

    private List<MatchInfo> getMatchesForElanTag(long elanTag, boolean isSHFlagSet) {
        List<MatchInfo> mkMatches = new ArrayList<>();
        // Matching metadata
        mkMatches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                ElanUtils.getElanMetadataLabel(elanTag, isSHFlagSet), MetaDataUtil.METADATA_MASK_SERVICE_SH_FLAG }));
        return mkMatches;
    }

    /**
     * Builds the list of instructions to be installed in the External Tunnel
     * table (38), which so far consists in writing the elanTag in metadata and
     * send packet to the new DHCP table.
     *
     * @param elanTag
     *            elanTag to be written in metadata when flow is selected
     * @return the instructions ready to be installed in a flow
     */
    private List<InstructionInfo> getInstructionsExtTunnelTable(Long elanTag) {
        List<InstructionInfo> mkInstructions = new ArrayList<>();
        mkInstructions.add(new InstructionInfo(InstructionType.write_metadata,
                new BigInteger[] { ElanUtils.getElanMetadataLabel(elanTag), ElanUtils.getElanMetadataMask() }));
        // TODO: We should point to SMAC or DMAC depending on a configuration
        // property to enable
        // mac learning
        mkInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.ELAN_DMAC_TABLE }));

        return mkInstructions;
    }

    // Install DMAC entry on dst DPN
    public void installDMacAddressTables(ElanInstance elanInfo, InterfaceInfo interfaceInfo, BigInteger dstDpId)
            throws ElanException {
        String interfaceName = interfaceInfo.getInterfaceName();
        ElanInterfaceMac elanInterfaceMac = elanUtils.getElanInterfaceMacByInterfaceName(interfaceName);
        if (elanInterfaceMac != null && elanInterfaceMac.getMacEntry() != null) {
            WriteTransaction writeFlowTx = broker.newWriteOnlyTransaction();
            List<MacEntry> macEntries = elanInterfaceMac.getMacEntry();
            for (MacEntry macEntry : macEntries) {
                PhysAddress physAddress = macEntry.getMacAddress();
                elanUtils.setupDMacFlowonRemoteDpn(elanInfo, interfaceInfo, dstDpId, physAddress.getValue(),
                        writeFlowTx);
            }
            writeFlowTx.submit();
        }
    }

    public void setupElanBroadcastGroups(ElanInstance elanInfo, BigInteger dpnId) {
        setupElanBroadcastGroups(elanInfo, null, dpnId);
    }

    public void setupElanBroadcastGroups(ElanInstance elanInfo, DpnInterfaces dpnInterfaces, BigInteger dpnId) {
        setupStandardElanBroadcastGroups(elanInfo, dpnInterfaces, dpnId);
        setupLeavesEtreeBroadcastGroups(elanInfo, dpnInterfaces, dpnId);
    }

    public void setupStandardElanBroadcastGroups(ElanInstance elanInfo, DpnInterfaces dpnInterfaces, BigInteger dpnId) {
        List<Bucket> listBucket = new ArrayList<>();
        int bucketId = 0;
        int actionKey = 0;
        Long elanTag = elanInfo.getElanTag();
        List<Action> listAction = new ArrayList<>();
        listAction.add(new ActionInfo(ActionType.group,
                new String[] { String.valueOf(ElanUtils.getElanLocalBCGId(elanTag)) }, ++actionKey).buildAction());
        listBucket.add(MDSALUtil.buildBucket(listAction, MDSALUtil.GROUP_WEIGHT, bucketId, MDSALUtil.WATCH_PORT,
                MDSALUtil.WATCH_GROUP));
        bucketId++;
        List<Bucket> listBucketInfoRemote = getRemoteBCGroupBuckets(elanInfo, dpnInterfaces, dpnId, bucketId,
                elanInfo.getElanTag());
        listBucket.addAll(listBucketInfoRemote);
        long groupId = ElanUtils.getElanRemoteBCGId(elanTag);
        Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                MDSALUtil.buildBucketLists(listBucket));
        LOG.trace("Installing the remote BroadCast Group:{}", group);
        mdsalManager.syncInstallGroup(dpnId, group, ElanConstants.DELAY_TIME_IN_MILLISECOND);
    }

    public void setupLeavesEtreeBroadcastGroups(ElanInstance elanInfo, DpnInterfaces dpnInterfaces, BigInteger dpnId) {
        EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
        if (etreeInstance != null) {
            long etreeLeafTag = etreeInstance.getEtreeLeafTagVal().getValue();
            List<Bucket> listBucket = new ArrayList<>();
            int bucketId = 0;
            int actionKey = 0;
            List<Action> listAction = new ArrayList<>();
            listAction.add(new ActionInfo(ActionType.group,
                    new String[] { String.valueOf(ElanUtils.getEtreeLeafLocalBCGId(etreeLeafTag)) }, ++actionKey)
                            .buildAction());
            listBucket.add(MDSALUtil.buildBucket(listAction, MDSALUtil.GROUP_WEIGHT, bucketId, MDSALUtil.WATCH_PORT,
                    MDSALUtil.WATCH_GROUP));
            bucketId++;
            List<Bucket> listBucketInfoRemote = getRemoteBCGroupBuckets(elanInfo, dpnInterfaces, dpnId, bucketId,
                    etreeLeafTag);
            listBucket.addAll(listBucketInfoRemote);
            long groupId = ElanUtils.getEtreeLeafRemoteBCGId(etreeLeafTag);
            Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                    MDSALUtil.buildBucketLists(listBucket));
            LOG.trace("Installing the remote BroadCast Group:{}", group);
            mdsalManager.syncInstallGroup(dpnId, group,
                    ElanConstants.DELAY_TIME_IN_MILLISECOND);
        }
    }

    private void createDropBucket(List<Bucket> listBucket) {
        List<Action> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.drop_action, new String[] {}).buildAction());
        Bucket dropBucket = MDSALUtil.buildBucket(actionsInfos, MDSALUtil.GROUP_WEIGHT, 0, MDSALUtil.WATCH_PORT,
                MDSALUtil.WATCH_GROUP);
        listBucket.add(dropBucket);
    }

    public void setupLocalBroadcastGroups(ElanInstance elanInfo, DpnInterfaces newDpnInterface,
            InterfaceInfo interfaceInfo) {
        setupStandardLocalBroadcastGroups(elanInfo, newDpnInterface, interfaceInfo);
        setupLeavesLocalBroadcastGroups(elanInfo, newDpnInterface, interfaceInfo);
    }

    public void setupStandardLocalBroadcastGroups(ElanInstance elanInfo, DpnInterfaces newDpnInterface,
            InterfaceInfo interfaceInfo) {
        List<Bucket> listBucket = new ArrayList<>();
        int bucketId = 0;
        long groupId = ElanUtils.getElanLocalBCGId(elanInfo.getElanTag());

        List<String> interfaces = new ArrayList<>();
        if (newDpnInterface != null) {
            interfaces = newDpnInterface.getInterfaces();
        }
        for (String ifName : interfaces) {
            // In case if there is a InterfacePort in the cache which is not in
            // operational state, skip processing it
            InterfaceInfo ifInfo = interfaceManager
                    .getInterfaceInfoFromOperationalDataStore(ifName, interfaceInfo.getInterfaceType());
            if (!isOperational(ifInfo)) {
                continue;
            }

            if (!interfaceManager.isExternalInterface(ifName)) {
                listBucket.add(MDSALUtil.buildBucket(getInterfacePortActions(ifInfo), MDSALUtil.GROUP_WEIGHT, bucketId,
                        MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
                bucketId++;
            }
        }

        Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                MDSALUtil.buildBucketLists(listBucket));
        LOG.trace("installing the localBroadCast Group:{}", group);
        mdsalManager.syncInstallGroup(interfaceInfo.getDpId(), group,
                ElanConstants.DELAY_TIME_IN_MILLISECOND);
    }

    private void setupLeavesLocalBroadcastGroups(ElanInstance elanInfo, DpnInterfaces newDpnInterface,
            InterfaceInfo interfaceInfo) {
        EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
        if (etreeInstance != null) {
            List<Bucket> listBucket = new ArrayList<>();
            int bucketId = 0;

            List<String> interfaces = new ArrayList<>();
            if (newDpnInterface != null) {
                interfaces = newDpnInterface.getInterfaces();
            }
            for (String ifName : interfaces) {
                // In case if there is a InterfacePort in the cache which is not
                // in
                // operational state, skip processing it
                InterfaceInfo ifInfo = interfaceManager
                        .getInterfaceInfoFromOperationalDataStore(ifName, interfaceInfo.getInterfaceType());
                if (!isOperational(ifInfo)) {
                    continue;
                }

                if (!interfaceManager.isExternalInterface(ifName)) {
                    // only add root interfaces
                    bucketId = addInterfaceIfRootInterface(bucketId, ifName, listBucket, ifInfo);
                }
            }

            if (listBucket.size() == 0) { // No Buckets
                createDropBucket(listBucket);
            }

            long etreeLeafTag = etreeInstance.getEtreeLeafTagVal().getValue();
            long groupId = ElanUtils.getEtreeLeafLocalBCGId(etreeLeafTag);
            Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                    MDSALUtil.buildBucketLists(listBucket));
            LOG.trace("installing the localBroadCast Group:{}", group);
            mdsalManager.syncInstallGroup(interfaceInfo.getDpId(), group,
                    ElanConstants.DELAY_TIME_IN_MILLISECOND);
        }
    }

    private int addInterfaceIfRootInterface(int bucketId, String ifName, List<Bucket> listBucket,
            InterfaceInfo ifInfo) {
        EtreeInterface etreeInterface = ElanUtils.getEtreeInterfaceByElanInterfaceName(broker, ifName);
        if (etreeInterface != null && etreeInterface.getEtreeInterfaceType() == EtreeInterfaceType.Root) {
            listBucket.add(MDSALUtil.buildBucket(getInterfacePortActions(ifInfo), MDSALUtil.GROUP_WEIGHT, bucketId,
                    MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
            bucketId++;
        }
        return bucketId;
    }

    public void removeLocalBroadcastGroup(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        BigInteger dpnId = interfaceInfo.getDpId();
        long groupId = ElanUtils.getElanLocalBCGId(elanInfo.getElanTag());
        List<Bucket> listBuckets = new ArrayList<>();
        int bucketId = 0;
        listBuckets.add(getLocalBCGroupBucketInfo(interfaceInfo, bucketId));
        // listBuckets.addAll(getRemoteBCGroupBucketInfos(elanInfo, 1,
        // interfaceInfo));
        Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                MDSALUtil.buildBucketLists(listBuckets));
        LOG.trace("deleted the localBroadCast Group:{}", group);
        mdsalManager.removeGroupToTx(dpnId, group, deleteFlowGroupTx);
    }

    public void removeElanBroadcastGroup(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            WriteTransaction deleteFlowGroupTx) {
        int bucketId = 0;
        int actionKey = 0;
        Long elanTag = elanInfo.getElanTag();
        List<Bucket> listBuckets = new ArrayList<>();
        List<Action> listAction = new ArrayList<>();
        listAction.add(new ActionInfo(ActionType.group,
                new String[] { String.valueOf(ElanUtils.getElanLocalBCGId(elanTag)) }, ++actionKey).buildAction());
        listBuckets.add(MDSALUtil.buildBucket(listAction, MDSALUtil.GROUP_WEIGHT, bucketId, MDSALUtil.WATCH_PORT,
                MDSALUtil.WATCH_GROUP));
        bucketId++;
        listBuckets.addAll(getRemoteBCGroupBucketInfos(elanInfo, bucketId, interfaceInfo, elanInfo.getElanTag()));
        BigInteger dpnId = interfaceInfo.getDpId();
        long groupId = ElanUtils.getElanRemoteBCGId(elanInfo.getElanTag());
        Group group = MDSALUtil.buildGroup(groupId, elanInfo.getElanInstanceName(), GroupTypes.GroupAll,
                MDSALUtil.buildBucketLists(listBuckets));
        LOG.trace("deleting the remoteBroadCast group:{}", group);
        mdsalManager.removeGroupToTx(dpnId, group, deleteFlowGroupTx);
    }

    /**
     * Installs a flow in the External Tunnel table consisting in translating
     * the VNI retrieved from the packet that came over a tunnel with a TOR into
     * elanTag that will be used later in the ELANs pipeline.
     *
     * @param dpnId
     *            the dpn id
     * @param elanInfo
     *            the elan info
     */
    public void setExternalTunnelTable(BigInteger dpnId, ElanInstance elanInfo) {
        long elanTag = elanInfo.getElanTag();
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpnId, NwConstants.EXTERNAL_TUNNEL_TABLE,
                getFlowRef(NwConstants.EXTERNAL_TUNNEL_TABLE, elanTag), 5, // prio
                elanInfo.getElanInstanceName(), // flowName
                0, // idleTimeout
                0, // hardTimeout
                ITMConstants.COOKIE_ITM_EXTERNAL.add(BigInteger.valueOf(elanTag)),
                buildMatchesForVni(elanInfo.getSegmentationId()), getInstructionsExtTunnelTable(elanTag));

        mdsalManager.installFlow(flowEntity);
    }

    /**
     * Removes, from External Tunnel table, the flow that translates from VNI to
     * elanTag. Important: ensure this method is only called whenever there is
     * no other ElanInterface in the specified DPN
     *
     * @param dpnId
     *            DPN whose Ext Tunnel table is going to be modified
     * @param elanInfo
     *            holds the elanTag needed for selecting the flow to be removed
     */
    public void unsetExternalTunnelTable(BigInteger dpnId, ElanInstance elanInfo) {
        // TODO: Use DataStoreJobCoordinator in order to avoid that removing the
        // last ElanInstance plus
        // adding a new one does (almost at the same time) are executed in that
        // exact order

        String flowId = getFlowRef(NwConstants.EXTERNAL_TUNNEL_TABLE, elanInfo.getElanTag());
        FlowEntity flowEntity = new FlowEntity(dpnId);
        flowEntity.setTableId(NwConstants.EXTERNAL_TUNNEL_TABLE);
        flowEntity.setFlowId(flowId);
        mdsalManager.removeFlow(flowEntity);
    }

    public void setupTerminateServiceTable(ElanInstance elanInfo, BigInteger dpId, WriteTransaction writeFlowGroupTx) {
        setupTerminateServiceTable(elanInfo, dpId, elanInfo.getElanTag(), writeFlowGroupTx);
        setupEtreeTerminateServiceTable(elanInfo, dpId, writeFlowGroupTx);
    }

    public void setupTerminateServiceTable(ElanInstance elanInfo, BigInteger dpId, long elanTag,
            WriteTransaction writeFlowGroupTx) {
        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.INTERNAL_TUNNEL_TABLE,
                getFlowRef(NwConstants.INTERNAL_TUNNEL_TABLE, elanTag), 5,
                String.format("%s:%d", "ITM Flow Entry ", elanTag), 0, 0,
                ITMConstants.COOKIE_ITM.add(BigInteger.valueOf(elanTag)),
                ElanUtils.getTunnelMatchesForServiceId((int) elanTag),
                getInstructionsForOutGroup(ElanUtils.getElanLocalBCGId(elanTag)));

        mdsalManager.addFlowToTx(dpId, flowEntity, writeFlowGroupTx);
    }

    private void setupEtreeTerminateServiceTable(ElanInstance elanInfo, BigInteger dpId,
            WriteTransaction writeFlowGroupTx) {
        EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
        if (etreeInstance != null) {
            setupTerminateServiceTable(elanInfo, dpId, etreeInstance.getEtreeLeafTagVal().getValue(), writeFlowGroupTx);
        }
    }

    public void setupUnknownDMacTable(ElanInstance elanInfo, BigInteger dpId, WriteTransaction writeFlowGroupTx) {
        long elanTag = elanInfo.getElanTag();
        installLocalUnknownFlow(elanInfo, dpId, elanTag, writeFlowGroupTx);
        installRemoteUnknownFlow(elanInfo, dpId, elanTag, writeFlowGroupTx);
        setupEtreeUnknownDMacTable(elanInfo, dpId, elanTag, writeFlowGroupTx);
    }

    private void setupEtreeUnknownDMacTable(ElanInstance elanInfo, BigInteger dpId, long elanTag,
            WriteTransaction writeFlowGroupTx) {
        EtreeLeafTagName etreeLeafTag = elanUtils.getEtreeLeafTagByElanTag(elanTag);
        if (etreeLeafTag != null) {
            long leafTag = etreeLeafTag.getEtreeLeafTag().getValue();
            installRemoteUnknownFlow(elanInfo, dpId, leafTag, writeFlowGroupTx);
            installLocalUnknownFlow(elanInfo, dpId, leafTag, writeFlowGroupTx);
        }
    }

    private void installLocalUnknownFlow(ElanInstance elanInfo, BigInteger dpId, long elanTag,
            WriteTransaction writeFlowGroupTx) {
        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.ELAN_UNKNOWN_DMAC_TABLE,
                getUnknownDmacFlowRef(NwConstants.ELAN_UNKNOWN_DMAC_TABLE, elanTag,
                        /* SH flag */false),
                5, elanInfo.getElanInstanceName(), 0, 0,
                ElanConstants.COOKIE_ELAN_UNKNOWN_DMAC.add(BigInteger.valueOf(elanTag)),
                getMatchesForElanTag(elanTag, /* SH flag */false),
                getInstructionsForOutGroup(ElanUtils.getElanRemoteBCGId(elanTag)));

        mdsalManager.addFlowToTx(dpId, flowEntity, writeFlowGroupTx);
    }

    private void installRemoteUnknownFlow(ElanInstance elanInfo, BigInteger dpId, long elanTag,
            WriteTransaction writeFlowGroupTx) {
        // only if ELAN can connect to external network, perform the following
        if (ElanUtils.isVxlan(elanInfo) || ElanUtils.isVlan(elanInfo) || ElanUtils.isFlat(elanInfo)) {
            Flow flowEntity2 = MDSALUtil.buildFlowNew(NwConstants.ELAN_UNKNOWN_DMAC_TABLE,
                    getUnknownDmacFlowRef(NwConstants.ELAN_UNKNOWN_DMAC_TABLE, elanTag,
                            /* SH flag */true),
                    5, elanInfo.getElanInstanceName(), 0, 0,
                    ElanConstants.COOKIE_ELAN_UNKNOWN_DMAC.add(BigInteger.valueOf(elanTag)),
                    getMatchesForElanTag(elanTag, /* SH flag */true),
                    getInstructionsForOutGroup(ElanUtils.getElanLocalBCGId(elanTag)));
            mdsalManager.addFlowToTx(dpId, flowEntity2, writeFlowGroupTx);
        }
    }


    private void removeUnknownDmacFlow(BigInteger dpId, ElanInstance elanInfo, WriteTransaction deleteFlowGroupTx,
            long elanTag) {
        Flow flow = new FlowBuilder().setId(new FlowId(getUnknownDmacFlowRef(NwConstants.ELAN_UNKNOWN_DMAC_TABLE,
                elanTag, /* SH flag */ false))).setTableId(NwConstants.ELAN_UNKNOWN_DMAC_TABLE).build();
        mdsalManager.removeFlowToTx(dpId, flow, deleteFlowGroupTx);

        if (ElanUtils.isVxlan(elanInfo)) {
            Flow flow2 = new FlowBuilder().setId(new FlowId(getUnknownDmacFlowRef(NwConstants.ELAN_UNKNOWN_DMAC_TABLE,
                    elanTag, /* SH flag */ true))).setTableId(NwConstants.ELAN_UNKNOWN_DMAC_TABLE)
                    .build();
            mdsalManager.removeFlowToTx(dpId, flow2, deleteFlowGroupTx);
        }
    }

    private void removeDefaultTermFlow(BigInteger dpId, long elanTag) {
        elanUtils.removeTerminatingServiceAction(dpId, (int) elanTag);
    }

    private void bindService(ElanInstance elanInfo, ElanInterface elanInterface, WriteTransaction tx) {
        if (isStandardElanService(elanInterface)) {
            bindElanService(elanInfo.getElanTag(), elanInfo.getElanInstanceName(), elanInterface.getName(), tx);
        } else { // Etree service
            bindEtreeService(elanInfo, elanInterface, tx);
        }
    }

    private void bindElanService(long elanTag, String elanInstanceName, String interfaceName, WriteTransaction tx) {
        int priority = ElanConstants.ELAN_SERVICE_PRIORITY;
        int instructionKey = 0;
        List<Instruction> instructions = new ArrayList<>();
        instructions.add(MDSALUtil.buildAndGetWriteMetadaInstruction(ElanUtils.getElanMetadataLabel(elanTag),
                MetaDataUtil.METADATA_MASK_SERVICE, ++instructionKey));
        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(NwConstants.ELAN_BASE_TABLE,
                ++instructionKey));
        short elanServiceIndex = ServiceIndex.getIndex(NwConstants.ELAN_SERVICE_NAME, NwConstants.ELAN_SERVICE_INDEX);
        BoundServices serviceInfo = ElanUtils.getBoundServices(
                String.format("%s.%s.%s", "vpn", elanInstanceName, interfaceName), elanServiceIndex,
                priority, NwConstants.COOKIE_ELAN_INGRESS_TABLE, instructions);
        tx.put(LogicalDatastoreType.CONFIGURATION,
                ElanUtils.buildServiceId(interfaceName, elanServiceIndex), serviceInfo, true);
    }

    private void bindEtreeService(ElanInstance elanInfo, ElanInterface elanInterface, WriteTransaction tx) {
        if (elanInterface.getAugmentation(EtreeInterface.class).getEtreeInterfaceType() == EtreeInterfaceType.Root) {
            bindElanService(elanInfo.getElanTag(), elanInfo.getElanInstanceName(), elanInterface.getName(), tx);
        } else {
            EtreeInstance etreeInstance = elanInfo.getAugmentation(EtreeInstance.class);
            if (etreeInstance == null) {
                LOG.error("EtreeInterface " + elanInterface.getName() + " is associated with a non EtreeInstance: "
                        + elanInfo.getElanInstanceName());
            } else {
                bindElanService(etreeInstance.getEtreeLeafTagVal().getValue(), elanInfo.getElanInstanceName(),
                        elanInterface.getName(), tx);
            }
        }
    }

    private boolean isStandardElanService(ElanInterface elanInterface) {
        return elanInterface.getAugmentation(EtreeInterface.class) == null;
    }

    private boolean isStandardElanService(ElanInstance elanInstance) {
        return elanInstance.getAugmentation(EtreeInstance.class) == null;
    }

    private void unbindService(ElanInstance elanInfo, String interfaceName, WriteTransaction tx) {
        tx.delete(LogicalDatastoreType.CONFIGURATION, ElanUtils.buildServiceId(interfaceName,
                ServiceIndex.getIndex(NwConstants.ELAN_SERVICE_NAME, NwConstants.ELAN_SERVICE_INDEX)));
    }

    private String getFlowRef(long tableId, long elanTag) {
        return new StringBuffer().append(tableId).append(elanTag).toString();
    }

    private String getUnknownDmacFlowRef(long tableId, long elanTag, boolean shFlag) {
        return new StringBuffer().append(tableId).append(elanTag).append(shFlag).toString();
    }

    private List<Action> getInterfacePortActions(InterfaceInfo interfaceInfo) {
        List<Action> listAction = new ArrayList<>();
        int actionKey = 0;
        listAction.add(new ActionInfo(ActionType.set_field_tunnel_id,
                new BigInteger[] { BigInteger.valueOf(interfaceInfo.getInterfaceTag()) }, actionKey).buildAction());
        actionKey++;
        listAction.add(new ActionInfo(ActionType.nx_resubmit,
                new String[] { String.valueOf(NwConstants.ELAN_FILTER_EQUALS_TABLE) }, actionKey).buildAction());
        return listAction;
    }

    private DpnInterfaces updateElanDpnInterfacesList(String elanInstanceName, BigInteger dpId,
            List<String> interfaceNames, WriteTransaction tx) {
        DpnInterfaces dpnInterface = new DpnInterfacesBuilder().setDpId(dpId).setInterfaces(interfaceNames)
                .setKey(new DpnInterfacesKey(dpId)).build();
        tx.put(LogicalDatastoreType.OPERATIONAL,
                ElanUtils.getElanDpnInterfaceOperationalDataPath(elanInstanceName, dpId), dpnInterface, true);
        return dpnInterface;
    }

    /**
     * Delete elan dpn interface from operational DS.
     *
     * @param elanInstanceName
     *            the elan instance name
     * @param dpId
     *            the dp id
     */
    private void deleteElanDpnInterface(String elanInstanceName, BigInteger dpId, WriteTransaction tx) {
        tx.delete(LogicalDatastoreType.OPERATIONAL,
                ElanUtils.getElanDpnInterfaceOperationalDataPath(elanInstanceName, dpId));
    }

    private DpnInterfaces createElanInterfacesList(String elanInstanceName, String interfaceName, BigInteger dpId,
            WriteTransaction tx) {
        List<String> interfaceNames = new ArrayList<>();
        interfaceNames.add(interfaceName);
        DpnInterfaces dpnInterface = new DpnInterfacesBuilder().setDpId(dpId).setInterfaces(interfaceNames)
                .setKey(new DpnInterfacesKey(dpId)).build();
        tx.put(LogicalDatastoreType.OPERATIONAL,
                ElanUtils.getElanDpnInterfaceOperationalDataPath(elanInstanceName, dpId), dpnInterface, true);
        return dpnInterface;
    }

    private void createElanInterfaceTablesList(String interfaceName, WriteTransaction tx) {
        InstanceIdentifier<ElanInterfaceMac> elanInterfaceMacTables = ElanUtils
                .getElanInterfaceMacEntriesOperationalDataPath(interfaceName);
        Optional<ElanInterfaceMac> interfaceMacTables = elanUtils.read(broker,
                LogicalDatastoreType.OPERATIONAL, elanInterfaceMacTables);
        // Adding new Elan Interface Port to the operational DataStore without
        // Static-Mac Entries..
        if (!interfaceMacTables.isPresent()) {
            ElanInterfaceMac elanInterfaceMacTable = new ElanInterfaceMacBuilder().setElanInterface(interfaceName)
                    .setKey(new ElanInterfaceMacKey(interfaceName)).build();
            tx.put(LogicalDatastoreType.OPERATIONAL,
                    ElanUtils.getElanInterfaceMacEntriesOperationalDataPath(interfaceName), elanInterfaceMacTable,
                    true);
        }
    }

    private void createElanStateList(String elanInstanceName, String interfaceName, WriteTransaction tx) {
        InstanceIdentifier<Elan> elanInstance = ElanUtils.getElanInstanceOperationalDataPath(elanInstanceName);
        Optional<Elan> elanInterfaceLists = elanUtils.read(broker,
                LogicalDatastoreType.OPERATIONAL, elanInstance);
        // Adding new Elan Interface Port to the operational DataStore without
        // Static-Mac Entries..
        if (elanInterfaceLists.isPresent()) {
            List<String> interfaceLists = elanInterfaceLists.get().getElanInterfaces();
            if (interfaceLists == null) {
                interfaceLists = new ArrayList<>();
            }
            interfaceLists.add(interfaceName);
            Elan elanState = new ElanBuilder().setName(elanInstanceName).setElanInterfaces(interfaceLists)
                    .setKey(new ElanKey(elanInstanceName)).build();
            tx.put(LogicalDatastoreType.OPERATIONAL, ElanUtils.getElanInstanceOperationalDataPath(elanInstanceName),
                    elanState, true);
        }
    }

    private boolean isOperational(InterfaceInfo interfaceInfo) {
        if (interfaceInfo == null) {
            return false;
        }
        return interfaceInfo.getAdminState() == InterfaceInfo.InterfaceAdminState.ENABLED;
    }

    public void handleInternalTunnelStateEvent(BigInteger srcDpId, BigInteger dstDpId) throws ElanException {
        ElanDpnInterfaces dpnInterfaceLists = elanUtils.getElanDpnInterfacesList();
        if (dpnInterfaceLists == null) {
            return;
        }
        List<ElanDpnInterfacesList> elanDpnIf = dpnInterfaceLists.getElanDpnInterfacesList();
        for (ElanDpnInterfacesList elanDpns : elanDpnIf) {
            int cnt = 0;
            String elanName = elanDpns.getElanInstanceName();
            List<DpnInterfaces> dpnInterfaces = elanDpns.getDpnInterfaces();
            if (dpnInterfaces == null) {
                continue;
            }
            for (DpnInterfaces dpnIf : dpnInterfaces) {
                if (dpnIf.getDpId().equals(srcDpId) || dpnIf.getDpId().equals(dstDpId)) {
                    cnt++;
                }
            }
            if (cnt == 2) {
                LOG.debug("Elan instance:{} is present b/w srcDpn:{} and dstDpn:{}", elanName, srcDpId, dstDpId);
                ElanInstance elanInfo = ElanUtils.getElanInstanceByName(broker, elanName);
                // update Remote BC Group
                setupElanBroadcastGroups(elanInfo, srcDpId);

                DpnInterfaces dpnInterface = elanUtils.getElanInterfaceInfoByElanDpn(elanName, dstDpId);
                Set<String> interfaceLists = new HashSet<>();
                interfaceLists.addAll(dpnInterface.getInterfaces());
                for (String ifName : interfaceLists) {
                    InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(ifName);
                    if (isOperational(interfaceInfo)) {
                        installDMacAddressTables(elanInfo, interfaceInfo, srcDpId);
                    }
                }
            }

        }
    }

    /**
     * Handle external tunnel state event.
     *
     * @param externalTunnel
     *            the external tunnel
     * @param intrf
     *            the interface
     * @throws ElanException in case of issues creating the flow objects
     */
    public void handleExternalTunnelStateEvent(ExternalTunnel externalTunnel, Interface intrf) throws ElanException {
        if (!validateExternalTunnelStateEvent(externalTunnel, intrf)) {
            return;
        }
        // dpId/externalNodeId will be available either in source or destination
        // based on the tunnel end point
        BigInteger dpId = null;
        NodeId externalNodeId = null;
        if (StringUtils.isNumeric(externalTunnel.getSourceDevice())) {
            dpId = new BigInteger(externalTunnel.getSourceDevice());
            externalNodeId = new NodeId(externalTunnel.getDestinationDevice());
        } else if (StringUtils.isNumeric(externalTunnel.getDestinationDevice())) {
            dpId = new BigInteger(externalTunnel.getDestinationDevice());
            externalNodeId = new NodeId(externalTunnel.getSourceDevice());
        }
        if (dpId == null || externalNodeId == null) {
            LOG.error("Dp ID / externalNodeId not found in external tunnel {}", externalTunnel);
            return;
        }

        ElanDpnInterfaces dpnInterfaceLists = elanUtils.getElanDpnInterfacesList();
        if (dpnInterfaceLists == null) {
            return;
        }
        List<ElanDpnInterfacesList> elanDpnIf = dpnInterfaceLists.getElanDpnInterfacesList();
        for (ElanDpnInterfacesList elanDpns : elanDpnIf) {
            String elanName = elanDpns.getElanInstanceName();
            ElanInstance elanInfo = ElanUtils.getElanInstanceByName(broker, elanName);

            DpnInterfaces dpnInterfaces = elanUtils.getElanInterfaceInfoByElanDpn(elanName, dpId);
            if (dpnInterfaces == null || dpnInterfaces.getInterfaces() == null
                    || dpnInterfaces.getInterfaces().isEmpty()) {
                continue;
            }
            LOG.debug("Elan instance:{} is present in Dpn:{} ", elanName, dpId);

            setupElanBroadcastGroups(elanInfo, dpId);
            // install L2gwDevices local macs in dpn.
            elanL2GatewayUtils.installL2gwDeviceMacsInDpn(dpId, externalNodeId, elanInfo, intrf.getName());
            // Install dpn macs on external device
            elanL2GatewayUtils.installDpnMacsInL2gwDevice(elanName, new HashSet<>(dpnInterfaces.getInterfaces()), dpId,
                    externalNodeId);
        }
        LOG.info("Handled ExternalTunnelStateEvent for {}", externalTunnel);
    }

    /**
     * Validate external tunnel state event.
     *
     * @param externalTunnel
     *            the external tunnel
     * @param intrf
     *            the intrf
     * @return true, if successful
     */
    private boolean validateExternalTunnelStateEvent(ExternalTunnel externalTunnel, Interface intrf) {
        if (intrf.getOperStatus() == Interface.OperStatus.Up) {
            String srcDevice = externalTunnel.getDestinationDevice();
            String destDevice = externalTunnel.getSourceDevice();
            ExternalTunnel otherEndPointExtTunnel = elanUtils.getExternalTunnel(srcDevice, destDevice,
                    LogicalDatastoreType.CONFIGURATION);
            LOG.trace("Validating external tunnel state: src tunnel {}, dest tunnel {}", externalTunnel,
                    otherEndPointExtTunnel);
            if (otherEndPointExtTunnel != null) {
                boolean otherEndPointInterfaceOperational = ElanUtils.isInterfaceOperational(
                        otherEndPointExtTunnel.getTunnelInterfaceName(), broker);
                if (otherEndPointInterfaceOperational) {
                    return true;
                } else {
                    LOG.debug("Other end [{}] of the external tunnel is not yet UP for {}",
                            otherEndPointExtTunnel.getTunnelInterfaceName(), externalTunnel);
                }
            }
        }
        return false;
    }

    private List<MatchInfo> getMatchesForFilterEqualsLPortTag(int lportTag) {
        List<MatchInfo> mkMatches = new ArrayList<>();
        // Matching metadata
        mkMatches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { MetaDataUtil.getLportTagMetaData(lportTag), MetaDataUtil.METADATA_MASK_LPORT_TAG }));
        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] { BigInteger.valueOf(lportTag) }));
        return mkMatches;
    }

    private List<MatchInfo> getTunnelIdMatchForFilterEqualsLPortTag(int lportTag) {
        List<MatchInfo> mkMatches = new ArrayList<>();
        // Matching metadata
        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] { BigInteger.valueOf(lportTag) }));
        return mkMatches;
    }

    public void updateRemoteBroadcastGroupForAllElanDpns(ElanInstance elanInfo) {
        List<DpnInterfaces> dpns = elanUtils.getInvolvedDpnsInElan(elanInfo.getElanInstanceName());
        if (dpns == null) {
            return;
        }
        for (DpnInterfaces dpn : dpns) {
            setupElanBroadcastGroups(elanInfo, dpn.getDpId());
        }
    }

    public List<Bucket> getRemoteBCGroupBucketsOfElanL2GwDevices(ElanInstance elanInfo, BigInteger dpnId,
            int bucketId) {
        List<Bucket> listBucketInfo = new ArrayList<>();
        ConcurrentMap<String, L2GatewayDevice> map = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanInfo.getElanInstanceName());
        for (L2GatewayDevice device : map.values()) {
            String interfaceName = elanL2GatewayUtils.getExternalTunnelInterfaceName(String.valueOf(dpnId),
                    device.getHwvtepNodeId());
            if (interfaceName == null) {
                continue;
            }
            List<Action> listActionInfo = elanUtils.buildTunnelItmEgressActions(interfaceName,
                    elanInfo.getSegmentationId());
            listBucketInfo.add(MDSALUtil.buildBucket(listActionInfo, MDSALUtil.GROUP_WEIGHT, bucketId,
                    MDSALUtil.WATCH_PORT, MDSALUtil.WATCH_GROUP));
            bucketId++;
        }
        return listBucketInfo;
    }

    @Override
    protected ElanInterfaceManager getDataTreeChangeListener() {
        return this;
    }
}
