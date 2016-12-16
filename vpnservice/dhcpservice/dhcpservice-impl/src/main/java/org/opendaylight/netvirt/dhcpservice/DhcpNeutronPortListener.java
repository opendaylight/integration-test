/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import java.math.BigInteger;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.binding.rev150712.PortBindingExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpNeutronPortListener
        extends AsyncClusteredDataTreeChangeListenerBase<Port, DhcpNeutronPortListener> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpNeutronPortListener.class);

    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;
    private final DataBroker broker;

    public DhcpNeutronPortListener(final DataBroker db, final DhcpExternalTunnelManager dhcpExternalTunnelManager) {
        super(Port.class, DhcpNeutronPortListener.class);
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.broker = db;
    }

    public void init() {
        registerListener(LogicalDatastoreType.CONFIGURATION, broker);
    }

    @Override
    protected InstanceIdentifier<Port> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Ports.class).child(Port.class);
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.debug("DhcpNeutronPortListener Listener Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<Port> identifier, Port del) {
        LOG.trace("Port removed: {}", del);
        if (isVnicTypeDirectOrMacVtap(del)) {
            removePort(del);
        }
    }

    @Override
    protected void update(InstanceIdentifier<Port> identifier, Port original, Port update) {
        LOG.trace("Port changed to {}", update);
        if (!isVnicTypeDirectOrMacVtap(update)) {
            LOG.trace("Port updated is normal {}", update.getUuid());
            if (isVnicTypeDirectOrMacVtap(original)) {
                LOG.trace("Original Port was direct/macvtap {} so removing flows and cache entry if any",
                        update.getUuid());
                removePort(original);
            }
            return;
        }
        if (!isVnicTypeDirectOrMacVtap((original))) {
            LOG.trace("Original port was normal and updated is direct. Calling addPort()");
            addPort(update);
            return;
        }
        String macOriginal = getMacAddress(original);
        String macUpdated = getMacAddress(update);
        String segmentationIdOriginal = DhcpServiceUtils.getSegmentationId(original.getNetworkId(), broker);
        String segmentationIdUpdated = DhcpServiceUtils.getSegmentationId(update.getNetworkId(), broker);
        if (macOriginal != null && !macOriginal.equalsIgnoreCase(macUpdated) && segmentationIdOriginal != null
                && !segmentationIdOriginal.equalsIgnoreCase(segmentationIdUpdated)) {
            LOG.trace("Mac/segment id has changed");
            dhcpExternalTunnelManager.removeVniMacToPortCache(new BigInteger(segmentationIdOriginal), macOriginal);
            dhcpExternalTunnelManager.updateVniMacToPortCache(new BigInteger(segmentationIdUpdated),
                    macUpdated, update);
        }
    }

    @Override
    protected void add(InstanceIdentifier<Port> identifier, Port add) {
        LOG.trace("Port added {}", add);
        if (!isVnicTypeDirectOrMacVtap(add)) {
            return;
        }
        addPort(add);
    }

    private void removePort(Port port) {
        String macAddress = getMacAddress(port);
        Uuid networkId = port.getNetworkId();
        String segmentationId = DhcpServiceUtils.getSegmentationId(networkId, broker);
        if (segmentationId == null) {
            return;
        }
        List<BigInteger> listOfDpns = DhcpServiceUtils.getListOfDpns(broker);
        dhcpExternalTunnelManager.unInstallDhcpFlowsForVms(networkId.getValue(), listOfDpns, macAddress);
        dhcpExternalTunnelManager.removeVniMacToPortCache(new BigInteger(segmentationId), macAddress);
    }

    private void addPort(Port port) {
        String macAddress = getMacAddress(port);
        Uuid networkId = port.getNetworkId();
        String segmentationId = DhcpServiceUtils.getSegmentationId(networkId, broker);
        if (segmentationId == null) {
            LOG.trace("segmentation id is null");
            return;
        }
        dhcpExternalTunnelManager.updateVniMacToPortCache(new BigInteger(segmentationId), macAddress, port);
    }

    private String getMacAddress(Port port) {
        return port.getMacAddress().getValue();
    }

    private boolean isVnicTypeDirectOrMacVtap(Port port) {
        PortBindingExtension portBinding = port.getAugmentation(PortBindingExtension.class);
        if (portBinding == null || portBinding.getVnicType() == null) {
            // By default, VNIC_TYPE is NORMAL
            return false;
        }
        String vnicType = portBinding.getVnicType().trim().toLowerCase();
        return (vnicType.equals("direct") || vnicType.equals("macvtap"));
    }

    @Override
    protected DhcpNeutronPortListener getDataTreeChangeListener() {
        return DhcpNeutronPortListener.this;
    }
}