/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.utils;

import com.google.common.base.Optional;
import com.google.common.collect.Lists;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.stream.Collectors;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.IfmUtil;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.SystemPropertyReader;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundUtils;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.elan.ElanException;
import org.opendaylight.netvirt.elan.l2gw.jobs.DeleteL2GwDeviceMacsFromElanJob;
import org.opendaylight.netvirt.elan.l2gw.jobs.DeleteLogicalSwitchJob;
import org.opendaylight.netvirt.elan.l2gw.listeners.HwvtepTerminationPointListener;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanConstants;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.AddL2GwDeviceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetExternalTunnelInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetExternalTunnelInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan._interface.forwarding.entries.ElanInterfaceMac;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.forwarding.tables.MacTable;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindings;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * It gathers a set of utility methods that handle ELAN configuration in
 * external Devices (where external means "not-CSS". As of now: TORs).
 *
 * <p>It makes use of HwvtepUtils class located under ovsdb/hwvtepsouthbound
 * project for low-level mdsal operations
 *
 * @author eperefr
 */
public class ElanL2GatewayUtils {
    private static final Logger LOG = LoggerFactory.getLogger(ElanL2GatewayUtils.class);

    private final DataBroker broker;
    private final ItmRpcService itmRpcService;
    private final ElanUtils elanUtils;
    private final EntityOwnershipService entityOwnershipService;
    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;

    private final DataStoreJobCoordinator dataStoreJobCoordinator = DataStoreJobCoordinator.getInstance();
    private static Timer LogicalSwitchDeleteJobTimer = new Timer();
    private static final int LOGICAL_SWITCH_DELETE_DELAY = 20000;
    private final ConcurrentMap<Pair<NodeId, String>, TimerTask> logicalSwitchDeletedTasks = new ConcurrentHashMap<>();

    public ElanL2GatewayUtils(DataBroker broker, ItmRpcService itmRpcService, ElanUtils elanUtils,
                              EntityOwnershipService entityOwnershipService,
                              ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils) {
        this.broker = broker;
        this.itmRpcService = itmRpcService;
        this.elanUtils = elanUtils;
        this.entityOwnershipService = entityOwnershipService;
        this.elanL2GatewayMulticastUtils = elanL2GatewayMulticastUtils;
    }

    /**
     * Installs dpn macs in external device. first it checks if the physical
     * locator towards this dpn tep is present or not if the physical locator is
     * present go ahead and add the ucast macs otherwise update the mcast mac
     * entry to include this dpn tep ip and schedule the job to put ucast macs
     * once the physical locator is programmed in device
     *
     * @param elanName
     *            the elan name
     * @param lstElanInterfaceNames
     *            the lst Elan interface names
     * @param dpnId
     *            the dpn id
     * @param externalNodeId
     *            the external node id
     */
    public void installDpnMacsInL2gwDevice(String elanName, Set<String> lstElanInterfaceNames, BigInteger dpnId,
            NodeId externalNodeId) {
        L2GatewayDevice elanL2GwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanName,
                externalNodeId.getValue());
        if (elanL2GwDevice == null) {
            LOG.debug("L2 gw device not found in elan cache for device name {}", externalNodeId);
            return;
        }
        IpAddress dpnTepIp = getSourceDpnTepIp(dpnId, externalNodeId);
        if (dpnTepIp == null) {
            LOG.warn("Could not install dpn macs in l2gw device , dpnTepIp not found dpn : {} , nodeid : {}", dpnId,
                    externalNodeId);
            return;
        }

        String logicalSwitchName = getLogicalSwitchFromElan(elanName);
        RemoteMcastMacs remoteMcastMac = readRemoteMcastMac(externalNodeId, logicalSwitchName,
                LogicalDatastoreType.OPERATIONAL);
        boolean phyLocAlreadyExists = checkIfPhyLocatorAlreadyExistsInRemoteMcastEntry(externalNodeId, remoteMcastMac,
                dpnTepIp);
        LOG.debug("phyLocAlreadyExists = {} for locator [{}] in remote mcast entry for elan [{}], nodeId [{}]",
                phyLocAlreadyExists, String.valueOf(dpnTepIp.getValue()), elanName, externalNodeId.getValue());
        List<PhysAddress> staticMacs = null;
        staticMacs = getElanDpnMacsFromInterfaces(lstElanInterfaceNames);

        if (phyLocAlreadyExists) {
            scheduleAddDpnMacsInExtDevice(elanName, dpnId, staticMacs, elanL2GwDevice);
            return;
        }
        elanL2GatewayMulticastUtils.scheduleMcastMacUpdateJob(elanName, elanL2GwDevice);
        scheduleAddDpnMacsInExtDevice(elanName, dpnId, staticMacs, elanL2GwDevice);
    }

    /**
     * gets the macs addresses for elan interfaces.
     *
     * @param lstElanInterfaceNames
     *            the lst elan interface names
     * @return the list
     */
    private List<PhysAddress> getElanDpnMacsFromInterfaces(Set<String> lstElanInterfaceNames) {
        List<PhysAddress> result = new ArrayList<>();
        for (String interfaceName : lstElanInterfaceNames) {
            ElanInterfaceMac elanInterfaceMac = elanUtils.getElanInterfaceMacByInterfaceName(interfaceName);
            if (elanInterfaceMac != null && elanInterfaceMac.getMacEntry() != null) {
                for (MacEntry macEntry : elanInterfaceMac.getMacEntry()) {
                    result.add(macEntry.getMacAddress());
                }
            }
        }
        return result;
    }

    /**
     * Check if phy locator already exists in remote mcast entry.
     *
     * @param nodeId
     *            the node id
     * @param remoteMcastMac
     *            the remote mcast mac
     * @param expectedPhyLocatorIp
     *            the expected phy locator ip
     * @return true, if successful
     */
    public static boolean checkIfPhyLocatorAlreadyExistsInRemoteMcastEntry(NodeId nodeId,
            RemoteMcastMacs remoteMcastMac, IpAddress expectedPhyLocatorIp) {
        if (remoteMcastMac != null) {
            HwvtepPhysicalLocatorAugmentation expectedPhyLocatorAug = HwvtepSouthboundUtils
                    .createHwvtepPhysicalLocatorAugmentation(String.valueOf(expectedPhyLocatorIp.getValue()));
            HwvtepPhysicalLocatorRef expectedPhyLocRef = new HwvtepPhysicalLocatorRef(
                    HwvtepSouthboundUtils.createPhysicalLocatorInstanceIdentifier(nodeId, expectedPhyLocatorAug));
            if (remoteMcastMac.getLocatorSet() != null) {
                for (LocatorSet locatorSet : remoteMcastMac.getLocatorSet()) {
                    if (locatorSet.getLocatorRef().equals(expectedPhyLocRef)) {
                        LOG.trace("matched phyLocRef: {}", expectedPhyLocRef);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Gets the remote mcast mac.
     *
     * @param nodeId
     *            the node id
     * @param logicalSwitchName
     *            the logical switch name
     * @param datastoreType
     *            the datastore type
     * @return the remote mcast mac
     */
    public RemoteMcastMacs readRemoteMcastMac(NodeId nodeId, String logicalSwitchName,
            LogicalDatastoreType datastoreType) {
        InstanceIdentifier<LogicalSwitches> logicalSwitch = HwvtepSouthboundUtils
                .createLogicalSwitchesInstanceIdentifier(nodeId, new HwvtepNodeName(logicalSwitchName));
        RemoteMcastMacsKey remoteMcastMacsKey = new RemoteMcastMacsKey(new HwvtepLogicalSwitchRef(logicalSwitch),
                new MacAddress(ElanConstants.UNKNOWN_DMAC));
        RemoteMcastMacs remoteMcastMac = HwvtepUtils.getRemoteMcastMac(broker, datastoreType, nodeId,
                remoteMcastMacsKey);
        return remoteMcastMac;
    }

    /**
     * Removes the given MAC Addresses from all the External Devices belonging
     * to the specified ELAN.
     *
     * @param elanInstance
     *            the elan instance
     * @param macAddresses
     *            the mac addresses
     */
    public void removeMacsFromElanExternalDevices(ElanInstance elanInstance, List<PhysAddress> macAddresses) {
        ConcurrentMap<String, L2GatewayDevice> elanL2GwDevices = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanInstance.getElanInstanceName());
        for (L2GatewayDevice l2GatewayDevice : elanL2GwDevices.values()) {
            removeRemoteUcastMacsFromExternalDevice(l2GatewayDevice.getHwvtepNodeId(),
                    elanInstance.getElanInstanceName(), macAddresses);
        }
    }

    /**
     * Removes the given MAC Addresses from the specified External Device.
     *
     * @param deviceNodeId
     *            the device node id
     * @param macAddresses
     *            the mac addresses
     * @return the listenable future
     */
    private ListenableFuture<Void> removeRemoteUcastMacsFromExternalDevice(String deviceNodeId,
            String logicalSwitchName, List<PhysAddress> macAddresses) {
        NodeId nodeId = new NodeId(deviceNodeId);

        // TODO (eperefr)
        List<MacAddress> lstMac = Lists.transform(macAddresses,
            physAddress -> physAddress != null ? new MacAddress(physAddress.getValue()) : null);
        return HwvtepUtils.deleteRemoteUcastMacs(broker, nodeId, logicalSwitchName, lstMac);
    }

    public ElanInstance getElanInstanceForUcastLocalMac(LocalUcastMacs localUcastMac) {
        Optional<LogicalSwitches> lsOpc = elanUtils.read(broker, LogicalDatastoreType.OPERATIONAL,
                (InstanceIdentifier<LogicalSwitches>) localUcastMac.getLogicalSwitchRef().getValue());
        if (lsOpc.isPresent()) {
            LogicalSwitches ls = lsOpc.get();
            if (ls != null) {
                // Logical switch name is Elan name
                String elanName = getElanFromLogicalSwitch(ls.getHwvtepNodeName().getValue());
                return ElanUtils.getElanInstanceByName(broker, elanName);
            } else {
                String macAddress = localUcastMac.getMacEntryKey().getValue();
                LOG.error("Could not find logical_switch for {} being added/deleted", macAddress);
            }
        }
        return null;
    }

    /**
     * Install external device local macs in dpn.
     *
     * @param dpnId
     *            the dpn id
     * @param l2gwDeviceNodeId
     *            the l2gw device node id
     * @param elan
     *            the elan
     * @param interfaceName
     *            the interface name
     * @throws ElanException in case of issues creating the flow objects
     */
    public void installL2gwDeviceMacsInDpn(BigInteger dpnId, NodeId l2gwDeviceNodeId, ElanInstance elan,
            String interfaceName) throws ElanException {
        L2GatewayDevice l2gwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elan.getElanInstanceName(),
                l2gwDeviceNodeId.getValue());
        if (l2gwDevice == null) {
            LOG.debug("L2 gw device not found in elan cache for device name {}", l2gwDeviceNodeId.getValue());
            return;
        }

        installDmacFlowsOnDpn(dpnId, l2gwDevice, elan, interfaceName);
    }

    /**
     * Install dmac flows on dpn.
     *
     * @param dpnId
     *            the dpn id
     * @param l2gwDevice
     *            the l2gw device
     * @param elan
     *            the elan
     * @param interfaceName
     *            the interface name
     * @throws ElanException in case of issues creating the flow objects
     */
    public void installDmacFlowsOnDpn(BigInteger dpnId, L2GatewayDevice l2gwDevice, ElanInstance elan,
            String interfaceName) throws ElanException {
        String elanName = elan.getElanInstanceName();

        List<LocalUcastMacs> l2gwDeviceLocalMacs = l2gwDevice.getUcastLocalMacs();
        if (l2gwDeviceLocalMacs != null && !l2gwDeviceLocalMacs.isEmpty()) {
            for (LocalUcastMacs localUcastMac : l2gwDeviceLocalMacs) {
                // TODO batch these ops
                elanUtils.installDmacFlowsToExternalRemoteMac(dpnId, l2gwDevice.getHwvtepNodeId(), elan.getElanTag(),
                        elan.getSegmentationId(), localUcastMac.getMacEntryKey().getValue(), elanName, interfaceName);
            }
            LOG.debug("Installing L2gw device [{}] local macs [size: {}] in dpn [{}] for elan [{}]",
                    l2gwDevice.getHwvtepNodeId(), l2gwDeviceLocalMacs.size(), dpnId, elanName);
        }
    }

    /**
     * Install elan l2gw devices local macs in dpn.
     *
     * @param dpnId
     *            the dpn id
     * @param elan
     *            the elan
     * @param interfaceName
     *            the interface name
     * @throws ElanException in case of issues creating the flow objects
     */
    public void installElanL2gwDevicesLocalMacsInDpn(BigInteger dpnId, ElanInstance elan, String interfaceName)
            throws ElanException {
        ConcurrentMap<String, L2GatewayDevice> elanL2GwDevicesFromCache = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elan.getElanInstanceName());
        if (elanL2GwDevicesFromCache != null) {
            for (L2GatewayDevice l2gwDevice : elanL2GwDevicesFromCache.values()) {
                installDmacFlowsOnDpn(dpnId, l2gwDevice, elan, interfaceName);
            }
        } else {
            LOG.debug("No Elan l2 gateway devices in cache for [{}] ", elan.getElanInstanceName());
        }
    }

    public void installL2GwUcastMacInElan(final ElanInstance elan, final L2GatewayDevice extL2GwDevice,
            final String macToBeAdded, String interfaceName) {
        final String extDeviceNodeId = extL2GwDevice.getHwvtepNodeId();
        final String elanInstanceName = elan.getElanInstanceName();

        // Retrieve all participating DPNs in this Elan. Populate this MAC in
        // DMAC table.
        // Looping through all DPNs in order to add/remove mac flows in their
        // DMAC table
        final List<DpnInterfaces> elanDpns = elanUtils.getInvolvedDpnsInElan(elanInstanceName);
        if (elanDpns != null && elanDpns.size() > 0) {
            String jobKey = elan.getElanInstanceName() + ":" + macToBeAdded;
            ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, jobKey, "install l2gw macs in dmac table",
                () -> {
                    List<ListenableFuture<Void>> fts = Lists.newArrayList();
                    if (doesLocalUcastMacExistsInCache(extL2GwDevice, macToBeAdded)) {
                        for (DpnInterfaces elanDpn : elanDpns) {
                            // TODO batch the below call
                            fts.addAll(elanUtils.installDmacFlowsToExternalRemoteMac(elanDpn.getDpId(),
                                    extDeviceNodeId, elan.getElanTag(), elan.getSegmentationId(), macToBeAdded,
                                    elanInstanceName, interfaceName));
                        }
                    } else {
                        LOG.trace("Skipping install of dmac flows for mac {} as it is not found in cache",
                                macToBeAdded);
                    }
                    return fts;
                });
        }
        final IpAddress extL2GwDeviceTepIp = extL2GwDevice.getTunnelIp();
        final List<PhysAddress> macList = new ArrayList<>();
        macList.add(new PhysAddress(macToBeAdded));

        String jobKey = "hwvtep:" + elan.getElanInstanceName() + ":" + macToBeAdded;
        ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, jobKey, "install remote ucast macs in l2gw device",
            () -> {
                List<ListenableFuture<Void>> fts = Lists.newArrayList();
                if (!doesLocalUcastMacExistsInCache(extL2GwDevice, macToBeAdded)) {
                    LOG.trace(
                            "Skipping install of remote ucast macs {} in l2gw device as it is not found in cache",
                            macToBeAdded);
                    return fts;
                }
                ConcurrentMap<String, L2GatewayDevice> elanL2GwDevices = ElanL2GwCacheUtils
                        .getInvolvedL2GwDevices(elanInstanceName);
                for (L2GatewayDevice otherDevice : elanL2GwDevices.values()) {
                    if (!otherDevice.getHwvtepNodeId().equals(extDeviceNodeId)
                            && !areMLAGDevices(extL2GwDevice, otherDevice)) {
                        final String hwvtepId = otherDevice.getHwvtepNodeId();
                        InstanceIdentifier<Node> iid = HwvtepSouthboundUtils
                                .createInstanceIdentifier(new NodeId(hwvtepId));
                        final String logicalSwitchName = elanInstanceName;

                        ListenableFuture<Void> ft = HwvtepUtils.installUcastMacs(broker, hwvtepId, macList,
                                logicalSwitchName, extL2GwDeviceTepIp);
                        // TODO batch the above call
                        Futures.addCallback(ft, new FutureCallback<Void>() {
                            @Override
                            public void onSuccess(Void noarg) {
                                LOG.trace("Successful in initiating ucast_remote_macs addition"
                                        + "related to {} in {}", logicalSwitchName, hwvtepId);
                            }

                            @Override
                            public void onFailure(Throwable error) {
                                LOG.error(String.format(
                                        "Failed adding ucast_remote_macs related to " + "%s in %s",
                                        logicalSwitchName, hwvtepId), error);
                            }
                        });
                        fts.add(ft);
                    }
                }
                return fts;
            });
    }

    /**
     * Does local ucast mac exists in cache.
     *
     * @param elanL2GwDevice
     *            the elan L2 Gw device
     * @param macAddress
     *            the mac address to be verified
     * @return true, if successful
     */
    private static boolean doesLocalUcastMacExistsInCache(L2GatewayDevice elanL2GwDevice, String macAddress) {
        java.util.Optional<LocalUcastMacs> macExistsInCache = elanL2GwDevice.getUcastLocalMacs().stream()
                .filter(mac -> mac.getMacEntryKey().getValue().equalsIgnoreCase(macAddress)).findFirst();
        return macExistsInCache.isPresent();
    }

    /**
     * Un install l2 gw ucast mac from elan.
     *
     * @param elan
     *            the elan
     * @param l2GwDevice
     *            the l2 gw device
     * @param macAddresses
     *            the mac addresses
     */
    public void unInstallL2GwUcastMacFromElan(final ElanInstance elan, final L2GatewayDevice l2GwDevice,
            final List<MacAddress> macAddresses) {
        if (macAddresses == null || macAddresses.isEmpty()) {
            return;
        }
        final String elanName = elan.getElanInstanceName();

        // Retrieve all participating DPNs in this Elan. Populate this MAC in
        // DMAC table. Looping through all DPNs in order to add/remove mac flows
        // in their DMAC table
        for (final MacAddress mac : macAddresses) {
            final List<DpnInterfaces> elanDpns = elanUtils.getInvolvedDpnsInElan(elanName);
            if (elanDpns != null && !elanDpns.isEmpty()) {
                String jobKey = elanName + ":" + mac.getValue();
                ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, jobKey, "delete l2gw macs from dmac table",
                    () -> {
                        List<ListenableFuture<Void>> fts = Lists.newArrayList();
                        for (DpnInterfaces elanDpn : elanDpns) {
                            BigInteger dpnId = elanDpn.getDpId();
                            // never batch deletes
                            fts.addAll(elanUtils.deleteDmacFlowsToExternalMac(elan.getElanTag(), dpnId,
                                    l2GwDevice.getHwvtepNodeId(), mac.getValue()));
                        }
                        return fts;
                    });
            }
        }

        DeleteL2GwDeviceMacsFromElanJob job = new DeleteL2GwDeviceMacsFromElanJob(broker, elanName, l2GwDevice,
                macAddresses);
        ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, job.getJobKey(),
                "delete remote ucast macs in l2gw devices", job);
    }

    /**
     * Delete elan l2 gateway devices ucast local macs from dpn.
     *
     * @param elanName
     *            the elan name
     * @param dpnId
     *            the dpn id
     */
    public void deleteElanL2GwDevicesUcastLocalMacsFromDpn(final String elanName, final BigInteger dpnId) {
        ConcurrentMap<String, L2GatewayDevice> elanL2GwDevices = ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanName);
        if (elanL2GwDevices == null || elanL2GwDevices.isEmpty()) {
            LOG.trace("No L2 gateway devices in Elan [{}] cache.", elanName);
            return;
        }
        final ElanInstance elan = ElanUtils.getElanInstanceByName(broker, elanName);
        if (elan == null) {
            LOG.error("Could not find Elan by name: {}", elanName);
            return;
        }
        LOG.info("Deleting Elan [{}] L2GatewayDevices UcastLocalMacs from Dpn [{}]", elanName, dpnId);

        final Long elanTag = elan.getElanTag();
        for (final L2GatewayDevice l2GwDevice : elanL2GwDevices.values()) {
            List<MacAddress> localMacs = getL2GwDeviceLocalMacs(l2GwDevice);
            if (localMacs != null && !localMacs.isEmpty()) {
                for (final MacAddress mac : localMacs) {
                    String jobKey = elanName + ":" + mac.getValue();
                    ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, jobKey,
                            "delete l2gw macs from dmac table", () -> {
                            List<ListenableFuture<Void>> futures = Lists.newArrayList();

                            futures.addAll(elanUtils.deleteDmacFlowsToExternalMac(elanTag, dpnId,
                                    l2GwDevice.getHwvtepNodeId(), mac.getValue()));
                            return futures;
                        });
                }
            }
        }
    }

    /**
     * Gets the l2 gw device local macs.
     *
     * @param l2gwDevice
     *            the l2gw device
     * @return the l2 gw device local macs
     */
    public static List<MacAddress> getL2GwDeviceLocalMacs(L2GatewayDevice l2gwDevice) {
        List<MacAddress> macs = new ArrayList<>();
        if (l2gwDevice == null) {
            return macs;
        }
        List<LocalUcastMacs> lstUcastLocalMacs = l2gwDevice.getUcastLocalMacs();
        if (lstUcastLocalMacs != null && !lstUcastLocalMacs.isEmpty()) {
            macs = Lists.transform(lstUcastLocalMacs,
                localUcastMac -> localUcastMac != null ? localUcastMac.getMacEntryKey() : null);
        }
        return macs;
    }

    /**
     * Delete elan macs from L2 gateway device.<br>
     * This includes deleting ELAN mac table entries plus external device
     * UcastLocalMacs which are part of the same ELAN.
     *
     * @param l2GatewayDevice
     *            the l2 gateway device
     * @param elanName
     *            the elan name
     * @return the listenable future
     */
    public ListenableFuture<Void> deleteElanMacsFromL2GatewayDevice(L2GatewayDevice l2GatewayDevice,
            String elanName) {
        String hwvtepNodeId = l2GatewayDevice.getHwvtepNodeId();
        String logicalSwitch = getLogicalSwitchFromElan(elanName);

        List<MacAddress> lstElanMacs = getRemoteUcastMacs(new NodeId(hwvtepNodeId), logicalSwitch,
                LogicalDatastoreType.CONFIGURATION);
        ListenableFuture<Void> future = HwvtepUtils.deleteRemoteUcastMacs(broker, new NodeId(hwvtepNodeId),
                logicalSwitch, lstElanMacs);

        Futures.addCallback(future, new FutureCallback<Void>() {
            @Override
            public void onSuccess(Void noarg) {
                LOG.trace("Successful in batch deletion of elan [{}] macs from l2gw device [{}]", elanName,
                        hwvtepNodeId);
            }

            @Override
            public void onFailure(Throwable error) {
                LOG.warn(String.format("Failed during batch delete of elan [%s] macs from l2gw device [%s]. "
                        + "Retrying with sequential deletes.", elanName, hwvtepNodeId), error);
                if (lstElanMacs != null && !lstElanMacs.isEmpty()) {
                    for (MacAddress mac : lstElanMacs) {
                        HwvtepUtils.deleteRemoteUcastMac(broker, new NodeId(hwvtepNodeId), logicalSwitch, mac);
                    }
                }
            }
        });

        if (LOG.isDebugEnabled()) {
            List<String> elanMacs = lstElanMacs.stream().map(MacAddress::getValue).collect(Collectors.toList());
            LOG.debug("Deleting elan [{}] macs from node [{}]. Deleted macs = {}", elanName, hwvtepNodeId, elanMacs);
        }
        return future;
    }

    /**
     * Gets the remote ucast macs from hwvtep node filtering based on logical
     * switch.
     *
     * @param hwvtepNodeId
     *            the hwvtep node id
     * @param logicalSwitch
     *            the logical switch
     * @param datastoreType
     *            the datastore type
     * @return the remote ucast macs
     */
    public List<MacAddress> getRemoteUcastMacs(NodeId hwvtepNodeId, String logicalSwitch,
            LogicalDatastoreType datastoreType) {
        List<MacAddress> lstMacs = Collections.emptyList();
        Node hwvtepNode = HwvtepUtils.getHwVtepNode(broker, datastoreType, hwvtepNodeId);
        if (hwvtepNode != null) {
            List<RemoteUcastMacs> remoteUcastMacs = hwvtepNode.getAugmentation(HwvtepGlobalAugmentation.class)
                    .getRemoteUcastMacs();
            if (remoteUcastMacs != null && !remoteUcastMacs.isEmpty()) {
                // Filtering remoteUcastMacs based on the logical switch and
                // forming a list of MacAddress
                lstMacs = remoteUcastMacs.stream()
                        .filter(mac -> logicalSwitch.equals(mac.getLogicalSwitchRef().getValue()
                                .firstKeyOf(LogicalSwitches.class).getHwvtepNodeName().getValue()))
                        .map(mac -> mac.getMacEntryKey()).collect(Collectors.toList());
            }
        }
        return lstMacs;
    }

    /**
     * Install ELAN macs in L2 Gateway device.<br>
     * This includes installing ELAN mac table entries plus external device
     * UcastLocalMacs which are part of the same ELAN.
     *
     * @param elanName
     *            the elan name
     * @param l2GatewayDevice
     *            the l2 gateway device which has to be configured
     * @return the listenable future
     */
    public ListenableFuture<Void> installElanMacsInL2GatewayDevice(String elanName,
            L2GatewayDevice l2GatewayDevice) {
        String logicalSwitchName = getLogicalSwitchFromElan(elanName);
        NodeId hwVtepNodeId = new NodeId(l2GatewayDevice.getHwvtepNodeId());

        List<RemoteUcastMacs> lstL2GatewayDevicesMacs = getOtherDevicesMacs(elanName, l2GatewayDevice, hwVtepNodeId,
                logicalSwitchName);
        List<RemoteUcastMacs> lstElanMacTableEntries = getElanMacTableEntriesMacs(elanName, l2GatewayDevice,
                hwVtepNodeId, logicalSwitchName);

        List<RemoteUcastMacs> lstRemoteUcastMacs = new ArrayList<>(lstL2GatewayDevicesMacs);
        lstRemoteUcastMacs.addAll(lstElanMacTableEntries);

        ListenableFuture<Void> future = HwvtepUtils.addRemoteUcastMacs(broker, hwVtepNodeId, lstRemoteUcastMacs);

        LOG.info("Added RemoteUcastMacs entries [{}] in config DS. NodeID: {}, LogicalSwitch: {}",
                lstRemoteUcastMacs.size(), hwVtepNodeId.getValue(), logicalSwitchName);
        return future;
    }

    /**
     * Gets the l2 gateway devices ucast local macs as remote ucast macs.
     *
     * @param elanName
     *            the elan name
     * @param l2GatewayDeviceToBeConfigured
     *            the l2 gateway device to be configured
     * @param hwVtepNodeId
     *            the hw vtep node Id to be configured
     * @param logicalSwitchName
     *            the logical switch name
     * @return the l2 gateway devices macs as remote ucast macs
     */
    public static List<RemoteUcastMacs> getOtherDevicesMacs(String elanName,
            L2GatewayDevice l2GatewayDeviceToBeConfigured, NodeId hwVtepNodeId, String logicalSwitchName) {
        List<RemoteUcastMacs> lstRemoteUcastMacs = new ArrayList<>();
        ConcurrentMap<String, L2GatewayDevice> elanL2GwDevicesFromCache = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanName);

        if (elanL2GwDevicesFromCache != null) {
            for (L2GatewayDevice otherDevice : elanL2GwDevicesFromCache.values()) {
                if (l2GatewayDeviceToBeConfigured.getHwvtepNodeId().equals(otherDevice.getHwvtepNodeId())) {
                    continue;
                }
                if (!areMLAGDevices(l2GatewayDeviceToBeConfigured, otherDevice)) {
                    List<LocalUcastMacs> lstUcastLocalMacs = otherDevice.getUcastLocalMacs();
                    if (lstUcastLocalMacs != null) {
                        for (LocalUcastMacs localUcastMac : lstUcastLocalMacs) {
                            HwvtepPhysicalLocatorAugmentation physLocatorAug = HwvtepSouthboundUtils
                                    .createHwvtepPhysicalLocatorAugmentation(
                                            String.valueOf(otherDevice.getTunnelIp().getValue()));
                            RemoteUcastMacs remoteUcastMac = HwvtepSouthboundUtils.createRemoteUcastMac(hwVtepNodeId,
                                    localUcastMac.getMacEntryKey().getValue(), localUcastMac.getIpaddr(),
                                    logicalSwitchName, physLocatorAug);
                            lstRemoteUcastMacs.add(remoteUcastMac);
                        }
                    }
                }
            }
        }
        return lstRemoteUcastMacs;
    }

    /**
     * Are MLAG devices.
     *
     * @param l2GatewayDevice
     *            the l2 gateway device
     * @param otherL2GatewayDevice
     *            the other l2 gateway device
     * @return true, if both the specified l2 gateway devices are part of same
     *         MLAG
     */
    public static boolean areMLAGDevices(L2GatewayDevice l2GatewayDevice, L2GatewayDevice otherL2GatewayDevice) {
        // If tunnel IPs are same, then it is considered to be part of same MLAG
        return Objects.equals(l2GatewayDevice.getTunnelIp(), otherL2GatewayDevice.getTunnelIp());
    }

    /**
     * Gets the elan mac table entries as remote ucast macs. <br>
     * Note: ELAN MAC table only contains internal switches MAC's. It doesn't
     * contain external device MAC's.
     *
     * @param elanName
     *            the elan name
     * @param l2GatewayDeviceToBeConfigured
     *            the l2 gateway device to be configured
     * @param hwVtepNodeId
     *            the hw vtep node id
     * @param logicalSwitchName
     *            the logical switch name
     * @return the elan mac table entries as remote ucast macs
     */
    public List<RemoteUcastMacs> getElanMacTableEntriesMacs(String elanName,
            L2GatewayDevice l2GatewayDeviceToBeConfigured, NodeId hwVtepNodeId, String logicalSwitchName) {
        List<RemoteUcastMacs> lstRemoteUcastMacs = new ArrayList<>();

        MacTable macTable = elanUtils.getElanMacTable(elanName);
        if (macTable == null || macTable.getMacEntry() == null || macTable.getMacEntry().isEmpty()) {
            LOG.trace("MacTable is empty for elan: {}", elanName);
            return lstRemoteUcastMacs;
        }

        for (MacEntry macEntry : macTable.getMacEntry()) {
            BigInteger dpnId = elanUtils.getDpidFromInterface(macEntry.getInterface());
            if (dpnId == null) {
                LOG.error("DPN ID not found for interface {}", macEntry.getInterface());
                continue;
            }

            IpAddress dpnTepIp = getSourceDpnTepIp(dpnId, hwVtepNodeId);
            LOG.trace("Dpn Tep IP: {} for dpnId: {} and nodeId: {}", dpnTepIp, dpnId, hwVtepNodeId.getValue());
            if (dpnTepIp == null) {
                LOG.error("TEP IP not found for dpnId {} and nodeId {}", dpnId, hwVtepNodeId.getValue());
                continue;
            }
            HwvtepPhysicalLocatorAugmentation physLocatorAug = HwvtepSouthboundUtils
                    .createHwvtepPhysicalLocatorAugmentation(String.valueOf(dpnTepIp.getValue()));
            // TODO: Query ARP cache to get IP address corresponding to the
            // MAC
            IpAddress ipAddress = null;
            RemoteUcastMacs remoteUcastMac = HwvtepSouthboundUtils.createRemoteUcastMac(hwVtepNodeId,
                    macEntry.getMacAddress().getValue(), ipAddress, logicalSwitchName, physLocatorAug);
            lstRemoteUcastMacs.add(remoteUcastMac);
        }
        return lstRemoteUcastMacs;
    }

    /**
     * Gets the external tunnel interface name.
     *
     * @param sourceNode
     *            the source node
     * @param dstNode
     *            the dst node
     * @return the external tunnel interface name
     */
    public String getExternalTunnelInterfaceName(String sourceNode, String dstNode) {
        Class<? extends TunnelTypeBase> tunType = TunnelTypeVxlan.class;
        String tunnelInterfaceName = null;
        try {
            Future<RpcResult<GetExternalTunnelInterfaceNameOutput>> output = itmRpcService
                    .getExternalTunnelInterfaceName(new GetExternalTunnelInterfaceNameInputBuilder()
                            .setSourceNode(sourceNode).setDestinationNode(dstNode).setTunnelType(tunType).build());

            RpcResult<GetExternalTunnelInterfaceNameOutput> rpcResult = output.get();
            if (rpcResult.isSuccessful()) {
                tunnelInterfaceName = rpcResult.getResult().getInterfaceName();
                LOG.debug("Tunnel interface name: {} for sourceNode: {} and dstNode: {}", tunnelInterfaceName,
                        sourceNode, dstNode);
            } else {
                LOG.warn("RPC call to ITM.GetExternalTunnelInterfaceName failed with error: {}", rpcResult.getErrors());
            }
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.error("Failed to get external tunnel interface name for sourceNode: {} and dstNode: {}: {} ",
                    sourceNode, dstNode, e);
        }
        return tunnelInterfaceName;
    }

    /**
     * Gets the source dpn tep ip.
     *
     * @param srcDpnId
     *            the src dpn id
     * @param dstHwVtepNodeId
     *            the dst hw vtep node id
     * @return the dpn tep ip
     */
    public IpAddress getSourceDpnTepIp(BigInteger srcDpnId, NodeId dstHwVtepNodeId) {
        IpAddress dpnTepIp = null;
        String tunnelInterfaceName = getExternalTunnelInterfaceName(String.valueOf(srcDpnId),
                dstHwVtepNodeId.getValue());
        if (tunnelInterfaceName != null) {
            Interface tunnelInterface = getInterfaceFromConfigDS(new InterfaceKey(tunnelInterfaceName), broker);
            if (tunnelInterface != null) {
                dpnTepIp = tunnelInterface.getAugmentation(IfTunnel.class).getTunnelSource();
            } else {
                LOG.warn("Tunnel interface not found for tunnelInterfaceName {}", tunnelInterfaceName);
            }
        } else {
            LOG.warn("Tunnel interface name not found for srcDpnId {} and dstHwVtepNodeId {}", srcDpnId,
                    dstHwVtepNodeId);
        }
        return dpnTepIp;
    }

    /**
     * Update vlan bindings in l2 gateway device.
     *
     * @param nodeId
     *            the node id
     * @param logicalSwitchName
     *            the logical switch name
     * @param hwVtepDevice
     *            the hardware device
     * @param defaultVlanId
     *            the default vlan id
     * @return the listenable future
     */
    public ListenableFuture<Void> updateVlanBindingsInL2GatewayDevice(NodeId nodeId, String logicalSwitchName,
            Devices hwVtepDevice, Integer defaultVlanId) {
        if (hwVtepDevice == null || hwVtepDevice.getInterfaces() == null || hwVtepDevice.getInterfaces().isEmpty()) {
            String errMsg = "HwVtepDevice is null or interfaces are empty.";
            LOG.error(errMsg);
            return Futures.immediateFailedFuture(new RuntimeException(errMsg));
        }

        WriteTransaction transaction = broker.newWriteOnlyTransaction();
        for (org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712
                 .l2gateway.attributes.devices.Interfaces deviceInterface : hwVtepDevice.getInterfaces()) {
            NodeId physicalSwitchNodeId = HwvtepSouthboundUtils.createManagedNodeId(nodeId,
                    hwVtepDevice.getDeviceName());
            TerminationPoint portTerminationPoint = HwvtepUtils.getPhysicalPortTerminationPoint(broker,
                    LogicalDatastoreType.OPERATIONAL, physicalSwitchNodeId, deviceInterface.getInterfaceName());
            if (portTerminationPoint == null) {
                // port is not present in Hwvtep; don't configure VLAN bindings
                // on this port
                continue;
            }
            List<VlanBindings> vlanBindings = new ArrayList<>();
            if (deviceInterface.getSegmentationIds() != null && !deviceInterface.getSegmentationIds().isEmpty()) {
                for (Integer vlanId : deviceInterface.getSegmentationIds()) {
                    vlanBindings.add(HwvtepSouthboundUtils.createVlanBinding(nodeId, vlanId, logicalSwitchName));
                }
            } else {
                // Use defaultVlanId (specified in L2GatewayConnection) if Vlan
                // ID not specified at interface level.
                vlanBindings.add(HwvtepSouthboundUtils.createVlanBinding(nodeId, defaultVlanId, logicalSwitchName));
            }
            HwvtepUtils.mergeVlanBindings(transaction, nodeId, hwVtepDevice.getDeviceName(),
                    deviceInterface.getInterfaceName(), vlanBindings);
        }
        ListenableFuture<Void> future = transaction.submit();
        LOG.info("Updated Hwvtep VlanBindings in config DS. NodeID: {}, LogicalSwitch: {}", nodeId.getValue(),
                logicalSwitchName);
        return future;
    }

    /**
     * Update vlan bindings in l2 gateway device.
     *
     * @param nodeId
     *            the node id
     * @param psName
     *            the physical switch name
     * @param interfaceName
     *            the interface in physical switch
     * @param vlanBindings
     *            the vlan bindings to be configured
     * @return the listenable future
     */
    public ListenableFuture<Void> updateVlanBindingsInL2GatewayDevice(NodeId nodeId, String psName,
            String interfaceName, List<VlanBindings> vlanBindings) {
        WriteTransaction transaction = broker.newWriteOnlyTransaction();
        HwvtepUtils.mergeVlanBindings(transaction, nodeId, psName, interfaceName, vlanBindings);
        ListenableFuture<Void> future = transaction.submit();
        LOG.info("Updated Hwvtep VlanBindings in config DS. NodeID: {}", nodeId.getValue());
        return future;
    }

    /**
     * Delete vlan bindings from l2 gateway device.
     *
     * @param nodeId
     *            the node id
     * @param hwVtepDevice
     *            the hw vtep device
     * @param defaultVlanId
     *            the default vlan id
     * @return the listenable future
     */
    public ListenableFuture<Void> deleteVlanBindingsFromL2GatewayDevice(NodeId nodeId, Devices hwVtepDevice,
            Integer defaultVlanId) {
        if (hwVtepDevice == null || hwVtepDevice.getInterfaces() == null || hwVtepDevice.getInterfaces().isEmpty()) {
            String errMsg = "HwVtepDevice is null or interfaces are empty.";
            LOG.error(errMsg);
            return Futures.immediateFailedFuture(new RuntimeException(errMsg));
        }
        NodeId physicalSwitchNodeId = HwvtepSouthboundUtils.createManagedNodeId(nodeId, hwVtepDevice.getDeviceName());

        WriteTransaction transaction = broker.newWriteOnlyTransaction();
        for (org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712
                 .l2gateway.attributes.devices.Interfaces deviceInterface : hwVtepDevice.getInterfaces()) {
            String phyPortName = deviceInterface.getInterfaceName();
            if (deviceInterface.getSegmentationIds() != null && !deviceInterface.getSegmentationIds().isEmpty()) {
                for (Integer vlanId : deviceInterface.getSegmentationIds()) {
                    HwvtepUtils.deleteVlanBinding(transaction, physicalSwitchNodeId, phyPortName, vlanId);
                }
            } else {
                // Use defaultVlanId (specified in L2GatewayConnection) if Vlan
                // ID not specified at interface level.
                HwvtepUtils.deleteVlanBinding(transaction, physicalSwitchNodeId, phyPortName, defaultVlanId);
            }
        }
        ListenableFuture<Void> future = transaction.submit();

        LOG.info("Deleted Hwvtep VlanBindings from config DS. NodeID: {}, hwVtepDevice: {}, defaultVlanId: {} ",
                nodeId.getValue(), hwVtepDevice, defaultVlanId);
        return future;
    }

    /**
     * Gets the elan name from logical switch name.
     *
     * @param logicalSwitchName
     *            the logical switch name
     * @return the elan name from logical switch name
     */
    public static String getElanFromLogicalSwitch(String logicalSwitchName) {
        // Assuming elan name is same as logical switch name
        String elanName = logicalSwitchName;
        return elanName;
    }

    /**
     * Gets the logical switch name from elan name.
     *
     * @param elanName
     *            the elan name
     * @return the logical switch from elan name
     */
    public static String getLogicalSwitchFromElan(String elanName) {
        // Assuming logical switch name is same as elan name
        String logicalSwitchName = elanName;
        return logicalSwitchName;
    }

    /**
     * Gets the l2 gateway connection job key.
     *
     * @param nodeId
     *            the node id
     * @param logicalSwitchName
     *            the logical switch name
     * @return the l2 gateway connection job key
     */
    public static String getL2GatewayConnectionJobKey(String nodeId, String logicalSwitchName) {
        return logicalSwitchName;
    }

    public static InstanceIdentifier<Interface> getInterfaceIdentifier(InterfaceKey interfaceKey) {
        InstanceIdentifier.InstanceIdentifierBuilder<Interface> interfaceInstanceIdentifierBuilder = InstanceIdentifier
                .builder(Interfaces.class).child(Interface.class, interfaceKey);
        return interfaceInstanceIdentifierBuilder.build();
    }

    public static Interface getInterfaceFromConfigDS(InterfaceKey interfaceKey, DataBroker dataBroker) {
        InstanceIdentifier<Interface> interfaceId = getInterfaceIdentifier(interfaceKey);
        Optional<Interface> interfaceOptional = IfmUtil.read(LogicalDatastoreType.CONFIGURATION, interfaceId,
                dataBroker);
        if (!interfaceOptional.isPresent()) {
            return null;
        }

        return interfaceOptional.get();
    }

    /**
     * Delete l2 gateway device ucast local macs from elan.<br>
     * Deletes macs from internal ELAN nodes and also on rest of external l2
     * gateway devices which are part of the ELAN.
     *
     * @param l2GatewayDevice
     *            the l2 gateway device whose ucast local macs to be deleted
     *            from elan
     * @param elanName
     *            the elan name
     * @return the listenable future
     */
    public List<ListenableFuture<Void>> deleteL2GwDeviceUcastLocalMacsFromElan(L2GatewayDevice l2GatewayDevice,
            String elanName) {
        LOG.info("Deleting L2GatewayDevice [{}] UcastLocalMacs from elan [{}]", l2GatewayDevice.getHwvtepNodeId(),
                elanName);

        List<ListenableFuture<Void>> futures = new ArrayList<>();
        ElanInstance elan = ElanUtils.getElanInstanceByName(broker, elanName);
        if (elan == null) {
            LOG.error("Could not find Elan by name: {}", elanName);
            return futures;
        }

        List<MacAddress> localMacs = getL2GwDeviceLocalMacs(l2GatewayDevice);
        unInstallL2GwUcastMacFromElan(elan, l2GatewayDevice, localMacs);
        return futures;
    }

    public static void createItmTunnels(ItmRpcService itmRpcService, String hwvtepId, String psName,
            IpAddress tunnelIp) {
        AddL2GwDeviceInputBuilder builder = new AddL2GwDeviceInputBuilder();
        builder.setTopologyId(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID.getValue());
        builder.setNodeId(HwvtepSouthboundUtils.createManagedNodeId(new NodeId(hwvtepId), psName).getValue());
        builder.setIpAddress(tunnelIp);
        try {
            Future<RpcResult<Void>> result = itmRpcService.addL2GwDevice(builder.build());
            RpcResult<Void> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                LOG.info("Created ITM tunnels for {}", hwvtepId);
            } else {
                LOG.error("Failed to create ITM Tunnels: ", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("RPC to create ITM tunnels failed", e);
        }
    }

    public static String getNodeIdFromDpnId(BigInteger dpnId) {
        return MDSALUtil.NODE_PREFIX + MDSALUtil.SEPARATOR + dpnId.toString();
    }

    public void scheduleAddDpnMacInExtDevices(String elanName, BigInteger dpId,
            List<PhysAddress> staticMacAddresses) {
        ConcurrentMap<String, L2GatewayDevice> elanDevices = ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanName);
        for (final L2GatewayDevice externalDevice : elanDevices.values()) {
            scheduleAddDpnMacsInExtDevice(elanName, dpId, staticMacAddresses, externalDevice);
        }
    }

    public void scheduleAddDpnMacsInExtDevice(final String elanName, BigInteger dpId,
            final List<PhysAddress> staticMacAddresses, final L2GatewayDevice externalDevice) {
        NodeId nodeId = new NodeId(externalDevice.getHwvtepNodeId());
        final IpAddress dpnTepIp = getSourceDpnTepIp(dpId, nodeId);
        LOG.trace("Dpn Tep IP: {} for dpnId: {} and nodeId: {}", dpnTepIp, dpId, nodeId);
        if (dpnTepIp == null) {
            LOG.error("could not install dpn mac in l2gw TEP IP not found for dpnId {} and nodeId {}", dpId, nodeId);
            return;
        }
        TerminationPointKey tpKey = HwvtepSouthboundUtils.getTerminationPointKey(dpnTepIp.getIpv4Address().getValue());
        InstanceIdentifier<TerminationPoint> tpPath = HwvtepSouthboundUtils.createTerminationPointId(nodeId, tpKey);

        HwvtepTerminationPointListener.runJobAfterPhysicalLocatorIsAvialable(tpPath, () -> HwvtepUtils
                .installUcastMacs(broker, externalDevice.getHwvtepNodeId(), staticMacAddresses, elanName, dpnTepIp));
    }

    public void scheduleDeleteLogicalSwitch(final NodeId hwvtepNodeId, final String lsName) {
        TimerTask logicalSwitchDeleteTask = new TimerTask() {
            @Override
            public void run() {
                Pair<NodeId, String> nodeIdLogicalSwitchNamePair = new ImmutablePair<>(hwvtepNodeId,
                        lsName);
                logicalSwitchDeletedTasks.remove(nodeIdLogicalSwitchNamePair);

                DeleteLogicalSwitchJob deleteLsJob = new DeleteLogicalSwitchJob(broker, hwvtepNodeId, lsName);
                dataStoreJobCoordinator.enqueueJob(deleteLsJob.getJobKey(), deleteLsJob,
                        SystemPropertyReader.getDataStoreJobCoordinatorMaxRetries());
            }
        };
        Pair<NodeId, String> nodeIdLogicalSwitchNamePair = new ImmutablePair<>(hwvtepNodeId, lsName);
        logicalSwitchDeletedTasks.put(nodeIdLogicalSwitchNamePair, logicalSwitchDeleteTask);
        LogicalSwitchDeleteJobTimer.schedule(logicalSwitchDeleteTask, LOGICAL_SWITCH_DELETE_DELAY);
    }

    public void cancelDeleteLogicalSwitch(final NodeId hwvtepNodeId, final String lsName) {
        Pair<NodeId, String> nodeIdLogicalSwitchNamePair = new ImmutablePair<>(hwvtepNodeId, lsName);
        TimerTask logicalSwitchDeleteTask = logicalSwitchDeletedTasks.get(nodeIdLogicalSwitchNamePair);
        if (logicalSwitchDeleteTask != null) {
            LOG.debug("Delete logical switch {} action on node {} cancelled", lsName, hwvtepNodeId);
            logicalSwitchDeleteTask.cancel();
            logicalSwitchDeletedTasks.remove(nodeIdLogicalSwitchNamePair);
        }
    }
}
