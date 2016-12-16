/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.listeners;

import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataTreeChangeListenerBase;
import org.opendaylight.netvirt.elan.internal.ElanInterfaceManager;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowCapableNode;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.groups.Group;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.dpn.interfaces.elan.dpn.interfaces.list.DpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ElanGroupListener extends AsyncClusteredDataTreeChangeListenerBase<Group, ElanGroupListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(ElanGroupListener.class);
    private ElanInterfaceManager elanInterfaceManager;
    private final DataBroker broker;
    private ElanUtils elanUtils;
    private final EntityOwnershipService entityOwnershipService;

    public ElanGroupListener(ElanInterfaceManager elanInterfaceManager, final DataBroker db, ElanUtils elanUtils,
                             EntityOwnershipService entityOwnershipService) {
        super(Group.class, ElanGroupListener.class);
        this.elanInterfaceManager = elanInterfaceManager;
        broker = db;
        this.elanUtils = elanUtils;
        this.entityOwnershipService = entityOwnershipService;
        LOG.trace("ElanGroupListener registered");
    }

    protected InstanceIdentifier<Group> getWildCardPath() {
        return InstanceIdentifier.create(Nodes.class).child(Node.class)
                .augmentation(FlowCapableNode.class).child(Group.class);
    }

    @Override
    protected void remove(InstanceIdentifier<Group> identifier, Group del) {
        LOG.trace("received group removed {}", del.getKey().getGroupId());
    }


    ElanInstance getElanInstanceFromGroupId(Group update) {
        Set<String> elanNames = ElanUtils.getAllElanNames();
        for (String elanName : elanNames) {
            ElanInstance elanInstance = ElanUtils.getElanInstanceByName(broker, elanName);
            if (elanInstance.getElanTag() != null) {
                long elanTag = elanInstance.getElanTag();
                long elanBCGroupId = ElanUtils.getElanRemoteBroadCastGroupID(elanTag);
                if (elanBCGroupId == update.getGroupId().getValue()) {
                    return elanInstance;
                }
            }
        }
        return null;
    }

    private BigInteger getDpnId(String node) {
        //openflow:1]
        String[] temp = node.split(":");
        if (temp != null && temp.length == 2) {
            return new BigInteger(temp[1]);
        }
        return null;
    }

    @Override
    protected void update(InstanceIdentifier<Group> identifier, Group original, Group update) {
        LOG.trace("received group updated {}", update.getKey().getGroupId());
        final BigInteger dpnId = getDpnId(identifier.firstKeyOf(Node.class).getId().getValue());
        if (dpnId == null) {
            return;
        }

        List<L2GatewayDevice> allDevices = ElanL2GwCacheUtils.getAllElanDevicesFromCache();
        if (allDevices == null || allDevices.size() == 0) {
            LOG.trace("no elan devices present in cache {}", update.getKey().getGroupId());
            return;
        }
        int expectedElanFootprint = 0;
        final ElanInstance elanInstance = getElanInstanceFromGroupId(update);
        if (elanInstance == null) {
            LOG.trace("no elan instance is null {}", update.getKey().getGroupId());
            return;
        }

        ConcurrentMap<String, L2GatewayDevice> devices =
                ElanL2GwCacheUtils.getInvolvedL2GwDevices(elanInstance.getElanInstanceName());
        if (devices == null || devices.size() == 0) {
            LOG.trace("no elan devices in elan cache {} {}", elanInstance.getElanInstanceName(),
                    update.getKey().getGroupId());
            return;
        }
        boolean updateGroup = false;
        List<DpnInterfaces> dpns = elanUtils.getInvolvedDpnsInElan(elanInstance.getElanInstanceName());
        if (dpns != null && dpns.size() > 0) {
            expectedElanFootprint += dpns.size();
        } else {
            updateGroup = true;
        }
        expectedElanFootprint += devices.size();
        if (update.getBuckets() != null && update.getBuckets().getBucket() != null) {
            if (update.getBuckets().getBucket().size() != expectedElanFootprint) {
                updateGroup = true;
            } else {
                LOG.trace("no of buckets matched perfectly {} {}", elanInstance.getElanInstanceName(),
                        update.getKey().getGroupId());
            }
        }
        if (updateGroup) {
            LOG.info("no of buckets mismatched {} {}", elanInstance.getElanInstanceName(),
                    update.getKey().getGroupId());
            ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, elanInstance.getElanInstanceName(),
                    "updating broadcast group",
                    new Callable<List<ListenableFuture<Void>>>() {
                        @Override
                        public List<ListenableFuture<Void>> call() throws Exception {
                            elanInterfaceManager.setupElanBroadcastGroups(elanInstance, dpnId);
                            return null;
                        }
                    });
        } else {
            LOG.trace("no buckets in the update {} {}", elanInstance.getElanInstanceName(),
                    update.getKey().getGroupId());
        }
    }

    @Override
    protected void add(InstanceIdentifier<Group> identifier, Group added) {
        LOG.trace("received group add {}", added.getKey().getGroupId());
        update(identifier, null/*original*/, added);
    }

    @Override
    protected ElanGroupListener getDataTreeChangeListener() {
        return this;
    }
}



