/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.DpnEndpoints;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.DPNTEPsInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.dpn.teps.info.TunnelEndPoints;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.util.concurrent.ListenableFuture;

public class TunnelEndPointChangeListener
        extends AsyncDataTreeChangeListenerBase<TunnelEndPoints, TunnelEndPointChangeListener> {
    private static final Logger LOG = LoggerFactory.getLogger(TunnelEndPointChangeListener.class);

    private final DataBroker broker;
    private final VpnInterfaceManager vpnInterfaceManager;

    public TunnelEndPointChangeListener(final DataBroker broker, final VpnInterfaceManager vpnInterfaceManager) {
        super(TunnelEndPoints.class, TunnelEndPointChangeListener.class);
        this.broker = broker;
        this.vpnInterfaceManager = vpnInterfaceManager;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, broker);
    }

    @Override
    protected InstanceIdentifier<TunnelEndPoints> getWildCardPath() {
        return InstanceIdentifier.builder(DpnEndpoints.class).child(DPNTEPsInfo.class).child(TunnelEndPoints.class)
                .build();
    }

    @Override
    protected void remove(InstanceIdentifier<TunnelEndPoints> key, TunnelEndPoints tep) {
    }

    @Override
    protected void update(InstanceIdentifier<TunnelEndPoints> key, TunnelEndPoints origTep,
            TunnelEndPoints updatedTep) {
    }

    @Override
    protected void add(InstanceIdentifier<TunnelEndPoints> key, TunnelEndPoints tep) {
        BigInteger dpnId = key.firstIdentifierOf(DPNTEPsInfo.class).firstKeyOf(DPNTEPsInfo.class).getDPNID();
        if (BigInteger.ZERO.equals(dpnId)) {
            LOG.warn("Invalid DPN id for TEP {}", tep.getInterfaceName());
            return;
        }

        List<VpnInstance> vpnInstances = VpnUtil.getAllVpnInstances(broker);
        if (vpnInstances == null || vpnInstances.isEmpty()) {
            LOG.debug("No VPN instances defined");
            return;
        }

        DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();

        for (VpnInstance vpnInstance : vpnInstances) {
            final String vpnName = vpnInstance.getVpnInstanceName();
            final long vpnId = VpnUtil.getVpnId(broker, vpnName);
            LOG.trace("Handling TEP {} add for VPN instance {}", tep.getInterfaceName(), vpnName);
            List<VpnInterfaces> vpnInterfaces = VpnUtil.getDpnVpnInterfaces(broker, vpnInstance, dpnId);
            if (vpnInterfaces != null) {
                for (VpnInterfaces vpnInterface : vpnInterfaces) {
                    String vpnInterfaceName = vpnInterface.getInterfaceName();
                    dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + vpnInterfaceName,
                            new Callable<List<ListenableFuture<Void>>>() {
                                @Override
                                public List<ListenableFuture<Void>> call() throws Exception {
                                    LOG.trace("Handling TEP {} add for VPN instance {} VPN interface {}",
                                            tep.getInterfaceName(), vpnName, vpnInterfaceName);
                                    WriteTransaction writeConfigTxn = broker.newWriteOnlyTransaction();
                                    WriteTransaction writeOperTxn = broker.newWriteOnlyTransaction();
                                    WriteTransaction writeInvTxn = broker.newWriteOnlyTransaction();
                                    final org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface interfaceState =
                                            InterfaceUtils.getInterfaceStateFromOperDS(broker, vpnInterfaceName);
                                    final int lPortTag = interfaceState.getIfIndex();
                                    vpnInterfaceManager.processVpnInterfaceAdjacencies(dpnId, lPortTag, vpnName, vpnInterfaceName,
                                            vpnId, writeConfigTxn, writeOperTxn, writeInvTxn);
                                    return Arrays.asList(writeOperTxn.submit(), writeConfigTxn.submit(), writeInvTxn.submit());
                                }
                            });
                }
            }
        }
    }

    @Override
    protected TunnelEndPointChangeListener getDataTreeChangeListener() {
        return this;
    }
}
