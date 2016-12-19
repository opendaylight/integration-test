/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.fibmanager;

import com.google.common.util.concurrent.FutureCallback;
import io.netty.util.concurrent.GlobalEventExecutor;
import java.math.BigInteger;
import java.util.List;
import org.opendaylight.controller.config.api.osgi.WaitingServiceTracker;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.RouterInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.osgi.framework.BundleContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class FibManagerImpl implements IFibManager {
    private static final Logger LOG = LoggerFactory.getLogger(FibManagerImpl.class);
    private final NexthopManager nexthopManager;
    private final VrfEntryListener vrfEntryListener;
    private IVpnManager vpnmanager;
    private final DataBroker dataBroker;

    public FibManagerImpl(final DataBroker dataBroker,
                          final NexthopManager nexthopManager,
                          final VrfEntryListener vrfEntryListener,
                          final BundleContext bundleContext) {
        this.dataBroker = dataBroker;
        this.nexthopManager = nexthopManager;
        this.vrfEntryListener = vrfEntryListener;

        GlobalEventExecutor.INSTANCE.execute(new Runnable() {
            @Override
            public void run() {
                final WaitingServiceTracker<IVpnManager> tracker = WaitingServiceTracker.create(
                        IVpnManager.class, bundleContext);
                vpnmanager = tracker.waitForService(WaitingServiceTracker.FIVE_MINUTES);
                LOG.info("FibManagerImpl initialized. IVpnManager={}", vpnmanager);
            }
        });
    }

    public void start() {
        InterVpnLinkCache.createInterVpnLinkCaches(this.dataBroker);  // Idempotent creation
    }

    @Override
    public void populateFibOnNewDpn(BigInteger dpnId, long vpnId, String rd,
                                    FutureCallback<List<Void>> callback) {
        vrfEntryListener.populateFibOnNewDpn(dpnId, vpnId, rd, callback);
    }

    @Override
    public void populateExternalRoutesOnDpn(BigInteger localDpnId, long vpnId,
                                            String rd, String localNextHopIp,
                                            String remoteNextHopIp) {
        vrfEntryListener.populateExternalRoutesOnDpn(localDpnId, vpnId, rd,
                localNextHopIp, remoteNextHopIp);
    }

    @Override
    public void populateInternalRoutesOnDpn(BigInteger localDpnId, long vpnId,
                                            String rd, String localNextHopIp,
                                            String remoteNextHopIp) {
        vrfEntryListener.populateInternalRoutesOnDpn(localDpnId, vpnId, rd,
                localNextHopIp, remoteNextHopIp);
    }

    @Override
    public void cleanUpExternalRoutesOnDpn(BigInteger dpnId, long vpnId,
                                           String rd, String localNextHopIp,
                                           String remoteNextHopIp) {
        vrfEntryListener.cleanUpExternalRoutesOnDpn(dpnId, vpnId, rd,
                localNextHopIp, remoteNextHopIp);
    }

    @Override
    public void cleanUpInternalRoutesOnDpn(BigInteger dpnId, long vpnId,
                                           String rd, String localNextHopIp,
                                           String remoteNextHopIp) {
        vrfEntryListener.cleanUpInternalRoutesOnDpn(dpnId, vpnId, rd,
                localNextHopIp, remoteNextHopIp);
    }

    @Override
    public void cleanUpDpnForVpn(BigInteger dpnId, long vpnId, String rd,
                                 FutureCallback<List<Void>> callback) {
        vrfEntryListener.cleanUpDpnForVpn(dpnId, vpnId, rd, callback);
    }

    @Override
    public List<String> printFibEntries() {
        return vrfEntryListener.printFibEntries();
    }

    @Override
    public void addStaticRoute(String prefix, String nextHop, String rd, int label) {
        vpnmanager.addExtraRoute(prefix, nextHop, rd, null, label, RouteOrigin.STATIC);
    }

    @Override
    public void deleteStaticRoute(String prefix, String nextHop, String rd) {
        vpnmanager.delExtraRoute(prefix, nextHop, rd, null);
    }

    @Override
    public void setConfTransType(String service, String transportType) {
        nexthopManager.setConfTransType(service, transportType);
    }

    @Override
    public void writeConfTransTypeConfigDS() {
        nexthopManager.writeConfTransTypeConfigDS();
    }

    @Override
    public String getConfTransType() {
        return nexthopManager.getConfiguredTransportTypeL3VPN().toString();
    }

    @Override
    public String getReqTransType() {
        return nexthopManager.getReqTransType();
    }

    @Override
    public String getTransportTypeStr(String tunType) {
        return nexthopManager.getTransportTypeStr(tunType);
    }

    @Override
    public void manageRemoteRouteOnDPN(boolean action,
                                       BigInteger DpnId,
                                       long vpnId,
                                       String  rd,
                                       String destPrefix,
                                       String destTepIp) {
        vrfEntryListener.manageRemoteRouteOnDPN(action, DpnId, vpnId,rd, destPrefix, destTepIp);
    }

    @Override
    public void addOrUpdateFibEntry(DataBroker broker, String rd, String macAddress, String prefix, List<String> nextHopList,
                                    VrfEntry.EncapType encapType, int label, long l3vni, String gatewayMacAddress,
                                    RouteOrigin origin, WriteTransaction writeConfigTxn) {
        FibUtil.addOrUpdateFibEntry(broker, rd, macAddress, prefix , nextHopList, encapType, label, l3vni, gatewayMacAddress,
                                    origin, writeConfigTxn);
    }

    @Override
    public void addFibEntryForRouterInterface(DataBroker broker, String rd, String prefix,
                                              RouterInterface routerInterface, long label, WriteTransaction writeConfigTxn) {
        FibUtil.addFibEntryForRouterInterface(broker, rd, prefix, routerInterface, label, writeConfigTxn);
    }

    @Override
    public void removeOrUpdateFibEntry(DataBroker broker, String rd, String prefix,
                                       String nextHopToRemove, WriteTransaction writeConfigTxn) {
        FibUtil.removeOrUpdateFibEntry(broker, rd, prefix, nextHopToRemove, writeConfigTxn);
    }

    @Override
    public void removeFibEntry(DataBroker broker, String rd, String prefix, WriteTransaction writeConfigTxn) {
        FibUtil.removeFibEntry(broker, rd, prefix, writeConfigTxn);
    }

    public void updateFibEntry(DataBroker broker, String rd, String prefix , List<String> nextHopList, WriteTransaction writeConfigTxn) {
        FibUtil.updateFibEntry(broker, rd, prefix , nextHopList, writeConfigTxn);
    }

    @Override
    public void addVrfTable(DataBroker broker, String rd, WriteTransaction writeConfigTxn) {
        FibUtil.addVrfTable(broker, rd, writeConfigTxn);

    }

    @Override
    public void removeVrfTable(DataBroker broker, String rd, WriteTransaction writeConfigTxn) {
        FibUtil.removeVrfTable(broker, rd, writeConfigTxn);
    }

    @Override
    public boolean isVPNConfigured() {
        return this.vpnmanager.isVPNConfigured();
    }

    @Override
    public void removeInterVPNLinkRouteFlows(final String interVpnLinkName,
                                             final boolean isVpnFirstEndPoint,
                                             final VrfEntry vrfEntry) {
        vrfEntryListener.removeInterVPNLinkRouteFlows(interVpnLinkName, isVpnFirstEndPoint,vrfEntry);
    }
}
