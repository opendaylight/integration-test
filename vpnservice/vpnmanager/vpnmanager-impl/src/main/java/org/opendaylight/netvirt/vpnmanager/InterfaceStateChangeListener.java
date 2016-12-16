/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;

import com.google.common.util.concurrent.ListenableFuture;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;

public class InterfaceStateChangeListener extends AsyncDataTreeChangeListenerBase<Interface, InterfaceStateChangeListener> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(InterfaceStateChangeListener.class);
    private final DataBroker dataBroker;
    private final VpnInterfaceManager vpnInterfaceManager;

    public InterfaceStateChangeListener(final DataBroker dataBroker, final VpnInterfaceManager vpnInterfaceManager) {
        super(Interface.class, InterfaceStateChangeListener.class);
        this.dataBroker = dataBroker;
        this.vpnInterfaceManager = vpnInterfaceManager;
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
    protected InterfaceStateChangeListener getDataTreeChangeListener() {
        return InterfaceStateChangeListener.this;
    }


    @Override
    protected void add(InstanceIdentifier<Interface> identifier, Interface intrf) {
        LOG.trace("Received interface {} add event", intrf);
        LOG.info("Received interface {} add event", intrf.getName());
        try {
            final String interfaceName = intrf.getName();
            LOG.info("Received interface add event for interface {} ", interfaceName);
            org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface
                    configInterface = InterfaceUtils.getInterface(dataBroker, interfaceName);
            if (configInterface != null) {
                if (!configInterface.getType().equals(Tunnel.class)) {
                    // We service only VM interfaces and Router interfaces here.
                    // We donot service Tunnel Interfaces here.
                    // Tunnel events are directly serviced
                    // by TunnelInterfacesStateListener present as part of VpnInterfaceManager
                    LOG.debug("Config Interface Name {}", configInterface.getName());
                    final VpnInterface vpnInterface = VpnUtil.getConfiguredVpnInterface(dataBroker, interfaceName);
                    if (vpnInterface != null) {
                        LOG.debug("VPN Interface Name {}", vpnInterface);
                        BigInteger intfDpnId = BigInteger.ZERO;
                        try {
                            intfDpnId = InterfaceUtils.getDpIdFromInterface(intrf);
                        } catch (Exception e){
                            LOG.error("Unable to retrieve dpnId for interface {}. Process vpn interface add fail with exception {}.",
                                    intrf.getName(), e);
                            return;
                        }
                        final BigInteger dpnId = intfDpnId;
                        final int ifIndex = intrf.getIfIndex();
                        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                        dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + intrf.getName(),
                                new Callable<List<ListenableFuture<Void>>>() {
                                    @Override
                                    public List<ListenableFuture<Void>> call() throws Exception {
                                        WriteTransaction writeConfigTxn = dataBroker.newWriteOnlyTransaction();
                                        WriteTransaction writeOperTxn = dataBroker.newWriteOnlyTransaction();
                                        WriteTransaction writeInvTxn = dataBroker.newWriteOnlyTransaction();
                                        vpnInterfaceManager.processVpnInterfaceUp(dpnId, vpnInterface, ifIndex, false,
                                                writeConfigTxn, writeOperTxn, writeInvTxn);
                                        List<ListenableFuture<Void>> futures = new ArrayList<ListenableFuture<Void>>();
                                        futures.add(writeOperTxn.submit());
                                        futures.add(writeConfigTxn.submit());
                                        futures.add(writeInvTxn.submit());
                                        return futures;
                                    }
                                });
                    }
                }
            } else {
                LOG.error("Unable to process add for interface {} ," +
                        "since Interface ConfigDS entry absent for the same", interfaceName);
            }
        } catch (Exception e) {
          LOG.error("Exception caught in Interface Operational State Up event", e);
        }
    }

    @Override
    protected void remove(InstanceIdentifier<Interface> identifier, Interface intrf) {
        final String interfaceName = intrf.getName();
        LOG.trace("Received interface {} down event", intrf);
        LOG.info("Received interface {} remove event", interfaceName);
        try {
            LOG.info("Received port DOWN event for interface {} ", interfaceName);
            if (intrf != null && intrf.getType() != null && !intrf.getType().equals(Tunnel.class)) {
                BigInteger dpId;
                InstanceIdentifier<VpnInterface> id = VpnUtil.getVpnInterfaceIdentifier(interfaceName);
                Optional<VpnInterface> optVpnInterface = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
                if (!optVpnInterface.isPresent()) {
                    LOG.debug("Interface {} is not a vpninterface, ignoring.", interfaceName);
                    return;
                }
                final VpnInterface vpnInterface = optVpnInterface.get();
                try {
                    dpId = InterfaceUtils.getDpIdFromInterface(intrf);
                } catch (Exception e) {
                    LOG.error("Unable to retrieve dpnId from interface operational data store for interface {}" +
                            ".Fetching from vpn interface op data store. ", interfaceName, e);
                    dpId = vpnInterface.getDpnId();
                }
                final BigInteger dpnId = dpId;
                final int ifIndex = intrf.getIfIndex();
                DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + interfaceName,
                        new Callable<List<ListenableFuture<Void>>>() {
                            @Override
                            public List<ListenableFuture<Void>> call() throws Exception {
                                WriteTransaction writeOperTxn = dataBroker.newWriteOnlyTransaction();
                                WriteTransaction writeConfigTxn = dataBroker.newWriteOnlyTransaction();
                                WriteTransaction writeInvTxn = dataBroker.newWriteOnlyTransaction();
                                vpnInterfaceManager.processVpnInterfaceDown(dpnId, interfaceName, ifIndex, false, false,
                                        writeConfigTxn, writeOperTxn, writeInvTxn);
                                List<ListenableFuture<Void>> futures = new ArrayList<ListenableFuture<Void>>();
                                futures.add(writeOperTxn.submit());
                                futures.add(writeConfigTxn.submit());
                                futures.add(writeInvTxn.submit());
                                return futures;
                            }
                        });
            }
        } catch (Exception e) {
            LOG.error("Exception observed in handling deletion of VPN Interface {}. ", interfaceName, e);
        }
    }

    @Override
    protected void update(InstanceIdentifier<Interface> identifier,
                          Interface original, Interface update) {
        LOG.trace("Operation Interface update event - Old: {}, New: {}", original, update);
        try {
            final String interfaceName = update.getName();
            if (original.getOperStatus().equals(Interface.OperStatus.Unknown) ||
                    update.getOperStatus().equals(Interface.OperStatus.Unknown)){
                LOG.debug("Interface {} state change is from/to UNKNOWN. Ignoring the update event.", interfaceName);
                return;
            }
            final BigInteger dpnId = InterfaceUtils.getDpIdFromInterface(update);

            if (update.getIfIndex() == null) {
                return;
            }
            if (update != null && (update.getType() != null)) {
                if (!update.getType().equals(Tunnel.class)) {
                    final VpnInterface vpnInterface = VpnUtil.getConfiguredVpnInterface(dataBroker, interfaceName);
                    if (vpnInterface != null) {
                        final int ifIndex = update.getIfIndex();
                        if (update.getOperStatus().equals(Interface.OperStatus.Up)) {
                            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                            dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + interfaceName,
                                    new Callable<List<ListenableFuture<Void>>>() {
                                        @Override
                                        public List<ListenableFuture<Void>> call() throws Exception {
                                            WriteTransaction writeConfigTxn = dataBroker.newWriteOnlyTransaction();
                                            WriteTransaction writeOperTxn = dataBroker.newWriteOnlyTransaction();
                                            WriteTransaction writeInvTxn = dataBroker.newWriteOnlyTransaction();
                                            vpnInterfaceManager.processVpnInterfaceUp(dpnId, vpnInterface, ifIndex,
                                                    true, writeConfigTxn, writeOperTxn, writeInvTxn);
                                            List<ListenableFuture<Void>> futures = new ArrayList<ListenableFuture<Void>>();
                                            futures.add(writeOperTxn.submit());
                                            futures.add(writeConfigTxn.submit());
                                            futures.add(writeInvTxn.submit());
                                            return futures;
                                        }
                                    });
                        } else if (update.getOperStatus().equals(Interface.OperStatus.Down)) {
                            DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                            dataStoreCoordinator.enqueueJob(interfaceName,
                                    new Callable<List<ListenableFuture<Void>>>() {
                                        @Override
                                        public List<ListenableFuture<Void>> call() throws Exception {
                                            WriteTransaction writeConfigTxn = dataBroker.newWriteOnlyTransaction();
                                            WriteTransaction writeOperTxn = dataBroker.newWriteOnlyTransaction();
                                            WriteTransaction writeInvTxn = dataBroker.newWriteOnlyTransaction();
                                            vpnInterfaceManager.processVpnInterfaceDown(dpnId, interfaceName, ifIndex, true, false,
                                                    writeConfigTxn, writeOperTxn, writeInvTxn);
                                            List<ListenableFuture<Void>> futures = new ArrayList<ListenableFuture<Void>>();
                                            futures.add(writeOperTxn.submit());
                                            futures.add(writeConfigTxn.submit());
                                            futures.add(writeInvTxn.submit());
                                            return futures;
                                        }
                                    });
                        }
                    }
                }
            }
        }catch (Exception e) {
            LOG.error("Exception observed in handling updation of VPN Interface {}. ", update.getName(), e);
        }
    }
}
