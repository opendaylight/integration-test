/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.listeners;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.Collection;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.AbstractDataChangeListener;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.cloudservicechain.utils.VpnPseudoPortCache;
import org.opendaylight.netvirt.cloudservicechain.utils.VpnServiceChainUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Listens for VrfEntry creations or removal with the purpose of including the
 * new label in the LFIB (or removing it) pointing to the VpnPseudoPort.
 *
 */
public class VrfListener extends AbstractDataChangeListener<VrfEntry> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(VrfListener.class);

    private final DataBroker broker;
    private final IMdsalApiManager mdsalMgr;

    private ListenerRegistration<DataChangeListener> listenerRegistration;


    public VrfListener(DataBroker broker, IMdsalApiManager mdsalMgr) {
        super(VrfEntry.class);
        this.broker = broker;
        this.mdsalMgr = mdsalMgr;
    }

    public void init() {
        registerListener();
    }

    private InstanceIdentifier<VrfEntry> getWildCardPath() {
        return InstanceIdentifier.create(FibEntries.class).child(VrfTables.class).child(VrfEntry.class);
    }

    private void registerListener() {
        listenerRegistration = broker.registerDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                                                                 getWildCardPath(),
                                                                 VrfListener.this,
                                                                 DataChangeScope.SUBTREE);
        LOG.info("VrfListener in Vpn-ServiceChain succesfully registered");
    }

    @Override
    public void close() throws Exception {
        if ( listenerRegistration != null ) {
            listenerRegistration.close();
        }
    }

    @Override
    protected void remove(InstanceIdentifier<VrfEntry> identifier, VrfEntry vrfEntryDeleted) {
        LOG.debug("VrfEntry removed: id={}  vrfEntry=[ destination={}, nexthops=[{}],  label={} ]",
                  identifier, vrfEntryDeleted.getDestPrefix(), vrfEntryDeleted.getNextHopAddressList(),
                  vrfEntryDeleted.getLabel());
        String vpnRd = identifier.firstKeyOf(VrfTables.class).getRouteDistinguisher();
        programLabelInAllVpnDpns(vpnRd, vrfEntryDeleted, NwConstants.DEL_FLOW);
    }

    @Override
    protected void update(InstanceIdentifier<VrfEntry> identifier, VrfEntry original, VrfEntry update) {
        LOG.debug("VrfEntry updated: id={}  vrfEntry=[ destination={}, nexthops=[{}],  label={} ]",
                  identifier, update.getDestPrefix(), update.getNextHopAddressList(), update.getLabel());
        if ( original.getLabel() != update.getLabel() ) {
            remove(identifier, original);
            add(identifier, update);
        }
    }

    @Override
    protected void add(InstanceIdentifier<VrfEntry> identifier, VrfEntry vrfEntryAdded) {
        LOG.debug("VrfEntry added: id={}  vrfEntry=[ destination={}, nexthops=[{}],  label={} ]",
                  identifier, vrfEntryAdded.getDestPrefix(), vrfEntryAdded.getNextHopAddressList(),
                  vrfEntryAdded.getLabel());
        String vpnRd = identifier.firstKeyOf(VrfTables.class).getRouteDistinguisher();
        programLabelInAllVpnDpns(vpnRd, vrfEntryAdded, NwConstants.ADD_FLOW);
    }

    /**
     * Adds or Removes a VPN's route in all the DPNs where the VPN has footprint.
     *
     * @param vpnRd Route-Distinguisher of the VPN
     * @param vrfEntry The route to add or remove
     * @param addOrRemove States if the route must be added or removed
     */
    protected void programLabelInAllVpnDpns(String vpnRd, VrfEntry vrfEntry, int addOrRemove) {
        Long vpnPseudoLPortTag = VpnPseudoPortCache.getVpnPseudoPortTagFromCache(vpnRd);
        if ( vpnPseudoLPortTag == null ) {
            LOG.debug("Vpn with rd={} not related to any VpnPseudoPort", vpnRd);
            return;
        }

        Optional<VpnInstanceOpDataEntry> vpnOpData = VpnServiceChainUtils.getVpnInstanceOpData(broker, vpnRd);
        if ( ! vpnOpData.isPresent()) {
            LOG.warn("Could not find operational data for VPN with RD={}", vpnRd);
            return;
        }

        Collection<VpnToDpnList> vpnToDpnList = vpnOpData.get().getVpnToDpnList();
        for (VpnToDpnList dpnInVpn : vpnToDpnList) {
            BigInteger dpnId = dpnInVpn.getDpnId();
            VpnServiceChainUtils.programLFibEntriesForSCF(mdsalMgr, dpnId, Arrays.asList(vrfEntry),
                                                          (int) vpnPseudoLPortTag.longValue(), addOrRemove);
        }
    }
}
