/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.listeners;

import com.google.common.collect.Lists;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.hwvtep.HwvtepClusteredDataTreeChangeListener;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * A listener for Ucast MAC entries that are added/removed to/from an External
 * Device (e.g., TOR).
 *
 * <p>When a Ucast MAC addr appears in the hwvtep's operational DS, that MAC must
 * be populated in DMAC tables in all Elan participating DPNs. ELAN is selected
 * according to field 'tunnel_key' of the Logical Switch to which the new MAC
 * belongs.
 */
public class HwvtepLocalUcastMacListener extends
        HwvtepClusteredDataTreeChangeListener<LocalUcastMacs, HwvtepLocalUcastMacListener> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(HwvtepLocalUcastMacListener.class);

    private final DataBroker broker;
    private final ElanL2GatewayUtils elanL2GatewayUtils;

    public HwvtepLocalUcastMacListener(DataBroker broker, ElanUtils elanUtils) {
        super(LocalUcastMacs.class, HwvtepLocalUcastMacListener.class);

        this.broker = broker;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    protected void removed(InstanceIdentifier<LocalUcastMacs> identifier, LocalUcastMacs macRemoved) {
        String hwvtepNodeId = identifier.firstKeyOf(Node.class).getNodeId().getValue();
        String macAddress = macRemoved.getMacEntryKey().getValue();

        LOG.trace("LocalUcastMacs {} removed from {}", macAddress, hwvtepNodeId);

        ElanInstance elan = elanL2GatewayUtils.getElanInstanceForUcastLocalMac(macRemoved);
        if (elan == null) {
            LOG.warn("Could not find ELAN for mac {} being deleted", macAddress);
            return;
        }

        String elanName = elan.getElanInstanceName();
        L2GatewayDevice elanL2GwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanName, hwvtepNodeId);
        if (elanL2GwDevice == null) {
            LOG.warn("Could not find L2GatewayDevice for ELAN: {}, nodeID:{} from cache", elanName, hwvtepNodeId);
            return;
        }

        // Remove MAC from cache
        elanL2GwDevice.removeUcastLocalMac(macRemoved);

        elanL2GatewayUtils.unInstallL2GwUcastMacFromElan(elan, elanL2GwDevice,
                Lists.newArrayList(macRemoved.getMacEntryKey()));
    }

    @Override
    protected void updated(InstanceIdentifier<LocalUcastMacs> identifier, LocalUcastMacs original,
            LocalUcastMacs update) {
        // TODO (eperefr) what can change here?

    }

    @Override
    protected void added(InstanceIdentifier<LocalUcastMacs> identifier, LocalUcastMacs macAdded) {
        String hwvtepNodeId = identifier.firstKeyOf(Node.class).getNodeId().getValue();
        String macAddress = macAdded.getMacEntryKey().getValue();

        LOG.trace("LocalUcastMacs {} added to {}", macAddress, hwvtepNodeId);

        ElanInstance elan = elanL2GatewayUtils.getElanInstanceForUcastLocalMac(macAdded);
        if (elan == null) {
            LOG.warn("Could not find ELAN for mac {} being added", macAddress);
            return;
        }

        String elanName = elan.getElanInstanceName();
        L2GatewayDevice elanL2GwDevice = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanName, hwvtepNodeId);
        if (elanL2GwDevice == null) {
            LOG.warn("Could not find L2GatewayDevice for ELAN: {}, nodeID:{} from cache", elanName, hwvtepNodeId);
            return;
        }

        // Cache MAC for furthur processing later
        elanL2GwDevice.addUcastLocalMac(macAdded);

        elanL2GatewayUtils.installL2GwUcastMacInElan(elan, elanL2GwDevice, macAddress, null);
    }

    @Override
    protected InstanceIdentifier<LocalUcastMacs> getWildCardPath() {
        return HwvtepUtils.getWildCardPathForLocalUcastMacs();
    }

    @Override
    protected HwvtepLocalUcastMacListener getDataTreeChangeListener() {
        return this;
    }
}
