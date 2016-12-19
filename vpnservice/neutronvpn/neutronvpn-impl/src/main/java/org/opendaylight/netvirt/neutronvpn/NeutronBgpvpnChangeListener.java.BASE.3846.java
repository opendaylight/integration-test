/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.bgpvpns.rev150903.BgpvpnTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.bgpvpns.rev150903.BgpvpnTypeL3;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.bgpvpns.rev150903.bgpvpns.attributes.Bgpvpns;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.bgpvpns.rev150903.bgpvpns.attributes.bgpvpns.Bgpvpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.osgi.framework.BundleContext;
import org.osgi.framework.FrameworkUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronBgpvpnChangeListener extends AsyncDataTreeChangeListenerBase<Bgpvpn, NeutronBgpvpnChangeListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronBgpvpnChangeListener.class);
    private final DataBroker dataBroker;
    private final NeutronvpnManager nvpnManager;
    private final IdManagerService idManager;
    private final String adminRDValue;

    public NeutronBgpvpnChangeListener(final DataBroker dataBroker, final NeutronvpnManager nVpnMgr,
                                       final IdManagerService idManager) {
        super(Bgpvpn.class, NeutronBgpvpnChangeListener.class);
        this.dataBroker = dataBroker;
        nvpnManager = nVpnMgr;
        this.idManager = idManager;
        BundleContext bundleContext=FrameworkUtil.getBundle(NeutronBgpvpnChangeListener.class).getBundleContext();
        adminRDValue = bundleContext.getProperty(NeutronConstants.RD_PROPERTY_KEY);
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        createIdPool();
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Bgpvpn> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Bgpvpns.class).child(Bgpvpn.class);
    }

    @Override
    protected NeutronBgpvpnChangeListener getDataTreeChangeListener() {
        return NeutronBgpvpnChangeListener.this;
    }

    private boolean isBgpvpnTypeL3(Class<? extends BgpvpnTypeBase> bgpvpnType) {
        if (BgpvpnTypeL3.class.equals(bgpvpnType)) {
            return true;
        } else {
            LOG.warn("CRUD operations supported only for L3 type Bgpvpn");
            return false;
        }
    }

    @Override
    protected void add(InstanceIdentifier<Bgpvpn> identifier, Bgpvpn input) {
        LOG.trace("Adding Bgpvpn : key: {}, value={}", identifier, input);
        if (isBgpvpnTypeL3(input.getType())) {
            // handle route-target(s)
            List<String> importRouteTargets = new ArrayList<String>();
            List<String> exportRouteTargets = new ArrayList<String>();
            List<String> inputRouteList = input.getRouteTargets();
            List<String> inputImportRouteList = input.getImportTargets();
            List<String> inputExportRouteList = input.getExportTargets();
            Set<String> inputImportRouteSet = new HashSet<>();
            Set<String> inputExportRouteSet = new HashSet<>();

            if (inputRouteList != null && !inputRouteList.isEmpty()) {
                inputImportRouteSet.addAll(inputRouteList);
                inputExportRouteSet.addAll(inputRouteList);
            }
            if (inputImportRouteList != null && !inputImportRouteList.isEmpty()) {
                inputImportRouteSet.addAll(inputImportRouteList);
            }
            if (inputExportRouteList != null && !inputExportRouteList.isEmpty()) {
                inputExportRouteSet.addAll(inputExportRouteList);
            }

            importRouteTargets.addAll(inputImportRouteSet);
            exportRouteTargets.addAll(inputExportRouteSet);

            List<String> rd = input.getRouteDistinguishers();

            if (rd == null || rd.isEmpty()) {
                // generate new RD
                rd = generateNewRD(input.getUuid());
            } else {
                String[] rdParams = rd.get(0).split(":");
                if (rdParams[0].trim().equals(adminRDValue)) {
                    LOG.error("AS specific part of RD should not be same as that defined by DC Admin");
                    return;
                }
            }
            Uuid router = null;
            if (input.getRouters() != null && !input.getRouters().isEmpty()) {
                // currently only one router
                router = input.getRouters().get(0);
            }
            if (rd != null) {
                try {
                    nvpnManager.createL3Vpn(input.getUuid(), input.getName(), input.getTenantId(), rd, importRouteTargets,
                            exportRouteTargets, router, input.getNetworks());
                } catch (Exception e) {
                    LOG.error("Creation of BGPVPN {} failed with error message {}. ", input.getUuid(),
                            e.getMessage(), e);
                }
            } else {
                LOG.error("Create BgpVPN with id " + input.getUuid() + " failed due to missing/invalid RD value.");
            }
        }
    }

    private List<String> generateNewRD(Uuid vpn) {
        if (adminRDValue != null) {
            Integer rdId = NeutronvpnUtils.getUniqueRDId(idManager, NeutronConstants.RD_IDPOOL_NAME, vpn.toString());
            if (rdId != null) {
                String rd = adminRDValue + ":" + rdId;
                LOG.debug("Generated RD {} for L3VPN {}", rd, vpn);
                return Collections.singletonList(rd);
            }
        }
        return Collections.emptyList();
    }

    @Override
    protected void remove(InstanceIdentifier<Bgpvpn> identifier, Bgpvpn input) {
        LOG.trace("Removing Bgpvpn : key: {}, value={}", identifier, input);
        if (isBgpvpnTypeL3(input.getType())) {
            nvpnManager.removeL3Vpn(input.getUuid());
            // Release RD Id in pool
            NeutronvpnUtils.releaseRDId(idManager, NeutronConstants.RD_IDPOOL_NAME, input.getUuid().toString());
        }
    }

    @Override
    protected void update(InstanceIdentifier<Bgpvpn> identifier, Bgpvpn original, Bgpvpn update) {
        LOG.trace("Update Bgpvpn : key: {}, value={}", identifier, update);
        if (isBgpvpnTypeL3(update.getType())) {
            List<Uuid> oldNetworks = original.getNetworks();
            List<Uuid> newNetworks = update.getNetworks();
            List<Uuid> oldRouters = original.getRouters();
            List<Uuid> newRouters = update.getRouters();
            Uuid vpnId = update.getUuid();
            handleNetworksUpdate(vpnId, oldNetworks, newNetworks);
            handleRoutersUpdate(vpnId, oldRouters, newRouters);
        }
    }

    protected void handleNetworksUpdate(Uuid vpnId, List<Uuid> oldNetworks, List<Uuid> newNetworks) {
        if (newNetworks != null && !newNetworks.isEmpty()) {
            if (oldNetworks != null && !oldNetworks.isEmpty()) {
                if (oldNetworks != newNetworks) {
                    Iterator<Uuid> iter = newNetworks.iterator();
                    while (iter.hasNext()) {
                        Uuid net = iter.next();
                        if (oldNetworks.contains(net)) {
                            oldNetworks.remove(net);
                            iter.remove();
                        }
                    }
                    //clear removed networks
                    if (!oldNetworks.isEmpty()) {
                        LOG.trace("Removing old networks {} ", oldNetworks);
                        nvpnManager.dissociateNetworksFromVpn(vpnId, oldNetworks);
                    }

                    //add new (Delta) Networks
                    if (!newNetworks.isEmpty()) {
                        LOG.trace("Adding delta New networks {} ", newNetworks);
                        nvpnManager.associateNetworksToVpn(vpnId, newNetworks);
                    }
                }
            } else {
                //add new Networks
                LOG.trace("Adding New networks {} ", newNetworks);
                nvpnManager.associateNetworksToVpn(vpnId, newNetworks);
            }
        } else if (oldNetworks != null && !oldNetworks.isEmpty()) {
            LOG.trace("Removing old networks {} ", oldNetworks);
            nvpnManager.dissociateNetworksFromVpn(vpnId, oldNetworks);

        }
    }

    protected void handleRoutersUpdate(Uuid vpnId, List<Uuid> oldRouters, List<Uuid> newRouters) {
        if (newRouters != null && !newRouters.isEmpty()) {
            if (oldRouters != null && !oldRouters.isEmpty()) {
                if (oldRouters.size() > 1 || newRouters.size() > 1) {
                    VpnMap vpnMap = NeutronvpnUtils.getVpnMap(dataBroker, vpnId);
                    if (vpnMap.getRouterId() != null) {
                        LOG.warn("Only Single Router association  to a given bgpvpn is allowed .Kindly de-associate " +
                                "router " + vpnMap.getRouterId().getValue() + " from vpn " + vpnId + " before " +
                                "proceeding with associate");
                    }
                    return;
                }
            } else if (validateRouteInfo(newRouters.get(0))) {
                nvpnManager.associateRouterToVpn(vpnId, newRouters.get(0));
            }

        } else if (oldRouters != null && !oldRouters.isEmpty()) {
                /* dissociate old router */
            Uuid oldRouter = oldRouters.get(0);
            nvpnManager.dissociateRouterFromVpn(vpnId, oldRouter);
        }
    }

    private void createIdPool() {
        CreateIdPoolInput createPool = new CreateIdPoolInputBuilder().setPoolName(NeutronConstants.RD_IDPOOL_NAME)
                .setLow(NeutronConstants.RD_IDPOOL_START)
                .setHigh(new BigInteger(NeutronConstants.RD_IDPOOL_SIZE).longValue()).build();
        try {
            Future<RpcResult<Void>> result = idManager.createIdPool(createPool);
            if ((result != null) && (result.get().isSuccessful())) {
                LOG.info("Created IdPool for Bgpvpn RD");
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to create idPool for Bgpvpn RD", e);
        }
    }

    private boolean validateRouteInfo(Uuid routerID) {
        Uuid assocVPNId;
        if ((assocVPNId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerID, true)) != null) {
            LOG.warn("VPN router association failed  due to router " + routerID.getValue()
                    + " already associated to another VPN " + assocVPNId.getValue());
            return false;
        }
        return true;
    }

}