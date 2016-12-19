/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.ipv6service;

import java.math.BigInteger;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6ServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ipv6ServiceInterfaceEventListener
        extends AsyncDataTreeChangeListenerBase<Interface, Ipv6ServiceInterfaceEventListener>
        implements ClusteredDataTreeChangeListener<Interface>, AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(Ipv6ServiceInterfaceEventListener.class);
    private final DataBroker dataBroker;
    private final IfMgr ifMgr;

    /**
     * Intialize the member variables.
     * @param broker the data broker instance.
     */
    public Ipv6ServiceInterfaceEventListener(DataBroker broker) {
        super(Interface.class, Ipv6ServiceInterfaceEventListener.class);
        this.dataBroker = broker;
        ifMgr = IfMgr.getIfMgrInstance();
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
    protected void remove(InstanceIdentifier<Interface> key, Interface del) {
        LOG.debug("Port removed {}, {}", key, del);
    }

    @Override
    protected void update(InstanceIdentifier<Interface> key, Interface dataObjectModificationBefore,
                          Interface dataObjectModificationAfter) {
        // TODO Auto-generated method stub
        LOG.debug("Port updated...");
    }

    private boolean isNeutronPort(String name) {
        try {
            Uuid portId = new Uuid(name);
            return true;
        } catch (IllegalArgumentException e) {
            LOG.debug("Port {} is not a Neutron Port, skipping.", name);
        }
        return false;
    }

    @Override
    protected void add(InstanceIdentifier<Interface> key, Interface add) {
        LOG.debug("Port added {}, {}", key, add);
        List<String> ofportIds = add.getLowerLayerIf();
        // When a port is created, we receive multiple notifications.
        // In ipv6service, we are only interested in the notification for NeutronPort, so we skip other notifications
        if (ofportIds == null || ofportIds.isEmpty() || !isNeutronPort(add.getName())) {
            return;
        }

        if (add.getType() != null && add.getType().equals(Tunnel.class)) {
            LOG.info("iface {} is a tunnel interface, skipping.", add);
            return;
        }

        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface iface;
        iface = Ipv6ServiceUtils.getInterface(dataBroker, add.getName());
        if (null != iface) {
            LOG.debug("Port added {}", iface);
            NodeConnectorId nodeConnectorId = new NodeConnectorId(ofportIds.get(0));
            BigInteger dpId = BigInteger.valueOf(MDSALUtil.getDpnIdFromPortName(nodeConnectorId));

            if (!dpId.equals(Ipv6Constants.INVALID_DPID)) {
                Uuid portId = new Uuid(iface.getName());
                VirtualPort port = ifMgr.obtainV6Interface(portId);
                if (port == null) {
                    LOG.info("Port {} not found, skipping.", portId);
                    return;
                }

                Long ofPort = MDSALUtil.getOfPortNumberFromPortName(nodeConnectorId);
                ifMgr.updateInterface(portId, dpId, ofPort);

                VirtualPort routerPort = ifMgr.getRouterV6InterfaceForNetwork(port.getNetworkID());
                if (routerPort == null) {
                    LOG.info("Port {} is not associated to a Router, skipping.", routerPort);
                    return;
                }
                // Check and program icmpv6 punt flows on the dpnID if its the first VM on the host.
                ifMgr.programIcmpv6PuntFlowsIfNecessary(portId, dpId, routerPort);
            }
        }
    }

    @Override
    protected Ipv6ServiceInterfaceEventListener getDataTreeChangeListener() {
        return Ipv6ServiceInterfaceEventListener.this;
    }
}
