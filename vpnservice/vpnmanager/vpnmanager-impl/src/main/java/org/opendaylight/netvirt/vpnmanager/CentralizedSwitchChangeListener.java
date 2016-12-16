/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.NaptSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitch;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * CentralizedSwitchChangeListener detect changes in switch:router mapping and
 * update flows accordingly.<br>
 * The centralized switch a.k.a NAPT switch is currently defined using models
 * residing in natservice bundle. As the roles of centralized switch will grow
 * beyond NAT use cases, the associated models and logic need to be renamed
 * and moved to either vpnmanager or new bundle as part of Carbon model changes
 *
 */
public class CentralizedSwitchChangeListener
        extends AsyncDataTreeChangeListenerBase<RouterToNaptSwitch, CentralizedSwitchChangeListener> {

    private static final Logger LOG = LoggerFactory.getLogger(CentralizedSwitchChangeListener.class);

    private final DataBroker dataBroker;
    private final IVpnManager vpnManager;

    public CentralizedSwitchChangeListener(final DataBroker dataBroker, final IVpnManager vpnManager) {
        super(RouterToNaptSwitch.class, CentralizedSwitchChangeListener.class);
        this.dataBroker = dataBroker;
        this.vpnManager = vpnManager;
    }

    @Override
    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<RouterToNaptSwitch> getWildCardPath() {
        return InstanceIdentifier.create(NaptSwitches.class).child(RouterToNaptSwitch.class);
    }

    @Override
    protected void remove(InstanceIdentifier<RouterToNaptSwitch> key, RouterToNaptSwitch routerToNaptSwitch) {
        LOG.debug("Removing {}", routerToNaptSwitch);
        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        setupRouterGwFlows(routerToNaptSwitch, writeTx, NwConstants.DEL_FLOW);
        writeTx.submit();
    }

    @Override
    protected void update(InstanceIdentifier<RouterToNaptSwitch> key, RouterToNaptSwitch origRouterToNaptSwitch,
            RouterToNaptSwitch updatedRouterToNaptSwitch) {
        LOG.debug("Updating old {} new {}", origRouterToNaptSwitch, updatedRouterToNaptSwitch);
        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        setupRouterGwFlows(origRouterToNaptSwitch, writeTx, NwConstants.DEL_FLOW);
        setupRouterGwFlows(updatedRouterToNaptSwitch, writeTx, NwConstants.ADD_FLOW);
        writeTx.submit();
    }

    @Override
    protected void add(InstanceIdentifier<RouterToNaptSwitch> key, RouterToNaptSwitch routerToNaptSwitch) {
        LOG.debug("Adding {}", routerToNaptSwitch);
        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        setupRouterGwFlows(routerToNaptSwitch, writeTx, NwConstants.ADD_FLOW);
        writeTx.submit();
    }

    @Override
    protected CentralizedSwitchChangeListener getDataTreeChangeListener() {
        return this;
    }

    private void setupRouterGwFlows(RouterToNaptSwitch routerToNaptSwitch, WriteTransaction writeTx, int addOrRemove) {
        Routers router = VpnUtil.getExternalRouter(dataBroker, routerToNaptSwitch.getRouterName());
        if (router == null) {
            LOG.warn("No router data found for router id {}", routerToNaptSwitch.getRouterName());
            return;
        }

        BigInteger primarySwitchId = routerToNaptSwitch.getPrimarySwitchId();
        Uuid extNetworkId = router.getNetworkId();
        String extGwMacAddress = router.getExtGwMacAddress();
        String routerName = router.getRouterName();
        vpnManager.setupRouterGwMacFlow(routerName, extGwMacAddress, primarySwitchId, extNetworkId, writeTx,
                addOrRemove);
        vpnManager.setupArpResponderFlowsToExternalNetworkIps(routerName, router.getExternalIps(), extGwMacAddress, primarySwitchId,
                extNetworkId, writeTx, addOrRemove);
    }
}
