/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;

import com.google.common.base.Optional;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubnetRouteInterfaceStateChangeListener extends AsyncDataTreeChangeListenerBase<Interface,
              SubnetRouteInterfaceStateChangeListener> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(SubnetRouteInterfaceStateChangeListener.class);
    private final DataBroker dataBroker;
    private final VpnInterfaceManager vpnInterfaceManager;
    private final VpnSubnetRouteHandler vpnSubnetRouteHandler;

    public SubnetRouteInterfaceStateChangeListener(final DataBroker dataBroker,
                                                   final VpnInterfaceManager vpnInterfaceManager,
                                                   final VpnSubnetRouteHandler vpnSubnetRouteHandler) {
        super(Interface.class, SubnetRouteInterfaceStateChangeListener.class);
        this.dataBroker = dataBroker;
        this.vpnInterfaceManager = vpnInterfaceManager;
        this.vpnSubnetRouteHandler = vpnSubnetRouteHandler;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Interface> getWildCardPath() {
        return InstanceIdentifier.create(InterfacesState.class).child(Interface.class);
    }

    @Override
    protected SubnetRouteInterfaceStateChangeListener getDataTreeChangeListener() {
        return SubnetRouteInterfaceStateChangeListener.this;
    }

    @Override
    protected void add(InstanceIdentifier<Interface> identifier, Interface intrf) {
        LOG.trace("SubnetRouteInterfaceListener add: Received interface {} up event", intrf);
        try {
            String interfaceName = intrf.getName();
            LOG.info("SubnetRouteInterfaceListener add: Received port UP event for interface {} ", interfaceName);
            org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface
                    configInterface = InterfaceUtils.getInterface(dataBroker, interfaceName);
            if (configInterface != null && (configInterface.getType() != null)) {
                if (!configInterface.getType().equals(Tunnel.class)) {
                    final VpnInterface vpnInterface = VpnUtil.getConfiguredVpnInterface(dataBroker, interfaceName);
                    if (vpnInterface != null) {
                        BigInteger dpnId = BigInteger.ZERO;
                        try {
                            dpnId = InterfaceUtils.getDpIdFromInterface(intrf);
                        } catch (Exception e) {
                            LOG.error("SubnetRouteInterfaceListener add: Unable to obtain dpnId for interface {},",
                                    " subnetroute inclusion for this interface failed with exception {}",
                                    interfaceName, e);
                            return;
                        }
                        vpnSubnetRouteHandler.onInterfaceUp(dpnId, intrf.getName());
                    }
                }
            }
        } catch (Exception e) {
            LOG.error("SubnetRouteInterfaceListener add: Exception observed in handling addition for VPN Interface {}. ", intrf.getName(), e);
        }
    }

    @Override
    protected void remove(InstanceIdentifier<Interface> identifier, Interface intrf) {
        LOG.trace("SubnetRouteInterfaceListener remove: Received interface {} down event", intrf);
        try {
            String interfaceName = intrf.getName();
            BigInteger dpnId = BigInteger.ZERO;
            LOG.info("SubnetRouteInterfaceListener remove: Received port DOWN event for interface {} ", interfaceName);
            if (intrf != null && intrf.getType() != null && (!intrf.getType().equals(Tunnel.class))) {
                InstanceIdentifier<VpnInterface> id = VpnUtil.getVpnInterfaceIdentifier(interfaceName);
                Optional<VpnInterface> optVpnInterface = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
                if (!optVpnInterface.isPresent()) {
                    LOG.debug("SubnetRouteInterfaceListener remove: Interface {} is not a vpninterface, ignoring.", intrf.getName());
                    return;
                }
                VpnInterface vpnInterface = optVpnInterface.get();
                try {
                    dpnId = InterfaceUtils.getDpIdFromInterface(intrf);
                } catch (Exception e) {
                    LOG.error("SubnetRouteInterfaceListener remove: Unable to retrieve dpnId for interface {}. " +
                                    "Fetching from vpn interface itself due to exception {}",
                            intrf.getName(), e);
                    dpnId = vpnInterface.getDpnId();
                }
                vpnSubnetRouteHandler.onInterfaceDown(dpnId, intrf.getName());
            }
        } catch (Exception e) {
            LOG.error("SubnetRouteInterfaceListener remove: Exception observed in handling deletion of VPN Interface {}. ",
                    intrf.getName(), e);
        }
    }

    @Override
    protected void update(InstanceIdentifier<Interface> identifier,
                          Interface original, Interface update) {
        LOG.trace("SubnetRouteInterfaceListener update: Operation Interface update event - Old: {}, New: {}", original, update);
        String interfaceName = update.getName();
        BigInteger dpnId = BigInteger.ZERO;
        if (update != null && (update.getType() != null)) {
            if (!update.getType().equals(Tunnel.class)) {
                final VpnInterface vpnInterface = VpnUtil.getConfiguredVpnInterface(dataBroker, interfaceName);
                if (vpnInterface != null) {
                    if (update.getOperStatus().equals(Interface.OperStatus.Up)) {
                        try {
                            dpnId = InterfaceUtils.getDpIdFromInterface(update);
                        } catch (Exception e) {
                            LOG.error("SubnetRouteInterfaceListener update: Unable to obtain dpnId for interface {} port up,",
                                    " subnetroute inclusion for this interface failed with exception {}",
                                    interfaceName, e);
                            return;
                        }
                        vpnSubnetRouteHandler.onInterfaceUp(dpnId, update.getName());
                    } else if (update.getOperStatus().equals(Interface.OperStatus.Down)) {
                        try {
                            dpnId = InterfaceUtils.getDpIdFromInterface(update);
                        } catch (Exception e) {
                            LOG.error("SubnetRouteInterfaceListener update: Unable to obtain dpnId for interface {} port down,",
                                    " subnetroute exclusion for this interface failed with exception {}",
                                    interfaceName, e);
                            return;
                        }
                        vpnSubnetRouteHandler.onInterfaceDown(dpnId, update.getName());
                    }
                }
            }
        }
    }
}
