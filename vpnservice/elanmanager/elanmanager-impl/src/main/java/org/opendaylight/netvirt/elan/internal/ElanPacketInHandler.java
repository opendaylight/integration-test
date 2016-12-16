/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.ListenableFuture;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;

import org.opendaylight.controller.liblldp.NetUtils;
import org.opendaylight.controller.liblldp.PacketException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NWUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.packet.Ethernet;
//import org.opendaylight.netvirt.elan.ElanException;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.tag.name.map.ElanTagName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.NoMatch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketInReason;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketReceived;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@SuppressWarnings("deprecation")
public class ElanPacketInHandler implements PacketProcessingListener {

    private static final Logger LOG = LoggerFactory.getLogger(ElanPacketInHandler.class);

    private final DataBroker broker;
    private final IInterfaceManager interfaceManager;
    private final ElanUtils elanUtils;
    private final ElanL2GatewayUtils elanL2GatewayUtils;

    public ElanPacketInHandler(DataBroker dataBroker, final IInterfaceManager interfaceManager, ElanUtils elanUtils) {
        broker = dataBroker;
        this.interfaceManager = interfaceManager;
        this.elanUtils = elanUtils;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
    }

    @Override
    public void onPacketReceived(PacketReceived notification) {
        Class<? extends PacketInReason> pktInReason = notification.getPacketInReason();
        short tableId = notification.getTableId().getValue();
        if (pktInReason == NoMatch.class && tableId == NwConstants.ELAN_SMAC_TABLE) {
            ElanManagerCounters.unknown_smac_pktin_rcv.inc();
            try {
                byte[] data = notification.getPayload();
                Ethernet res = new Ethernet();

                res.deserialize(data, 0, data.length * NetUtils.NumBitsInAByte);

                byte[] srcMac = res.getSourceMACAddress();
                final String macAddress = NWUtil.toStringMacAddress(srcMac);

                final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                portDataStoreCoordinator.enqueueJob("MAC-" + macAddress, new Callable<List<ListenableFuture<Void>>>() {
                    @Override
                    public List<ListenableFuture<Void>> call() throws Exception {
                        BigInteger metadata = notification.getMatch().getMetadata().getMetadata();
                        long elanTag = MetaDataUtil.getElanTagFromMetadata(metadata);

                        long portTag = MetaDataUtil.getLportFromMetadata(metadata).intValue();

                        Optional<IfIndexInterface> interfaceInfoOp = elanUtils.getInterfaceInfoByInterfaceTag(portTag);
                        if (!interfaceInfoOp.isPresent()) {
                            LOG.warn("There is no interface for given portTag {}", portTag);
                            return Collections.emptyList();
                        }
                        String interfaceName = interfaceInfoOp.get().getInterfaceName();
                        LOG.debug("Received a packet with srcMac: {} ElanTag: {} PortTag: {} InterfaceName: {}",
                                macAddress, elanTag, portTag, interfaceName);
                        ElanTagName elanTagName = elanUtils.getElanInfoByElanTag(elanTag);
                        if (elanTagName == null) {
                            LOG.warn("not able to find elanTagName in elan-tag-name-map for elan tag {}", elanTag);
                            return Collections.emptyList();
                        }
                        String elanName = elanTagName.getName();
                        PhysAddress physAddress = new PhysAddress(macAddress);
                        MacEntry macEntry = elanUtils.getInterfaceMacEntriesOperationalDataPath(interfaceName,
                                physAddress);
                        if (macEntry != null && macEntry.getInterface().equals(interfaceName)) {
                            BigInteger macTimeStamp = macEntry.getControllerLearnedForwardingEntryTimestamp();
                            if (System.currentTimeMillis() > macTimeStamp.longValue() + 10000) {
                                /*
                                 * Protection time expired. Even though the MAC has been
                                 * learnt (it is in the cache) the packets are punted to
                                 * controller. Which means, the the flows were not
                                 * successfully created in the DPN, but the MAC entry
                                 * has been added successfully in the cache.
                                 *
                                 * So, the cache has to be cleared and the flows and
                                 * cache should be recreated (clearing of cache is
                                 * required so that the timestamp is updated).
                                 */
                                InstanceIdentifier<MacEntry> macEntryId = ElanUtils
                                        .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName,
                                                physAddress);
                                ElanUtils.delete(broker, LogicalDatastoreType.OPERATIONAL, macEntryId);
                                ElanManagerCounters.unknown_smac_pktin_removed_for_retry.inc();
                            } else {
                                // Protection time running. Ignore packets for 2 seconds
                                ElanManagerCounters.unknown_smac_pktin_ignored_due_protection.inc();
                                return Collections.emptyList();
                            }
                        } else if (macEntry != null) {
                            // MAC address has moved. Overwrite the mapping and replace
                            // MAC flows
                            long macTimeStamp = macEntry.getControllerLearnedForwardingEntryTimestamp().longValue();
                            if (System.currentTimeMillis() > macTimeStamp + 10000) {

                                InstanceIdentifier<MacEntry> macEntryId = ElanUtils
                                        .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName,
                                                physAddress);
                                ElanUtils.delete(broker, LogicalDatastoreType.OPERATIONAL, macEntryId);
                                tryAndRemoveInvalidMacEntry(elanName, macEntry);
                                ElanManagerCounters.unknown_smac_pktin_removed_for_relearned.inc();
                            } else {
                                // New FEs flood their packets on all interfaces. This
                                // can lead
                                // to many contradicting packet_ins. Ignore all packets
                                // received
                                // within 1s after the first packet_in
                                ElanManagerCounters.unknown_smac_pktin_mac_migration_ignored_due_to_protection.inc();
                                return Collections.emptyList();
                            }
                        }
                        BigInteger timeStamp = new BigInteger(String.valueOf(System.currentTimeMillis()));
                        macEntry = new MacEntryBuilder().setInterface(interfaceName).setMacAddress(physAddress)
                                .setKey(new MacEntryKey(physAddress))
                                .setControllerLearnedForwardingEntryTimestamp(timeStamp)
                                .setIsStaticAddress(false).build();
                        InstanceIdentifier<MacEntry> macEntryId = ElanUtils
                                .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName, physAddress);
                        MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, macEntryId,
                                macEntry);
                        InstanceIdentifier<MacEntry> elanMacEntryId = ElanUtils.getMacEntryOperationalDataPath(elanName,
                                physAddress);
                        MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, elanMacEntryId,
                                macEntry);
                        ElanInstance elanInstance = ElanUtils.getElanInstanceByName(broker, elanName);
                        WriteTransaction flowWritetx = broker.newWriteOnlyTransaction();

                        boolean isVlanOrFlatProviderIface =
                                ElanUtils.isVlan(elanInstance)
                                && interfaceName.endsWith(":" + elanInstance.getSegmentationId())
                                || ElanUtils.isFlat(elanInstance) && interfaceName.endsWith(":flat");

                        elanUtils.setupMacFlows(elanInstance, interfaceManager.getInterfaceInfo(interfaceName),
                                                elanInstance.getMacTimeout(), macAddress,
                                                !isVlanOrFlatProviderIface, flowWritetx);
                        List<ListenableFuture<Void>> futures = new ArrayList<>();
                        futures.add(flowWritetx.submit());
                        BigInteger dpId = interfaceManager.getDpnForInterface(interfaceName);
                        elanL2GatewayUtils.scheduleAddDpnMacInExtDevices(elanInstance.getElanInstanceName(), dpId,
                                Arrays.asList(physAddress));

                        ElanManagerCounters.unknown_smac_pktin_learned.inc();
                        return futures;
                    }
                });

            } catch (PacketException e) {
                LOG.error("Failed to decode packet: {}", notification, e);
            }
        }
    }

    /*
     * Though this method is a little costlier because it uses try-catch
     * construct, it is used only in rare scenarios like MAC movement or invalid
     * Static MAC having been added on a wrong ELAN.
     */
    private void tryAndRemoveInvalidMacEntry(String elanName, MacEntry macEntry) {
        ElanInstance elanInfo = ElanUtils.getElanInstanceByName(broker, elanName);
        if (elanInfo == null) {
            LOG.warn("MAC {} is been added (either statically or dynamically) for an invalid Elan {}. "
                    + "Manual cleanup may be necessary", macEntry.getMacAddress(), elanName);
            return;
        }

        InterfaceInfo oldInterfaceLport = interfaceManager.getInterfaceInfo(macEntry.getInterface());
        if (oldInterfaceLport == null) {
            LOG.warn("MAC {} is been added (either statically or dynamically) on an invalid Logical Port {}. "
                     + "Manual cleanup may be necessary",
                     macEntry.getMacAddress(), macEntry.getInterface());
            return;
        }
        WriteTransaction flowDeletetx = broker.newWriteOnlyTransaction();
        elanUtils.deleteMacFlows(elanInfo, oldInterfaceLport, macEntry, flowDeletetx);
        flowDeletetx.submit();
        elanL2GatewayUtils.removeMacsFromElanExternalDevices(elanInfo, Arrays.asList(macEntry.getMacAddress()));
    }

}
