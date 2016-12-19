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
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundUtils;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.elan.internal.ElanInstanceManager;
import org.opendaylight.netvirt.elan.internal.ElanInterfaceManager;
import org.opendaylight.netvirt.elan.l2gw.jobs.HwvtepDeviceMcastMacUpdateJob;
import org.opendaylight.netvirt.elan.utils.ElanConstants;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.DesignatedSwitchesForExternalTunnels;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.designated.switches._for.external.tunnels.DesignatedSwitchForTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.designated.switches._for.external.tunnels.DesignatedSwitchForTunnelKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSetBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The utility class to handle ELAN L2 Gateway related to multicast.
 */
public class ElanL2GatewayMulticastUtils {

    /** The Constant LOG. */
    private static final Logger LOG = LoggerFactory.getLogger(ElanL2GatewayMulticastUtils.class);

    /** The broker. */
    private final DataBroker broker;

    /** The elan instance manager. */
    private final ElanInstanceManager elanInstanceManager;

    /** The elan interface manager. */
    private final ElanInterfaceManager elanInterfaceManager;

    private final ElanUtils elanUtils;

    private ElanL2GatewayUtils elanL2GatewayUtils;

    public ElanL2GatewayMulticastUtils(DataBroker broker, ElanInstanceManager elanInstanceManager,
                                       ElanInterfaceManager elanInterfaceManager,
                                       ElanUtils elanUtils) {
        this.broker = broker;
        this.elanInstanceManager = elanInstanceManager;
        this.elanInterfaceManager = elanInterfaceManager;
        this.elanUtils = elanUtils;
    }

    public void setEElanL2GatewayUtils(ElanL2GatewayUtils elanL2GatewayUtils) {
        this.elanL2GatewayUtils = elanL2GatewayUtils;
    }

    /**
     * Handle mcast for elan l2 gw device add.
     *
     * @param elanName
     *            the elan name
     * @param device
     *            the device
     * @return the listenable future
     */
    public ListenableFuture<Void> handleMcastForElanL2GwDeviceAdd(String elanName, L2GatewayDevice device) {
        return updateMcastMacsForAllElanDevices(elanName, device, true/* updateThisDevice */);
    }

    /**
     * Updates the remote mcast mac table for all the devices in this elan
     * includes all the dpn tep ips and other devices tep ips in broadcast
     * locator set.
     *
     * @param elanName
     *            the elan to be updated
     * @return the listenable future
     */
    @SuppressWarnings("checkstyle:IllegalCatch")
    public ListenableFuture<Void> updateRemoteMcastMacOnElanL2GwDevices(String elanName) {
        try {
            WriteTransaction transaction = broker.newWriteOnlyTransaction();
            for (L2GatewayDevice device : ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanName).values()) {
                prepareRemoteMcastMacUpdateOnDevice(transaction, elanName, device);
            }
            return transaction.submit();
        } catch (RuntimeException e) {
            LOG.error("Failed to configure mcast mac on elan " + elanName, e);
            return Futures.immediateFailedCheckedFuture(e);
        }
    }

    public void scheduleMcastMacUpdateJob(String elanName, L2GatewayDevice device) {
        HwvtepDeviceMcastMacUpdateJob job = new HwvtepDeviceMcastMacUpdateJob(this, elanName,device);
        DataStoreJobCoordinator.getInstance().enqueueJob(job.getJobKey(), job);
    }

    /**
     * Update remote mcast mac on elan l2 gw device.
     *
     * @param elanName
     *            the elan name
     * @param device
     *            the device
     * @return the listenable future
     */
    public ListenableFuture<Void> updateRemoteMcastMacOnElanL2GwDevice(String elanName, L2GatewayDevice device) {
        WriteTransaction transaction = broker.newWriteOnlyTransaction();
        prepareRemoteMcastMacUpdateOnDevice(transaction, elanName, device);
        return transaction.submit();
    }

    public void prepareRemoteMcastMacUpdateOnDevice(WriteTransaction transaction,String elanName,
                                                           L2GatewayDevice device) {
        ConcurrentMap<String, L2GatewayDevice> elanL2gwDevices = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanName);
        List<DpnInterfaces> dpns = elanUtils.getInvolvedDpnsInElan(elanName);
        List<IpAddress> dpnsTepIps = getAllTepIpsOfDpns(device, dpns);
        List<IpAddress> l2GwDevicesTepIps = getAllTepIpsOfL2GwDevices(elanL2gwDevices);
        preapareRemoteMcastMacEntry(transaction, elanName, device, dpnsTepIps, l2GwDevicesTepIps);
    }

    /**
     * Update mcast macs for this elan.
     * for all dpns in this elan  recompute and update broadcast group
     * for all l2gw devices in this elan recompute and update remote mcast mac entry
     *
     * @param elanName
     *            the elan name
     * @param device
     *            the device
     * @param updateThisDevice
     *            the update this device
     * @return the listenable future
     */
    public ListenableFuture<Void> updateMcastMacsForAllElanDevices(String elanName, L2GatewayDevice device,
                                                                          boolean updateThisDevice) {

        SettableFuture<Void> ft = SettableFuture.create();
        ft.set(null);

        ElanInstance elanInstance = elanInstanceManager.getElanInstanceByName(elanName);
        elanInterfaceManager.updateRemoteBroadcastGroupForAllElanDpns(elanInstance);

        List<DpnInterfaces> dpns = elanUtils.getInvolvedDpnsInElan(elanName);

        ConcurrentMap<String, L2GatewayDevice> devices = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanName);

        List<IpAddress> dpnsTepIps = getAllTepIpsOfDpns(device, dpns);
        List<IpAddress> l2GwDevicesTepIps = getAllTepIpsOfL2GwDevices(devices);
        // if (allTepIps.size() < 2) {
        // LOG.debug("no other devices are found in the elan {}", elanName);
        // return ft;
        // }

        WriteTransaction transaction = broker.newWriteOnlyTransaction();
        if (updateThisDevice) {
            preapareRemoteMcastMacEntry(transaction, elanName, device, dpnsTepIps, l2GwDevicesTepIps);
        }

        // TODO: Need to revisit below logic as logical switches might not be
        // present to configure RemoteMcastMac entry
        for (L2GatewayDevice otherDevice : devices.values()) {
            if (!otherDevice.getDeviceName().equals(device.getDeviceName())) {
                preapareRemoteMcastMacEntry(transaction, elanName, otherDevice, dpnsTepIps, l2GwDevicesTepIps);
            }
        }
        return transaction.submit();

    }

    /**
     * Update remote mcast mac.
     *
     * @param transaction
     *            the transaction
     * @param elanName
     *            the elan name
     * @param device
     *            the device
     * @param dpnsTepIps
     *            the dpns tep ips
     * @param l2GwDevicesTepIps
     *            the l2 gw devices tep ips
     * @return the write transaction
     */
    private void preapareRemoteMcastMacEntry(WriteTransaction transaction, String elanName,
                                                    L2GatewayDevice device, List<IpAddress> dpnsTepIps,
                                                    List<IpAddress> l2GwDevicesTepIps) {
        NodeId nodeId = new NodeId(device.getHwvtepNodeId());

        ArrayList<IpAddress> remoteTepIps = new ArrayList<>(l2GwDevicesTepIps);
        remoteTepIps.remove(device.getTunnelIp());
        remoteTepIps.addAll(dpnsTepIps);
        if (dpnsTepIps.isEmpty()) {
            // If no dpns in elan, configure dhcp designated switch Tep Ip as a
            // physical locator in l2 gw device
            IpAddress dhcpDesignatedSwitchTepIp = getTepIpOfDesignatedSwitchForExternalTunnel(device, elanName);
            if (dhcpDesignatedSwitchTepIp != null) {
                remoteTepIps.add(dhcpDesignatedSwitchTepIp);

                HwvtepPhysicalLocatorAugmentation phyLocatorAug = HwvtepSouthboundUtils
                        .createHwvtepPhysicalLocatorAugmentation(String.valueOf(dhcpDesignatedSwitchTepIp.getValue()));
                HwvtepUtils.putPhysicalLocator(transaction, nodeId, phyLocatorAug);

                LOG.info("Adding PhysicalLocator for node: {} with Dhcp designated switch Tep Ip {} "
                        + "as physical locator, elan {}", device.getHwvtepNodeId(),
                        String.valueOf(dhcpDesignatedSwitchTepIp.getValue()), elanName);
            } else {
                LOG.warn("Dhcp designated switch Tep Ip not found for l2 gw node {} and elan {}",
                        device.getHwvtepNodeId(), elanName);
            }
        }

        String logicalSwitchName = elanL2GatewayUtils.getLogicalSwitchFromElan(elanName);
        putRemoteMcastMac(transaction, nodeId, logicalSwitchName, remoteTepIps);
        LOG.info("Adding RemoteMcastMac for node: {} with physical locators: {}", device.getHwvtepNodeId(),
                remoteTepIps);
    }

    /**
     * Put remote mcast mac in config DS.
     *
     * @param transaction
     *            the transaction
     * @param nodeId
     *            the node id
     * @param logicalSwitchName
     *            the logical switch name
     * @param tepIps
     *            the tep ips
     */
    private static void putRemoteMcastMac(WriteTransaction transaction, NodeId nodeId, String logicalSwitchName,
            ArrayList<IpAddress> tepIps) {
        List<LocatorSet> locators = new ArrayList<>();
        for (IpAddress tepIp : tepIps) {
            HwvtepPhysicalLocatorAugmentation phyLocatorAug = HwvtepSouthboundUtils
                    .createHwvtepPhysicalLocatorAugmentation(String.valueOf(tepIp.getValue()));
            HwvtepPhysicalLocatorRef phyLocRef = new HwvtepPhysicalLocatorRef(
                    HwvtepSouthboundUtils.createPhysicalLocatorInstanceIdentifier(nodeId, phyLocatorAug));
            locators.add(new LocatorSetBuilder().setLocatorRef(phyLocRef).build());
        }

        HwvtepLogicalSwitchRef lsRef = new HwvtepLogicalSwitchRef(HwvtepSouthboundUtils
                .createLogicalSwitchesInstanceIdentifier(nodeId, new HwvtepNodeName(logicalSwitchName)));
        RemoteMcastMacs remoteUcastMac = new RemoteMcastMacsBuilder()
                .setMacEntryKey(new MacAddress(ElanConstants.UNKNOWN_DMAC)).setLogicalSwitchRef(lsRef)
                .setLocatorSet(locators).build();
        HwvtepUtils.putRemoteMcastMac(transaction, nodeId, remoteUcastMac);
    }

    /**
     * Gets all the tep ips of dpns.
     *
     * @param l2GwDevice
     *            the device
     * @param dpns
     *            the dpns
     * @return the all tep ips of dpns and devices
     */
    private List<IpAddress> getAllTepIpsOfDpns(L2GatewayDevice l2GwDevice, List<DpnInterfaces> dpns) {
        List<IpAddress> tepIps = new ArrayList<>();
        for (DpnInterfaces dpn : dpns) {
            IpAddress internalTunnelIp = elanL2GatewayUtils.getSourceDpnTepIp(dpn.getDpId(),
                    new NodeId(l2GwDevice.getHwvtepNodeId()));
            if (internalTunnelIp != null) {
                tepIps.add(internalTunnelIp);
            }
        }
        return tepIps;
    }

    /**
     * Gets the all tep ips of l2 gw devices.
     *
     * @param devices
     *            the devices
     * @return the all tep ips of l2 gw devices
     */
    private static List<IpAddress> getAllTepIpsOfL2GwDevices(ConcurrentMap<String, L2GatewayDevice> devices) {
        List<IpAddress> tepIps = new ArrayList<>();
        for (L2GatewayDevice otherDevice : devices.values()) {
            tepIps.add(otherDevice.getTunnelIp());
        }
        return tepIps;
    }

    /**
     * Handle mcast for elan l2 gw device delete.
     *
     * @param elanName
     *            the elan instance name
     * @param l2GatewayDevice
     *            the l2 gateway device
     * @return the listenable future
     */
    public List<ListenableFuture<Void>> handleMcastForElanL2GwDeviceDelete(String elanName,
            L2GatewayDevice l2GatewayDevice) {
        ListenableFuture<Void> updateMcastMacsFuture = updateMcastMacsForAllElanDevices(
                elanName, l2GatewayDevice, false/* updateThisDevice */);
        ListenableFuture<Void> deleteRemoteMcastMacFuture = deleteRemoteMcastMac(
                new NodeId(l2GatewayDevice.getHwvtepNodeId()), elanName);
        return Lists.newArrayList(updateMcastMacsFuture, deleteRemoteMcastMacFuture);
    }

    /**
     * Delete remote mcast mac from Hwvtep node.
     *
     * @param nodeId
     *            the node id
     * @param logicalSwitchName
     *            the logical switch name
     * @return the listenable future
     */
    private ListenableFuture<Void> deleteRemoteMcastMac(NodeId nodeId, String logicalSwitchName) {
        InstanceIdentifier<LogicalSwitches> logicalSwitch = HwvtepSouthboundUtils
                .createLogicalSwitchesInstanceIdentifier(nodeId, new HwvtepNodeName(logicalSwitchName));
        RemoteMcastMacsKey remoteMcastMacsKey = new RemoteMcastMacsKey(new HwvtepLogicalSwitchRef(logicalSwitch),
                new MacAddress(ElanConstants.UNKNOWN_DMAC));

        LOG.info("Deleting RemoteMcastMacs entry on node: {} for logical switch: {}", nodeId.getValue(),
                logicalSwitchName);
        return HwvtepUtils.deleteRemoteMcastMac(broker, nodeId, remoteMcastMacsKey);
    }

    /**
     * Gets the tep ip of designated switch for external tunnel.
     *
     * @param l2GwDevice
     *            the l2 gw device
     * @param elanInstanceName
     *            the elan instance name
     * @return the tep ip of designated switch for external tunnel
     */
    public IpAddress getTepIpOfDesignatedSwitchForExternalTunnel(L2GatewayDevice l2GwDevice,
            String elanInstanceName) {
        IpAddress tepIp = null;
        if (l2GwDevice.getTunnelIp() == null) {
            LOG.warn("Tunnel IP not found for {}", l2GwDevice.getDeviceName());
            return tepIp;
        }
        DesignatedSwitchForTunnel desgSwitch = getDesignatedSwitchForExternalTunnel(l2GwDevice.getTunnelIp(),
                elanInstanceName);
        if (desgSwitch != null) {
            tepIp = elanL2GatewayUtils.getSourceDpnTepIp(BigInteger.valueOf(desgSwitch.getDpId()),
                    new NodeId(l2GwDevice.getHwvtepNodeId()));
        }
        return tepIp;
    }

    /**
     * Gets the designated switch for external tunnel.
     *
     * @param tunnelIp
     *            the tunnel ip
     * @param elanInstanceName
     *            the elan instance name
     * @return the designated switch for external tunnel
     */
    public DesignatedSwitchForTunnel getDesignatedSwitchForExternalTunnel(IpAddress tunnelIp,
            String elanInstanceName) {
        InstanceIdentifier<DesignatedSwitchForTunnel> instanceIdentifier = InstanceIdentifier
                .builder(DesignatedSwitchesForExternalTunnels.class)
                .child(DesignatedSwitchForTunnel.class, new DesignatedSwitchForTunnelKey(elanInstanceName, tunnelIp))
                .build();
        Optional<DesignatedSwitchForTunnel> designatedSwitchForTunnelOptional = MDSALUtil.read(broker,
                LogicalDatastoreType.CONFIGURATION, instanceIdentifier);
        if (designatedSwitchForTunnelOptional.isPresent()) {
            return designatedSwitchForTunnelOptional.get();
        }
        return null;
    }

}
