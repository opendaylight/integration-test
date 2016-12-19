/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.NotificationPublishService;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.AddDpnEvent;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.AddDpnEventBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.RemoveDpnEvent;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.RemoveDpnEventBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.add.dpn.event.AddEventData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.add.dpn.event.AddEventDataBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.remove.dpn.event.RemoveEventData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.remove.dpn.event.RemoveEventDataBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.IpAddresses;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VpnFootprintService {

    // TODO: Should this class have its own interface instead of being under IVpnManager's umbrella?

    private static final Logger LOG = LoggerFactory.getLogger(VpnFootprintService.class);

    private final DataBroker dataBroker;
    private final IFibManager fibManager;
    private final VpnOpDataSyncer vpnOpDataSyncer;
    private final OdlInterfaceRpcService ifaceMgrRpcService;
    private final NotificationPublishService notificationPublishService;

    public VpnFootprintService(final DataBroker dataBroker,
                               final IFibManager fibManager,
                               final OdlInterfaceRpcService ifaceRpcService,
                               final NotificationPublishService notificationPublishService,
                               final VpnOpDataSyncer vpnOpDataSyncer) {
        this.dataBroker = dataBroker;
        this.fibManager = fibManager;
        this.vpnOpDataSyncer = vpnOpDataSyncer;
        this.ifaceMgrRpcService = ifaceRpcService;
        this.notificationPublishService = notificationPublishService;
    }

    public void updateVpnToDpnMapping(BigInteger dpId, String vpnName, String interfaceName, boolean add) {
        long vpnId = VpnUtil.getVpnId(dataBroker, vpnName);
        if (dpId == null) {
            dpId = InterfaceUtils.getDpnForInterface(ifaceMgrRpcService, interfaceName);
        }
        if(!dpId.equals(BigInteger.ZERO)) {
            if(add) {
                // Considering the possibility of VpnInstanceOpData not being ready yet cause the VPN is
                // still in its creation process
                if ( vpnId == VpnConstants.INVALID_ID ) {
                    vpnOpDataSyncer.waitForVpnDataReady(VpnOpDataSyncer.VpnOpDataType.vpnInstanceToId, vpnName,
                                                   VpnConstants.PER_VPN_INSTANCE_OPDATA_MAX_WAIT_TIME_IN_MILLISECONDS);
                    vpnId = VpnUtil.getVpnId(dataBroker, vpnName);
                }
                createOrUpdateVpnToDpnList(vpnId, dpId, interfaceName, vpnName);
            } else {
                removeOrUpdateVpnToDpnList(vpnId, dpId, interfaceName, vpnName);
            }
        }
    }

    private void createOrUpdateVpnToDpnList(long vpnId, BigInteger dpnId, String intfName, String vpnName) {
        String routeDistinguisher = VpnUtil.getVpnRdFromVpnInstanceConfig(dataBroker, vpnName);
        String rd = (routeDistinguisher == null) ? vpnName : routeDistinguisher;
        Boolean newDpnOnVpn = Boolean.FALSE;

        synchronized (vpnName.intern()) {
            WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
            InstanceIdentifier<VpnToDpnList> id = VpnUtil.getVpnToDpnListIdentifier(rd, dpnId);
            Optional<VpnToDpnList> dpnInVpn = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
            VpnInterfaces vpnInterface = new VpnInterfacesBuilder().setInterfaceName(intfName).build();

            if (dpnInVpn.isPresent()) {
                VpnToDpnList vpnToDpnList = dpnInVpn.get();
                List<VpnInterfaces> vpnInterfaces = vpnToDpnList.getVpnInterfaces();
                if (vpnInterfaces == null) {
                    vpnInterfaces = new ArrayList<>();
                }
                vpnInterfaces.add(vpnInterface);
                VpnToDpnListBuilder vpnToDpnListBuilder = new VpnToDpnListBuilder(vpnToDpnList);
                vpnToDpnListBuilder.setDpnState(VpnToDpnList.DpnState.Active).setVpnInterfaces(vpnInterfaces);

                writeTxn.put(LogicalDatastoreType.OPERATIONAL, id, vpnToDpnListBuilder.build(), true);
                /* If earlier state was inactive, it is considered new DPN coming back to the
                 * same VPN
                 */
                if (vpnToDpnList.getDpnState() == VpnToDpnList.DpnState.Inactive) {
                    newDpnOnVpn = Boolean.TRUE;
                }
            } else {
                List<VpnInterfaces> vpnInterfaces = new ArrayList<>();
                vpnInterfaces.add(vpnInterface);
                VpnToDpnListBuilder vpnToDpnListBuilder = new VpnToDpnListBuilder().setDpnId(dpnId);
                vpnToDpnListBuilder.setDpnState(VpnToDpnList.DpnState.Active).setVpnInterfaces(vpnInterfaces);

                writeTxn.put(LogicalDatastoreType.OPERATIONAL, id, vpnToDpnListBuilder.build(), true);
                newDpnOnVpn = Boolean.TRUE;
            }
            CheckedFuture<Void, TransactionCommitFailedException> futures = writeTxn.submit();
            try {
                futures.get();
            } catch (InterruptedException | ExecutionException e) {
                LOG.error("Error adding to dpnToVpnList for vpn {} interface {} dpn {}", vpnName, intfName, dpnId, e);
                throw new RuntimeException(e.getMessage());
            }
        }
        /*
         * Informing the Fib only after writeTxn is submitted successfuly.
         */
        if (newDpnOnVpn) {
            LOG.debug("Sending populateFib event for new dpn {} in VPN {}", dpnId, vpnName);
            fibManager.populateFibOnNewDpn(dpnId, vpnId, rd, new DpnEnterExitVpnWorker(dpnId, vpnName, rd,
                                                                                       true /* entered */));
        }
    }

    private void removeOrUpdateVpnToDpnList(long vpnId, BigInteger dpnId, String intfName, String vpnName) {
        Boolean lastDpnOnVpn = Boolean.FALSE;
        String rd = VpnUtil.getVpnRd(dataBroker, vpnName);
        synchronized (vpnName.intern()) {
            InstanceIdentifier<VpnToDpnList> id = VpnUtil.getVpnToDpnListIdentifier(rd, dpnId);
            Optional<VpnToDpnList> dpnInVpn = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
            WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
            if (dpnInVpn.isPresent()) {
                List<VpnInterfaces> vpnInterfaces = dpnInVpn.get().getVpnInterfaces();
                VpnInterfaces currVpnInterface = new VpnInterfacesBuilder().setInterfaceName(intfName).build();

                if (vpnInterfaces.remove(currVpnInterface)) {
                    if (vpnInterfaces.isEmpty()) {
                        List<IpAddresses> ipAddresses = dpnInVpn.get().getIpAddresses();
                        if (ipAddresses == null || ipAddresses.isEmpty()) {
                            VpnToDpnListBuilder dpnInVpnBuilder =
                                new VpnToDpnListBuilder(dpnInVpn.get()).setDpnState(VpnToDpnList.DpnState.Inactive)
                                                                       .setVpnInterfaces(null);
                            writeTxn.put(LogicalDatastoreType.OPERATIONAL, id, dpnInVpnBuilder.build(), true);
                            lastDpnOnVpn = Boolean.TRUE;
                        } else {
                            LOG.warn("vpn interfaces are empty but ip addresses are present for the vpn {} in dpn {}",
                                     vpnName, dpnId);
                        }
                    } else {
                        writeTxn.delete(LogicalDatastoreType.OPERATIONAL, id.child(VpnInterfaces.class,
                                                                                   new VpnInterfacesKey(intfName)));
                    }
                }
            }
            CheckedFuture<Void, TransactionCommitFailedException> futures = writeTxn.submit();
            try {
                futures.get();
            } catch (InterruptedException | ExecutionException e) {
                LOG.error("Error removing from dpnToVpnList for vpn {} interface {} dpn {}",
                          vpnName, intfName, dpnId, e);
                throw new RuntimeException(e.getMessage());
            }
        }
        if (lastDpnOnVpn) {
            LOG.debug("Sending cleanup event for dpn {} in VPN {}", dpnId, vpnName);
            fibManager.cleanUpDpnForVpn(dpnId, vpnId, rd, new DpnEnterExitVpnWorker(dpnId, vpnName, rd,
                                                                                    false /* exited */));
        }
    }

    void publishAddNotification(final BigInteger dpnId, final String vpnName, final String rd) {
        LOG.debug("Sending notification for add dpn {} in vpn {} event ", dpnId, vpnName);
        AddEventData data = new AddEventDataBuilder().setVpnName(vpnName).setRd(rd).setDpnId(dpnId).build();
        AddDpnEvent event = new AddDpnEventBuilder().setAddEventData(data).build();
        final ListenableFuture<? extends Object> eventFuture = notificationPublishService.offerNotification(event);
        Futures.addCallback(eventFuture, new FutureCallback<Object>() {
            @Override
            public void onFailure(Throwable error) {
                LOG.warn("Error in notifying listeners for add dpn {} in vpn {} event ", dpnId, vpnName, error);
            }

            @Override
            public void onSuccess(Object arg) {
                LOG.trace("Successful in notifying listeners for add dpn {} in vpn {} event ", dpnId, vpnName);
            }
        });
    }

    void publishRemoveNotification(final BigInteger dpnId, final String vpnName, final String rd) {
        LOG.debug("Sending notification for remove dpn {} in vpn {} event ", dpnId, vpnName);
        RemoveEventData data = new RemoveEventDataBuilder().setVpnName(vpnName).setRd(rd).setDpnId(dpnId).build();
        RemoveDpnEvent event = new RemoveDpnEventBuilder().setRemoveEventData(data).build();
        final ListenableFuture<? extends Object> eventFuture = notificationPublishService.offerNotification(event);
        Futures.addCallback(eventFuture, new FutureCallback<Object>() {
            @Override
            public void onFailure(Throwable error) {
                LOG.warn("Error in notifying listeners for remove dpn {} in vpn {} event ", dpnId, vpnName, error);
            }

            @Override
            public void onSuccess(Object arg) {
                LOG.trace("Successful in notifying listeners for remove dpn {} in vpn {} event ", dpnId, vpnName);
            }
        });
    }


    /**
     * JobCallback class is used as a future callback for
     * main and rollback workers to handle success and failure.
     */
    private class DpnEnterExitVpnWorker implements FutureCallback<List<Void>> {
        BigInteger dpnId;
        String vpnName;
        String rd;
        boolean entered;

        public DpnEnterExitVpnWorker(BigInteger dpnId, String vpnName, String rd, boolean entered) {
            this.entered = entered;
            this.dpnId = dpnId;
            this.vpnName = vpnName;
            this.rd = rd;
        }

        /**
         * @param voids
         * This implies that all the future instances have returned success. -- TODO: Confirm this
         */
        @Override
        public void onSuccess(List<Void> voids) {
            if (entered) {
                publishAddNotification(dpnId, vpnName, rd);
            } else {
                publishRemoveNotification(dpnId, vpnName, rd);
            }
        }

        /**
         *
         * @param throwable
         * This method is used to handle failure callbacks.
         * If more retry needed, the retrycount is decremented and mainworker is executed again.
         * After retries completed, rollbackworker is executed.
         * If rollbackworker fails, this is a double-fault. Double fault is logged and ignored.
         */
        @Override
        public void onFailure(Throwable throwable) {
            LOG.warn("Job: failed with exception: ", throwable);
        }
    }

}
