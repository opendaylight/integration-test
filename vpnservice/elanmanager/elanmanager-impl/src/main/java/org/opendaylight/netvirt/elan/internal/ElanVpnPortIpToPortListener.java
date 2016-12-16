/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.netvirt.elan.utils.ElanConstants;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ElanVpnPortIpToPortListener extends
        AsyncDataTreeChangeListenerBase<VpnPortipToPort, ElanVpnPortIpToPortListener> {
    private static final Logger LOG = LoggerFactory.getLogger(ElanVpnPortIpToPortListener.class);
    private final DataBroker broker;
    private final IInterfaceManager interfaceManager;
    private final ElanUtils elanUtils;

    public ElanVpnPortIpToPortListener(DataBroker broker, IInterfaceManager interfaceManager, ElanUtils elanUtils) {
        super(VpnPortipToPort.class, ElanVpnPortIpToPortListener.class);
        this.broker = broker;
        this.interfaceManager = interfaceManager;
        this.elanUtils = elanUtils;
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.debug("ElanVpnPortIpToPort Listener Closed");
    }

    @Override
    protected InstanceIdentifier<VpnPortipToPort> getWildCardPath() {
        return InstanceIdentifier.create(NeutronVpnPortipPortData.class).child(VpnPortipToPort.class);
    }

    @Override
    protected void remove(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort dataObjectModification) {
        String macAddress = dataObjectModification.getMacAddress();
        String interfaceName = dataObjectModification.getPortName();
        boolean isLearnt = dataObjectModification.isLearnt();
        if (!isLearnt) {
            LOG.trace("Not learnt mac {}. Not performing action", macAddress);
            return;
        }
        LOG.trace("Removing mac address {} from interface {} ", macAddress, interfaceName);
        DataStoreJobCoordinator.getInstance().enqueueJob(buildJobKey(macAddress, interfaceName),
                new StaticMacRemoveWorker(macAddress, interfaceName));
    }

    @Override
    protected void update(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort dataObjectModificationBefore,
            VpnPortipToPort dataObjectModificationAfter) {
        String oldMac = dataObjectModificationBefore.getMacAddress();
        String oldInterfaceName = dataObjectModificationBefore.getPortName();
        String newMac = dataObjectModificationAfter.getMacAddress();
        String newInterfaceName = dataObjectModificationAfter.getPortName();
        boolean isLearntOld = dataObjectModificationBefore.isLearnt();
        boolean isLearntNew = dataObjectModificationAfter.isLearnt();
        DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
        if (oldMac.equals(newMac) && oldInterfaceName.equals(newInterfaceName)) {
            LOG.trace("No change in Mac Address {} and InterfaceName {}. No actions performed", newMac,
                    newInterfaceName);
            return;
        }
        if (isLearntOld) {
            LOG.trace("Removing mac address {} from interface {} due to update event", oldMac, oldInterfaceName);
            coordinator.enqueueJob(buildJobKey(oldMac, oldInterfaceName), new StaticMacRemoveWorker(oldMac,
                    oldInterfaceName));
        }
        if (isLearntNew) {
            LOG.trace("Adding mac address {} to interface {} due to update event", newMac, newInterfaceName);
            coordinator.enqueueJob(buildJobKey(newMac, newInterfaceName), new StaticMacAddWorker(newMac,
                    newInterfaceName));
        }
    }

    @Override
    protected void add(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort dataObjectModification) {
        String macAddress = dataObjectModification.getMacAddress();
        String interfaceName = dataObjectModification.getPortName();
        boolean isLearnt = dataObjectModification.isLearnt();
        if (isLearnt) {
            LOG.trace("Adding mac address {} to interface {} ", macAddress, interfaceName);
            DataStoreJobCoordinator.getInstance().enqueueJob(buildJobKey(macAddress, interfaceName),
                    new StaticMacAddWorker(macAddress, interfaceName));
        }
    }

    @Override
    protected ElanVpnPortIpToPortListener getDataTreeChangeListener() {
        return this;
    }

    private class StaticMacAddWorker implements Callable<List<ListenableFuture<Void>>> {
        String macAddress;
        String interfaceName;

        StaticMacAddWorker(String macAddress, String interfaceName) {
            this.macAddress = macAddress;
            this.interfaceName = interfaceName;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            List<ListenableFuture<Void>> futures = new ArrayList<>();
            WriteTransaction flowWritetx = broker.newWriteOnlyTransaction();
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            ElanInterface elanInterface = ElanUtils.getElanInterfaceByElanInterfaceName(broker, interfaceName);
            if (elanInterface == null) {
                LOG.debug("ElanInterface Not present for interfaceName {} for add event", interfaceName);
                return futures;
            }
            elanUtils.addMacEntryToDsAndSetupFlows(interfaceManager, interfaceName, macAddress,
                    elanInterface.getElanInstanceName(), tx, flowWritetx, ElanConstants.STATIC_MAC_TIMEOUT);
            futures.add(tx.submit());
            futures.add(flowWritetx.submit());
            return futures;
        }
    }

    private class StaticMacRemoveWorker implements Callable<List<ListenableFuture<Void>>> {
        String macAddress;
        String interfaceName;

        StaticMacRemoveWorker(String macAddress, String interfaceName) {
            this.macAddress = macAddress;
            this.interfaceName = interfaceName;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {
            List<ListenableFuture<Void>> futures = new ArrayList<>();
            WriteTransaction deleteFlowTx = broker.newWriteOnlyTransaction();
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            ElanInterface elanInterface = ElanUtils.getElanInterfaceByElanInterfaceName(broker, interfaceName);
            if (elanInterface == null) {
                LOG.debug("ElanInterface Not present for interfaceName {} for delete event", interfaceName);
                return futures;
            }
            elanUtils.deleteMacEntryFromDsAndRemoveFlows(interfaceManager, interfaceName, macAddress,
                    elanInterface.getElanInstanceName(), tx, deleteFlowTx);
            futures.add(tx.submit());
            futures.add(deleteFlowTx.submit());
            return futures;
        }
    }

    private String buildJobKey(String mac, String interfaceName) {
        return "ENTERPRISEMACJOB" + mac + interfaceName;
    }


}
