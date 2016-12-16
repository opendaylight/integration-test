/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterInterfacesMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class NatRouterInterfaceListener extends AsyncDataTreeChangeListenerBase<Interfaces, NatRouterInterfaceListener> {
    private static final Logger LOG = LoggerFactory.getLogger(NatRouterInterfaceListener.class);
    private final DataBroker dataBroker;
    private final OdlInterfaceRpcService interfaceManager;

    public NatRouterInterfaceListener(final DataBroker dataBroker, final OdlInterfaceRpcService interfaceManager) {
        super(Interfaces.class, NatRouterInterfaceListener.class);
        this.dataBroker = dataBroker;
        this.interfaceManager = interfaceManager;
    }

    @Override
    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected NatRouterInterfaceListener getDataTreeChangeListener() {
        return NatRouterInterfaceListener.this;
    }

    @Override
    protected InstanceIdentifier<Interfaces> getWildCardPath() {
        return InstanceIdentifier.create(RouterInterfacesMap.class).child(RouterInterfaces.class).child(Interfaces.class);
    }

    @Override
    protected void add(InstanceIdentifier<Interfaces> identifier, Interfaces interfaceInfo) {
        LOG.trace("NAT Service : Add event - key: {}, value: {}", identifier, interfaceInfo);
        final String routerId = identifier.firstKeyOf(RouterInterfaces.class).getRouterId().getValue();
        final String interfaceName = interfaceInfo.getInterfaceId();

        try {
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, NatUtil.getRouterInterfaceId(interfaceName),
                    getRouterInterface(interfaceName, routerId));
        }catch (Exception e){
            LOG.error("NAT Service : Unable to write data in RouterInterface model", e.getMessage());
        }

        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface interfaceState =
                NatUtil.getInterfaceStateFromOperDS(dataBroker, interfaceName);
        WriteTransaction writeOperTxn = dataBroker.newWriteOnlyTransaction();
        if (interfaceState!= null) {
            NatUtil.addToNeutronRouterDpnsMap(dataBroker, routerId, interfaceName, interfaceManager, writeOperTxn);
            NatUtil.addToDpnRoutersMap(dataBroker, routerId, interfaceName, interfaceManager, writeOperTxn);
        }else{
            LOG.warn("NAT Service : Interface {} not yet operational to handle router interface add event in router {}",
                    interfaceName, routerId);
        }

        writeOperTxn.submit();

    }

    @Override
    protected void remove(InstanceIdentifier<Interfaces> identifier, Interfaces interfaceInfo) {
        LOG.trace("NAT Service : Remove event - key: {}, value: {}", identifier, interfaceInfo);
        final String routerId = identifier.firstKeyOf(RouterInterfaces.class).getRouterId().getValue();
        final String interfaceName = interfaceInfo.getInterfaceId();

        //Delete the RouterInterfaces maintained in the ODL:L3VPN configuration model
        NatUtil.delete(dataBroker, LogicalDatastoreType.CONFIGURATION, NatUtil.getRouterInterfaceId(interfaceName));

        //Delete the NeutronRouterDpnMap from the ODL:L3VPN operational model
        WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
        NatUtil.removeFromNeutronRouterDpnsMap(dataBroker, routerId, interfaceName, interfaceManager, writeTxn);

        //Delete the DpnRouterMap from the ODL:L3VPN operational model
        NatUtil.removeFromDpnRoutersMap(dataBroker, routerId, interfaceName, interfaceManager, writeTxn);
        writeTxn.submit();
    }

    @Override
    protected void update(InstanceIdentifier<Interfaces> identifier, Interfaces original, Interfaces update) {
        LOG.trace("Update event - key: {}, original: {}, update: {}", identifier, original, update);
    }

    static RouterInterface getRouterInterface(String interfaceName, String routerName) {
        return new RouterInterfaceBuilder().setKey(new RouterInterfaceKey(interfaceName))
                .setInterfaceName(interfaceName).setRouterName(routerName).build();
    }

}
