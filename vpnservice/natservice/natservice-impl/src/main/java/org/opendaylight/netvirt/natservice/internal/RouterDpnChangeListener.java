/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.NeutronRouterDpns;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RouterDpnChangeListener extends AsyncDataTreeChangeListenerBase<DpnVpninterfacesList, RouterDpnChangeListener> implements
        AutoCloseable{
    private static final Logger LOG = LoggerFactory.getLogger(RouterDpnChangeListener.class);
    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private final SNATDefaultRouteProgrammer snatDefaultRouteProgrammer;
    private final NaptSwitchHA naptSwitchHA;
    private final IdManagerService idManager;
    private final ExternalNetworkGroupInstaller extNetGroupInstaller;

    public RouterDpnChangeListener(final DataBroker dataBroker, final IMdsalApiManager mdsalManager,
                                   final SNATDefaultRouteProgrammer snatDefaultRouteProgrammer,
                                   final NaptSwitchHA naptSwitchHA,
                                   final IdManagerService idManager,
                                   final ExternalNetworkGroupInstaller extNetGroupInstaller) {
        super(DpnVpninterfacesList.class, RouterDpnChangeListener.class);
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.snatDefaultRouteProgrammer = snatDefaultRouteProgrammer;
        this.naptSwitchHA = naptSwitchHA;
        this.idManager = idManager;
        this.extNetGroupInstaller = extNetGroupInstaller;
    }

    @Override
    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected RouterDpnChangeListener getDataTreeChangeListener() {
        return RouterDpnChangeListener.this;
    }

    @Override
    protected InstanceIdentifier<DpnVpninterfacesList> getWildCardPath() {
        return InstanceIdentifier.create(NeutronRouterDpns.class).child(RouterDpnList.class).child(DpnVpninterfacesList.class);
    }

    @Override
    protected void add(final InstanceIdentifier<DpnVpninterfacesList> identifier, final DpnVpninterfacesList dpnInfo) {
        LOG.trace("Add event - key: {}, value: {}", identifier, dpnInfo);
        final String routerId = identifier.firstKeyOf(RouterDpnList.class).getRouterId();
        BigInteger dpnId = dpnInfo.getDpnId();
        //check router is associated to external network
        InstanceIdentifier<Routers> id = NatUtil.buildRouterIdentifier(routerId);
        Optional<Routers> routerData = NatUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            Uuid networkId = routerData.get().getNetworkId();
            if(networkId != null) {
                LOG.debug("Router {} is associated with ext nw {}", routerId, networkId);
                Uuid vpnName = NatUtil.getVpnForRouter(dataBroker,routerId);
                Long vpnId;
                if (vpnName == null) {
                    LOG.debug("Internal vpn associated to router {}",routerId);
                    vpnId = NatUtil.getVpnId(dataBroker,routerId);
                    if (vpnId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid vpnId returned for routerName {}",routerId);
                        return;
                    }
                    LOG.debug("Retrieved vpnId {} for router {}",vpnId,routerId);
                    //Install default entry in FIB to SNAT table
                    LOG.debug("Installing default route in FIB on dpn {} for router {} with vpn {}...", dpnId,routerId,vpnId);
                    snatDefaultRouteProgrammer.installDefNATRouteInDPN(dpnId, vpnId);
                } else {
                    LOG.debug("External BGP vpn associated to router {}",routerId);
                    vpnId = NatUtil.getVpnId(dataBroker, vpnName.getValue());
                    if (vpnId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid vpnId returned for routerName {}", routerId);
                        return;
                    }
                    Long routId = NatUtil.getVpnId(dataBroker, routerId);
                    if (routId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid routId returned for routerName {}",routerId);
                        return;
                    }
                    LOG.debug("Retrieved vpnId {} for router {}",vpnId,routerId);
                    //Install default entry in FIB to SNAT table
                    LOG.debug("Installing default route in FIB on dpn {} for routerId {} with vpnId {}...", dpnId,routerId,vpnId);
                    snatDefaultRouteProgrammer.installDefNATRouteInDPN(dpnId, vpnId, routId);
                }
                extNetGroupInstaller.installExtNetGroupEntries(networkId, dpnId);

                if (routerData.get().isEnableSnat()) {
                    LOG.info("SNAT enabled for router {}", routerId);
                    handleSNATForDPN(dpnId, routerId ,vpnId);
                } else {
                    LOG.info("SNAT is not enabled for router {} to handle addDPN event {}", routerId, dpnId);
                }
            }
        } else {
            LOG.debug("Router {} is not associated with External network", routerId);
        }
    }

    @Override
    protected void remove(InstanceIdentifier<DpnVpninterfacesList> identifier, DpnVpninterfacesList dpnInfo) {
        LOG.trace("Remove event - key: {}, value: {}", identifier, dpnInfo);
        final String routerId = identifier.firstKeyOf(RouterDpnList.class).getRouterId();
        BigInteger dpnId = dpnInfo.getDpnId();
        //check router is associated to external network
        InstanceIdentifier<Routers> id = NatUtil.buildRouterIdentifier(routerId);
        Optional<Routers> routerData = NatUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            Uuid networkId = routerData.get().getNetworkId();
            if (networkId != null) {
                LOG.debug("Router {} is associated with ext nw {}", routerId, networkId);
                Uuid vpnName = NatUtil.getVpnForRouter(dataBroker, routerId);
                Long vpnId;
                if (vpnName == null) {
                    LOG.debug("Internal vpn associated to router {}", routerId);
                    vpnId = NatUtil.getVpnId(dataBroker, routerId);
                    if (vpnId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid vpnId returned for routerName {}", routerId);
                        return;
                    }
                    LOG.debug("Retrieved vpnId {} for router {}",vpnId,routerId);
                    //Remove default entry in FIB
                    LOG.debug("Removing default route in FIB on dpn {} for vpn {} ...", dpnId, vpnName);
                    snatDefaultRouteProgrammer.removeDefNATRouteInDPN(dpnId, vpnId);
                } else {
                    LOG.debug("External vpn associated to router {}", routerId);
                    vpnId = NatUtil.getVpnId(dataBroker, vpnName.getValue());
                    if (vpnId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid vpnId returned for routerName {}", routerId);
                        return;
                    }
                    Long routId = NatUtil.getVpnId(dataBroker, routerId);
                    if (routId == NatConstants.INVALID_ID) {
                        LOG.error("Invalid routId returned for routerName {}",routerId);
                        return;
                    }
                    LOG.debug("Retrieved vpnId {} for router {}",vpnId,routerId);
                    //Remove default entry in FIB
                    LOG.debug("Removing default route in FIB on dpn {} for vpn {} ...", dpnId, vpnName);
                    snatDefaultRouteProgrammer.removeDefNATRouteInDPN(dpnId,vpnId,routId);
                }

                if (routerData.get().isEnableSnat()) {
                    LOG.info("SNAT enabled for router {}", routerId);
                    removeSNATFromDPN(dpnId, routerId, vpnId);
                } else {
                    LOG.info("SNAT is not enabled for router {} to handle removeDPN event {}", routerId, dpnId);
                }
            }
        }
    }

    @Override
    protected void update(InstanceIdentifier<DpnVpninterfacesList> identifier, DpnVpninterfacesList original, DpnVpninterfacesList update) {
        LOG.trace("Update event - key: {}, original: {}, update: {}", identifier, original, update);
    }
    void handleSNATForDPN(BigInteger dpnId, String routerName,Long routerVpnId) {
        //Check if primary and secondary switch are selected, If not select the role
        //Install select group to NAPT switch
        //Install default miss entry to NAPT switch
        BigInteger naptSwitch;
        try {
            Long routerId = NatUtil.getVpnId(dataBroker, routerName);
            if (routerId == NatConstants.INVALID_ID) {
                LOG.error("Invalid routerId returned for routerName {}", routerName);
                return;
            }
            BigInteger naptId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
            if (naptId == null || naptId.equals(BigInteger.ZERO) || !naptSwitchHA.getSwitchStatus(naptId)) {
                LOG.debug("No NaptSwitch is selected for router {}", routerName);

                naptSwitch = dpnId;
                boolean naptstatus = naptSwitchHA.updateNaptSwitch(routerName, naptSwitch);
                if (!naptstatus) {
                    LOG.error("Failed to update newNaptSwitch {} for routername {}", naptSwitch, routerName);
                    return;
                }
                LOG.debug("Switch {} is elected as NaptSwitch for router {}", dpnId, routerName);

                naptSwitchHA.installSnatFlows(routerName, routerId, naptSwitch, routerVpnId);

                // Install miss entry (table 26) pointing to table 46
                FlowEntity flowEntity = naptSwitchHA.buildSnatFlowEntityForNaptSwitch(dpnId, routerName, routerVpnId, NatConstants.ADD_FLOW);
                if (flowEntity == null) {
                    LOG.debug("Failed to populate flowentity for router {} with dpnId {}", routerName, dpnId);
                    return;
                }
                LOG.debug("Successfully installed flow for dpnId {} router {}", dpnId, routerName);
                mdsalManager.installFlow(flowEntity);
                //Removing primary flows from old napt switch
                if (naptId != null && !naptId.equals(BigInteger.ZERO)) {
                    LOG.debug("Removing primary flows from old napt switch {} for router {}", naptId, routerName);
                    naptSwitchHA.removeSnatFlowsInOldNaptSwitch(routerName, naptId, null);
                }
            } else if (naptId.equals(dpnId)) {
                    LOG.debug("NaptSwitch {} gone down during cluster reboot came alive", naptId);
            } else {

                LOG.debug("Napt switch with Id {} is already elected for router {}", naptId, routerName);
                naptSwitch = naptId;

                //installing group
                List<BucketInfo> bucketInfo = naptSwitchHA.handleGroupInNeighborSwitches(dpnId, routerName, naptSwitch);
                if (bucketInfo == null) {
                    LOG.debug("Failed to populate bucketInfo for dpnId {} routername {} naptSwitch {}", dpnId, routerName,
                            naptSwitch);
                    return;
                }
                naptSwitchHA.installSnatGroupEntry(dpnId, bucketInfo, routerName);

                // Install miss entry (table 26) pointing to group
                long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(routerName), idManager);
                FlowEntity flowEntity = naptSwitchHA.buildSnatFlowEntity(dpnId, routerName, groupId, routerVpnId, NatConstants.ADD_FLOW);
                if (flowEntity == null) {
                    LOG.debug("Failed to populate flowentity for router {} with dpnId {} groupId {}", routerName, dpnId, groupId);
                    return;
                }
                LOG.debug("Successfully installed flow for dpnId {} router {} group {}", dpnId, routerName, groupId);
                mdsalManager.installFlow(flowEntity);
            }
        } catch (Exception ex) {
            LOG.error("Exception in handleSNATForDPN method : {}", ex);
        }
    }

    void removeSNATFromDPN(BigInteger dpnId, String routerName, long routerVpnId) {
        //irrespective of naptswitch or non-naptswitch, SNAT default miss entry need to be removed
        //remove miss entry to NAPT switch
        //if naptswitch elect new switch and install Snat flows and remove those flows in oldnaptswitch

        //get ExternalIpIn prior
        List<String> externalIpCache;
        //HashMap Label
        HashMap<String,Long> externalIpLabel;
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("Invalid routerId returned for routerName {}",routerName);
            return;
        }
        externalIpCache = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
        externalIpLabel = NatUtil.getExternalIpsLabelForRouter(dataBroker,routerId);
        BigInteger naptSwitch = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
        if (naptSwitch == null || naptSwitch.equals(BigInteger.ZERO)) {
            LOG.debug("No naptSwitch is selected for router {}", routerName);
            return;
        }
        try {
            boolean naptStatus = naptSwitchHA.isNaptSwitchDown(routerName,dpnId,naptSwitch,routerVpnId,externalIpCache);
            if (!naptStatus) {
                LOG.debug("NaptSwitchDown: Switch with DpnId {} is not naptSwitch for router {}",
                        dpnId, routerName);
                long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(routerName), idManager);
                FlowEntity flowEntity = null;
                try {
                    flowEntity = naptSwitchHA.buildSnatFlowEntity(dpnId, routerName, groupId, routerVpnId, NatConstants.DEL_FLOW);
                    if (flowEntity == null) {
                        LOG.debug("Failed to populate flowentity for router {} with dpnId {} groupIs {}",routerName,dpnId,groupId);
                        return;
                    }
                    LOG.debug("NAT Service : Removing default SNAT miss entry flow entity {}",flowEntity);
                    mdsalManager.removeFlow(flowEntity);

                } catch (Exception ex) {
                    LOG.debug("NAT Service : Failed to remove default SNAT miss entry flow entity {} : {}",flowEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : Removed default SNAT miss entry flow for dpnID {} with routername {}", dpnId, routerName);

                //remove group
                GroupEntity groupEntity = null;
                try {
                    groupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName,
                            GroupTypes.GroupAll, null);
                    LOG.info("NAT Service : Removing NAPT GroupEntity:{}", groupEntity);
                    mdsalManager.removeGroup(groupEntity);
                } catch (Exception ex) {
                    LOG.debug("NAT Service : Failed to remove group entity {} : {}",groupEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : Removed default SNAT miss entry flow for dpnID {} with routerName {}", dpnId, routerName);
            } else {
                naptSwitchHA.removeSnatFlowsInOldNaptSwitch(routerName, naptSwitch,externalIpLabel);
                //remove table 26 flow ppointing to table46
                FlowEntity flowEntity = null;
                try {
                    flowEntity = naptSwitchHA.buildSnatFlowEntityForNaptSwitch(dpnId, routerName, routerVpnId, NatConstants.DEL_FLOW);
                    if (flowEntity == null) {
                        LOG.debug("Failed to populate flowentity for router {} with dpnId {}",routerName,dpnId);
                        return;
                    }
                    LOG.debug("NAT Service : Removing default SNAT miss entry flow entity for router {} with dpnId {} in napt switch {}"
                            ,routerName,dpnId,naptSwitch);
                    mdsalManager.removeFlow(flowEntity);

                } catch (Exception ex) {
                    LOG.debug("NAT Service : Failed to remove default SNAT miss entry flow entity {} : {}",flowEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : Removed default SNAT miss entry flow for dpnID {} with routername {}", dpnId, routerName);

                //best effort to check IntExt model
                naptSwitchHA.bestEffortDeletion(routerId,routerName,externalIpLabel);
            }
        } catch (Exception ex) {
            LOG.debug("Exception while handling naptSwitch down for router {} : {}",routerName,ex);
        }
    }
}