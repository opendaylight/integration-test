/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.collect.Lists;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataChangeListenerBase;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayMulticastUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanDpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.ElanDpnInterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ElanDpnInterfaceClusteredListener
    extends AsyncClusteredDataChangeListenerBase<DpnInterfaces, ElanDpnInterfaceClusteredListener>
    implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(ElanDpnInterfaceClusteredListener.class);

    private final DataBroker broker;
    private final EntityOwnershipService entityOwnershipService;
    private final ElanL2GatewayUtils elanL2GatewayUtils;
    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;

    public ElanDpnInterfaceClusteredListener(DataBroker broker, EntityOwnershipService entityOwnershipService,
                                             ElanUtils elanUtils) {
        super(DpnInterfaces.class, ElanDpnInterfaceClusteredListener.class);
        this.broker = broker;
        this.entityOwnershipService = entityOwnershipService;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
        this.elanL2GatewayMulticastUtils = elanUtils.getElanL2GatewayMulticastUtils();
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, this.broker);
    }

    @Override
    public InstanceIdentifier<DpnInterfaces> getWildCardPath() {
        return InstanceIdentifier.builder(ElanDpnInterfaces.class).child(ElanDpnInterfacesList.class)
            .child(DpnInterfaces.class).build();
    }

    @Override
    protected ClusteredDataChangeListener getDataChangeListener() {
        return ElanDpnInterfaceClusteredListener.this;
    }

    @Override
    protected AsyncDataBroker.DataChangeScope getDataChangeScope() {
        return AsyncDataBroker.DataChangeScope.BASE;
    }

    void handleUpdate(InstanceIdentifier<DpnInterfaces> id, DpnInterfaces dpnInterfaces) {
        final String elanName = getElanName(id);
        if (ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanName).isEmpty()) {
            LOG.debug("dpnInterface updation, no external l2 devices to update for elan {} with Dp Id:", elanName,
                dpnInterfaces.getDpId());
            return;
        }
        ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, elanName, "updating mcast mac upon tunnel event",
            () -> Lists.newArrayList(
                elanL2GatewayMulticastUtils.updateRemoteMcastMacOnElanL2GwDevices(elanName)));
    }

    @Override
    protected void remove(InstanceIdentifier<DpnInterfaces> identifier, final DpnInterfaces dpnInterfaces) {
        // this is the last dpn interface on this elan
        final String elanName = getElanName(identifier);
        LOG.debug("Received ElanDpnInterface removed for for elan {} with Dp Id ", elanName,
            dpnInterfaces.getDpId());

        if (ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanName).isEmpty()) {
            LOG.debug("dpnInterface removed, no external l2 devices to update for elan {} with Dp Id:", elanName,
                dpnInterfaces.getDpId());
            return;
        }
        ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, elanName, "handling ElanDpnInterface removed",
            () -> {
                // deleting Elan L2Gw Devices UcastLocalMacs From Dpn
                elanL2GatewayUtils.deleteElanL2GwDevicesUcastLocalMacsFromDpn(elanName,
                    dpnInterfaces.getDpId());
                // updating remote mcast mac on l2gw devices
                return Lists.newArrayList(
                    elanL2GatewayMulticastUtils.updateRemoteMcastMacOnElanL2GwDevices(elanName));
            });
    }

    @Override
    protected void update(InstanceIdentifier<DpnInterfaces> identifier, DpnInterfaces original,
                          final DpnInterfaces dpnInterfaces) {
        LOG.debug("dpninterfaces update fired new size {}", dpnInterfaces.getInterfaces().size());
        if (dpnInterfaces.getInterfaces().size() == 0) {
            LOG.debug("dpninterfaces last dpn interface on this elan {} ", dpnInterfaces.getKey());
            // this is the last dpn interface on this elan
            handleUpdate(identifier, dpnInterfaces);
        }
    }

    @Override
    protected void add(InstanceIdentifier<DpnInterfaces> identifier, final DpnInterfaces dpnInterfaces) {
        if (dpnInterfaces.getInterfaces().size() == 1) {
            LOG.debug("dpninterfaces first dpn interface on this elan {} {} ", dpnInterfaces.getKey(),
                dpnInterfaces.getInterfaces().get(0));
            // this is the first dpn interface on this elan
            handleUpdate(identifier, dpnInterfaces);
        }
    }

    private String getElanName(InstanceIdentifier<DpnInterfaces> identifier) {
        return identifier.firstKeyOf(ElanDpnInterfacesList.class).getElanInstanceName();
    }

}
