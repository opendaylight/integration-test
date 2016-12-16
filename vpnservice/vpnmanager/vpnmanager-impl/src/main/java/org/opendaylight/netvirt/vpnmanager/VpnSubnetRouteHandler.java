/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import java.math.BigInteger;
import java.util.*;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.vpnmanager.VpnOpDataSyncer.VpnOpDataType;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface.OperStatus;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.LockManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.PortOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.SubnetOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.TaskState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalNetworks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.NetworksKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.PortAddedToSubnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.PortRemovedFromSubnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterAssociatedToVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterDisassociatedFromVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetAddedToVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetAddedToVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetDeletedFromVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetDeletedFromVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetUpdatedInVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VpnSubnetRouteHandler implements NeutronvpnListener {
    private static final Logger logger = LoggerFactory.getLogger(VpnSubnetRouteHandler.class);
    private final DataBroker dataBroker;
    private final SubnetOpDpnManager subOpDpnManager;
    private final IBgpManager bgpManager;
    private final VpnInterfaceManager vpnInterfaceManager;
    private final IdManagerService idManager;
    private LockManagerService lockManager;
    private final VpnOpDataSyncer vpnOpDataSyncer;

    public VpnSubnetRouteHandler(final DataBroker dataBroker, final SubnetOpDpnManager subnetOpDpnManager,
                                 final IBgpManager bgpManager, final VpnInterfaceManager vpnIntfManager,
                                 final IdManagerService idManager, LockManagerService lockManagerService,
                                 final VpnOpDataSyncer vpnOpDataSyncer) {
        this.dataBroker = dataBroker;
        this.subOpDpnManager = subnetOpDpnManager;
        this.bgpManager = bgpManager;
        this.vpnInterfaceManager = vpnIntfManager;
        this.idManager = idManager;
        this.lockManager = lockManagerService;
        this.vpnOpDataSyncer = vpnOpDataSyncer;
    }

    @Override
    public void onSubnetAddedToVpn(SubnetAddedToVpn notification) {
        if (!notification.isExternalVpn()) {
            return;
        }

        Uuid subnetId = notification.getSubnetId();
        String vpnName = notification.getVpnName();
        String subnetIp = notification.getSubnetIp();
        Long elanTag = notification.getElanTag();
        boolean isRouteAdvertised = false;

        Preconditions.checkNotNull(subnetId, "SubnetId cannot be null or empty!");
        Preconditions.checkNotNull(subnetIp, "SubnetPrefix cannot be null or empty!");
        Preconditions.checkNotNull(vpnName, "VpnName cannot be null or empty!");
        Preconditions.checkNotNull(elanTag, "ElanTag cannot be null or empty!");

        logger.info("onSubnetAddedToVpn: Subnet {} being added to vpn", subnetId.getValue());
        long vpnId = VpnUtil.getVpnId(dataBroker, vpnName);
        if (vpnId == VpnConstants.INVALID_ID) {
            vpnOpDataSyncer.waitForVpnDataReady(VpnOpDataType.vpnInstanceToId, vpnName,
                                                VpnConstants.PER_VPN_INSTANCE_MAX_WAIT_TIME_IN_MILLISECONDS);
            vpnId = VpnUtil.getVpnId(dataBroker, vpnName);
            if (vpnId == VpnConstants.INVALID_ID) {
                logger.error("onSubnetAddedToVpn: VpnInstance to VPNId mapping not yet available for VpnName {} processing subnet {} with IP {} " +
                        ", bailing out now.", vpnName, subnetId, subnetIp);
                return;
            }
        }
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                Subnetmap subMap = null;

                // Please check if subnetId belongs to an External Network
                InstanceIdentifier<Subnetmap> subMapid = InstanceIdentifier.builder(Subnetmaps.class).
                        child(Subnetmap.class, new SubnetmapKey(subnetId)).build();
                Optional<Subnetmap> sm = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, subMapid);
                if (!sm.isPresent()) {
                    logger.error("onSubnetAddedToVpn: Unable to retrieve subnetmap entry for subnet : " + subnetId);
                    return;
                }
                subMap = sm.get();
                InstanceIdentifier<Networks> netsIdentifier = InstanceIdentifier.builder(ExternalNetworks.class).
                        child(Networks.class, new NetworksKey(subMap.getNetworkId())).build();
                Optional<Networks> optionalNets = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, netsIdentifier);
                if (optionalNets.isPresent()) {
                    logger.info("onSubnetAddedToVpn: subnet {} is an external subnet on external network {}, so ignoring this for SubnetRoute",
                            subnetId.getValue(), subMap.getNetworkId().getValue());
                    return;
                }
                //Create and add SubnetOpDataEntry object for this subnet to the SubnetOpData container
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                        LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (optionalSubs.isPresent()) {
                    logger.error("onSubnetAddedToVpn: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " already detected to be present");
                    return;
                }
                logger.debug("onSubnetAddedToVpn: Creating new SubnetOpDataEntry node for subnet: " +  subnetId.getValue());
                Map<BigInteger, SubnetToDpn> subDpnMap = new HashMap<BigInteger, SubnetToDpn>();
                SubnetOpDataEntry subOpEntry = null;
                BigInteger dpnId = null;
                BigInteger nhDpnId = null;
                SubnetToDpn subDpn = null;

                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder().setKey(new SubnetOpDataEntryKey(subnetId));
                subOpBuilder.setSubnetId(subnetId);
                subOpBuilder.setSubnetCidr(subnetIp);
                String rd = VpnUtil.getVpnRdFromVpnInstanceConfig(dataBroker, vpnName);
                if (rd == null) {
                    logger.error("onSubnetAddedToVpn: The VPN Instance name " + notification.getVpnName() + " does not have RD ");
                    return;
                }
                subOpBuilder.setVrfId(rd);
                subOpBuilder.setVpnName(vpnName);
                subOpBuilder.setSubnetToDpn(new ArrayList<SubnetToDpn>());
                subOpBuilder.setRouteAdvState(TaskState.Na);
                subOpBuilder.setElanTag(elanTag);

                // First recover set of ports available in this subnet
                List<Uuid> portList = subMap.getPortList();
                if (portList != null) {
                    for (Uuid port: portList) {
                        Interface intfState = InterfaceUtils.getInterfaceStateFromOperDS(dataBroker,port.getValue());
                        if (intfState != null) {
                            try {
                                dpnId = InterfaceUtils.getDpIdFromInterface(intfState);
                            } catch (Exception e) {
                                logger.error("onSubnetAddedToVpn: Unable to obtain dpnId for interface {},",
                                        " subnetroute inclusion for this interface failed with exception {}",
                                        port.getValue(), e);
                                continue;
                            }
                            if (dpnId.equals(BigInteger.ZERO)) {
                                logger.info("onSubnetAddedToVpn: Port " + port.getValue() + " is not assigned DPN yet, ignoring ");
                                continue;
                            }
                            subOpDpnManager.addPortOpDataEntry(port.getValue(), subnetId, dpnId);
                            if (intfState.getOperStatus() != OperStatus.Up) {
                                logger.info("onSubnetAddedToVpn: Port " + port.getValue() + " is not UP yet, ignoring ");
                                continue;
                            }
                            subDpn = subOpDpnManager.addInterfaceToDpn(subnetId, dpnId, port.getValue());
                            if (intfState.getOperStatus() == OperStatus.Up) {
                                // port is UP
                                subDpnMap.put(dpnId, subDpn);
                                if (nhDpnId == null) {
                                    nhDpnId = dpnId;
                                }
                            }
                        } else {
                            subOpDpnManager.addPortOpDataEntry(port.getValue(), subnetId, null);
                        }
                    }
                    if (subDpnMap.size() > 0) {
                        subOpBuilder.setSubnetToDpn(new ArrayList<SubnetToDpn>(subDpnMap.values()));
                    }
                }

                if (nhDpnId != null) {
                    logger.info("Next-Hop dpn {} is available for rd {} subnetIp {} vpn {}", nhDpnId, rd, subnetIp, vpnName);
                    subOpBuilder.setNhDpnId(nhDpnId);
                    try {
                        /*
                        Write the subnet route entry to the FIB.
                        And also advertise the subnet route entry via BGP.
                        */
                        int label = getLabel(rd, subnetIp);
                        if (label == 0) {
                            logger.error("Unable to fetch label from Id Manager. Bailing out of handling addition of subnet {} to vpn {}", subnetIp, vpnName);
                            return;
                        }
                        isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                        if (isRouteAdvertised) {
                            subOpBuilder.setRouteAdvState(TaskState.Done);
                        } else {
                            subOpBuilder.setNhDpnId(null);
                            subOpBuilder.setRouteAdvState(TaskState.Na);
                        }
                    } catch (Exception ex) {
                        logger.error("onSubnetAddedToVpn: FIB rules and Advertising nhDpnId " + nhDpnId +
                                " information for subnet " + subnetId.getValue() + " to BGP failed {}", ex);
                        subOpBuilder.setRouteAdvState(TaskState.Pending);
                    }
                }else{
                    logger.info("Next-Hop dpn is unavailable for rd {} subnetIp {} vpn {}", rd, subnetIp, vpnName);
                }

                subOpEntry = subOpBuilder.build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                logger.info("onSubnetAddedToVpn: Added subnetopdataentry to OP Datastore for subnet {}",
                        subnetId.getValue());
            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}", ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle subnet {} added to vpn {} {}", subnetIp, vpnName, e);
        }

    }

    @Override
    public void onSubnetDeletedFromVpn(SubnetDeletedFromVpn notification) {
        Uuid subnetId = notification.getSubnetId();

        if (!notification.isExternalVpn()) {
            return;
        }
        logger.info("onSubnetDeletedFromVpn: Subnet " + subnetId.getValue() + " being removed from vpn");
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                logger.trace(" Removing the SubnetOpDataEntry node for subnet: " +  subnetId.getValue());
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                        LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.error("onSubnetDeletedFromVpn: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " not available in datastore");
                    return;
                }

                /* If subnet is deleted (or if its removed from VPN), the ports that are DOWN on that subnet
                 * will continue to be stale in portOpData DS, as subDpnList used for portOpData removal will
                 * contain only ports that are UP. So here we explicitly cleanup the ports of the subnet by
                 * going through the list of ports on the subnet
                 */
                InstanceIdentifier<Subnetmap> subMapid = InstanceIdentifier.builder(Subnetmaps.class).
                        child(Subnetmap.class, new SubnetmapKey(subnetId)).build();
                Optional<Subnetmap> sm = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, subMapid);
                if (!sm.isPresent()) {
                    logger.error("Stale ports removal: Unable to retrieve subnetmap entry for subnet : " + subnetId);
                } else {
                    Subnetmap subMap = sm.get();
                    List<Uuid> portList = subMap.getPortList();
                    if (portList != null) {
                        for (Uuid port : portList) {
                            InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
                                    child(PortOpDataEntry.class, new PortOpDataEntryKey(port.getValue())).build();
                            logger.trace("Deleting portOpData entry for port " + port.getValue());
                            MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
                        }
                    }
                }

                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier);
                logger.info("onSubnetDeletedFromVpn: Removed subnetopdataentry for subnet {} successfully from Datastore", subnetId.getValue());
                try {
                    //Withdraw the routes for all the interfaces on this subnet
                    //Remove subnet route entry from FIB
                    deleteSubnetRouteFromFib(rd, subnetIp, vpnName);
                } catch (Exception ex) {
                    logger.error("onSubnetAddedToVpn: Withdrawing routes from BGP for subnet " +
                            subnetId.getValue() + " failed {}" + ex);
                }
            } catch (Exception ex) {
                logger.error("Removal of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle subnet {} removed to vpn {} {}", notification.getSubnetIp(), notification.getVpnName(), e);
        }
    }

    @Override
    public void onSubnetUpdatedInVpn(SubnetUpdatedInVpn notification) {
        Uuid subnetId = notification.getSubnetId();
        String vpnName = notification.getVpnName();
        String subnetIp = notification.getSubnetIp();
        Long elanTag = notification.getElanTag();

        Preconditions.checkNotNull(subnetId, "SubnetId cannot be null or empty!");
        Preconditions.checkNotNull(subnetIp, "SubnetPrefix cannot be null or empty!");
        Preconditions.checkNotNull(vpnName, "VpnName cannot be null or empty!");
        Preconditions.checkNotNull(elanTag, "ElanTag cannot be null or empty!");

        InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
        Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                LogicalDatastoreType.OPERATIONAL,
                subOpIdentifier);
        if (optionalSubs.isPresent()) {
            if (!notification.isExternalVpn()) {
                SubnetDeletedFromVpnBuilder bldr = new SubnetDeletedFromVpnBuilder().setVpnName(vpnName);
                bldr.setElanTag(elanTag).setExternalVpn(true).setSubnetIp(subnetIp).setSubnetId(subnetId);
                onSubnetDeletedFromVpn(bldr.build());
            }
            // TODO(vivek): Something got updated, but we donot know what ?
        } else {
            if (notification.isExternalVpn()) {
                SubnetAddedToVpnBuilder bldr = new SubnetAddedToVpnBuilder().setVpnName(vpnName).setElanTag(elanTag);
                bldr.setSubnetIp(subnetIp).setSubnetId(subnetId).setExternalVpn(true);;
                onSubnetAddedToVpn(bldr.build());
            }
            // TODO(vivek): Something got updated, but we donot know what ?
        }
    }

    @Override
    public void onPortAddedToSubnet(PortAddedToSubnet notification) {
        Uuid subnetId = notification.getSubnetId();
        Uuid portId = notification.getPortId();
        boolean isRouteAdvertised = false;

        logger.info("onPortAddedToSubnet: Port " + portId.getValue() + " being added to subnet " + subnetId.getValue());
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();

                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.info("onPortAddedToSubnet: Port " + portId.getValue() + " is part of a subnet " + subnetId.getValue() +
                            " that is not in VPN, ignoring");
                    return;
                }
                Interface intfState = InterfaceUtils.getInterfaceStateFromOperDS(dataBroker,portId.getValue());
                if (intfState == null) {
                    // Interface State not yet available
                    subOpDpnManager.addPortOpDataEntry(portId.getValue(), subnetId, null);
                    return;
                }
                BigInteger dpnId = BigInteger.ZERO;
                try {
                    dpnId = InterfaceUtils.getDpIdFromInterface(intfState);
                } catch (Exception e) {
                    logger.error("onSubnetAddedToVpn: Unable to obtain dpnId for interface {},",
                            " subnetroute inclusion for this interface failed with exception {}",
                            portId.getValue(), e);
                    return;
                }
                if (dpnId.equals(BigInteger.ZERO)) {
                    logger.info("onPortAddedToSubnet: Port " + portId.getValue() + " is not assigned DPN yet, ignoring ");
                    return;
                }
                subOpDpnManager.addPortOpDataEntry(portId.getValue(), subnetId, dpnId);
                if (intfState.getOperStatus() != OperStatus.Up) {
                    logger.info("onPortAddedToSubnet: Port " + portId.getValue() + " is not UP yet, ignoring ");
                    return;
                }
                logger.debug("onPortAddedToSubnet: Updating the SubnetOpDataEntry node for subnet: " + subnetId.getValue());
                SubnetToDpn subDpn = subOpDpnManager.addInterfaceToDpn(subnetId, dpnId, portId.getValue());
                if (subDpn == null) {
                    return;
                }
                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                List<SubnetToDpn> subDpnList = subOpBuilder.getSubnetToDpn();
                subDpnList.add(subDpn);
                subOpBuilder.setSubnetToDpn(subDpnList);
                if (subOpBuilder.getNhDpnId()  == null) {
                    subOpBuilder.setNhDpnId(dpnId);
                }
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                Long elanTag = subOpBuilder.getElanTag();
                if ((subOpBuilder.getRouteAdvState() == TaskState.Pending) ||
                        (subOpBuilder.getRouteAdvState() == TaskState.Na)) {
                    try {
                        // Write the Subnet Route Entry to FIB
                        // Advertise BGP Route here and set route_adv_state to DONE
                        int label = getLabel(rd, subnetIp);
                        if (label == 0) {
                            logger.error("Unable to fetch label from Id Manager. Bailing out of handling addition of port {} to subnet {} in vpn {}", portId.getValue(), subnetIp, vpnName);
                            return;
                        }
                        isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                        if (isRouteAdvertised) {
                            subOpBuilder.setRouteAdvState(TaskState.Done);
                        } else {
                            subOpBuilder.setNhDpnId(null);
                            subOpBuilder.setRouteAdvState(TaskState.Na);
                        }
                    } catch (Exception ex) {
                        logger.error("onPortAddedToSubnet: Advertising NextHopDPN "+ nhDpnId +
                                " information for subnet " + subnetId.getValue() + " to BGP failed {}", ex);
                    }
                }
                SubnetOpDataEntry subOpEntry = subOpBuilder.build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                logger.info("onPortAddedToSubnet: Updated subnetopdataentry to OP Datastore for port " + portId.getValue());

            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}", ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle port {} added to subnet {} {}", portId.getValue(), subnetId.getValue(), e);
        }
    }

    @Override
    public void onPortRemovedFromSubnet(PortRemovedFromSubnet notification) {
        Uuid subnetId = notification.getSubnetId();
        Uuid portId = notification.getPortId();
        boolean isRouteAdvertised = false;

        logger.info("onPortRemovedFromSubnet: Port " + portId.getValue() + " being removed from subnet " + subnetId.getValue());
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                PortOpDataEntry portOpEntry = subOpDpnManager.removePortOpDataEntry(portId.getValue());
                if (portOpEntry == null) {
                    return;
                }
                BigInteger dpnId = portOpEntry.getDpnId();
                if (dpnId == null) {
                    logger.debug("onPortRemovedFromSubnet:  Port {} does not have a DPNId associated, ignoring", portId.getValue());
                    return;
                }
                logger.debug("onPortRemovedFromSubnet: Updating the SubnetOpDataEntry node for subnet: " +  subnetId.getValue());
                boolean last = subOpDpnManager.removeInterfaceFromDpn(subnetId, dpnId, portId.getValue());
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.info("onPortRemovedFromSubnet: Port " + portId.getValue() + " is part of a subnet " + subnetId.getValue() +
                            " that is not in VPN, ignoring");
                    return;
                }
                SubnetOpDataEntry subOpEntry = null;
                List<SubnetToDpn> subDpnList = null;
                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                Long elanTag = subOpBuilder.getElanTag();
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                if ((nhDpnId != null) && (nhDpnId.equals(dpnId))) {
                    // select another NhDpnId
                    if (last) {
                        logger.debug("onPortRemovedFromSubnet: Last port " + portId + " on the subnet: " +  subnetId.getValue());
                        // last port on this DPN, so we need to swap the NHDpnId
                        subDpnList = subOpBuilder.getSubnetToDpn();
                        if (subDpnList.isEmpty()) {
                            subOpBuilder.setNhDpnId(null);
                            try {
                                // withdraw route from BGP
                                deleteSubnetRouteFromFib(rd, subnetIp, vpnName);
                                subOpBuilder.setRouteAdvState(TaskState.Na);
                            } catch (Exception ex) {
                                logger.error("onPortRemovedFromSubnet: Withdrawing NextHopDPN " + dpnId + " information for subnet " +
                                  subnetId.getValue() + " from BGP failed ", ex);
                                subOpBuilder.setRouteAdvState(TaskState.Pending);
                            }
                        } else {
                            nhDpnId = subDpnList.get(0).getDpnId();
                            subOpBuilder.setNhDpnId(nhDpnId);
                            logger.debug("onInterfaceDown: Swapping the Designated DPN to " + nhDpnId + " for subnet " + subnetId.getValue());
                            try {
                                // Best effort Withdrawal of route from BGP for this subnet
                                // Advertise the new NexthopIP to BGP for this subnet
                                //withdrawSubnetRoutefromBgp(rd, subnetIp);
                                int label = getLabel(rd, subnetIp);
                                if (label == 0) {
                                    logger.error("Unable to fetch label from Id Manager. Bailing out of handling removal  of port {} from subnet {} in vpn {}", portId.getValue(), subnetIp, vpnName);
                                    return;
                                }
                                isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                                if (isRouteAdvertised) {
                                    subOpBuilder.setRouteAdvState(TaskState.Done);
                                } else {
                                    subOpBuilder.setNhDpnId(null);
                                    subOpBuilder.setRouteAdvState(TaskState.Na);
                                }
                            } catch (Exception ex) {
                                logger.error("onPortRemovedFromSubnet: Swapping Withdrawing NextHopDPN " + dpnId +
                                        " information for subnet " + subnetId.getValue() +
                                        " to BGP failed {}" + ex);
                                subOpBuilder.setRouteAdvState(TaskState.Pending);
                            }
                        }
                    }
                }
                subOpEntry = subOpBuilder.build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                logger.info("onPortRemovedFromSubnet: Updated subnetopdataentry to OP Datastore removing port " + portId.getValue());
            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle port {} removed from subnet {} {}", portId.getValue(), subnetId.getValue(), e);
        }
    }

    public void onInterfaceUp(BigInteger dpnId, String intfName) {
        logger.info("onInterfaceUp: Port " + intfName);
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        SubnetToDpn subDpn = null;
        boolean isRouteAdvertised = false;
        PortOpDataEntry portOpEntry = subOpDpnManager.getPortOpDataEntry(intfName);
        if (portOpEntry == null) {
            logger.info("onInterfaceUp: Port " + intfName  + "is part of a subnet not in VPN, ignoring");
            return;
        }
        if ((dpnId == null) || (dpnId == BigInteger.ZERO)) {
            dpnId = portOpEntry.getDpnId();
            if (dpnId == null) {
                logger.error("onInterfaceUp: Unable to determine the DPNID for port " + intfName);
            return;
            }
        }
        Uuid subnetId = portOpEntry.getSubnetId();
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.error("onInterfaceUp: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " is not available");
                    return;
                }

                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                logger.debug("onInterfaceUp: Updating the SubnetOpDataEntry node for subnet: " +  subnetId.getValue());
                subOpDpnManager.addPortOpDataEntry(intfName, subnetId, dpnId);
                subDpn = subOpDpnManager.addInterfaceToDpn(subnetId, dpnId, intfName);
                if (subDpn == null) {
                    return;
                }
                List<SubnetToDpn> subDpnList = subOpBuilder.getSubnetToDpn();
                subDpnList.add(subDpn);
                subOpBuilder.setSubnetToDpn(subDpnList);
                if (subOpBuilder.getNhDpnId()  == null) {
                    subOpBuilder.setNhDpnId(dpnId);
                }
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                Long elanTag = subOpBuilder.getElanTag();
                if ((subOpBuilder.getRouteAdvState() == TaskState.Pending) || (subOpBuilder.getRouteAdvState() == TaskState.Na)) {
                    try {
                        // Write the Subnet Route Entry to FIB
                        // Advertise BGP Route here and set route_adv_state to DONE
                        int label = getLabel(rd, subnetIp);
                        if (label == 0) {
                            logger.error("Unable to fetch label from Id Manager. Bailing out of handling interface up event for port {} for subnet {} in vpn {}", intfName, subnetIp, vpnName);
                            return;
                        }
                        isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                        if(isRouteAdvertised) {
                            subOpBuilder.setRouteAdvState(TaskState.Done);
                        } else {
                            subOpBuilder.setNhDpnId(null);
                            subOpBuilder.setRouteAdvState(TaskState.Na);
                        }
                    } catch (Exception ex) {
                        logger.error("onInterfaceUp: Advertising NextHopDPN " + nhDpnId + " information for subnet " +
                                subnetId.getValue() + " to BGP failed {}" + ex);
                    }
                }
                SubnetOpDataEntry subOpEntry = subOpBuilder.build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                logger.info("onInterfaceUp: Updated subnetopdataentry to OP Datastore port up " + intfName);
            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle interface up event for port {} in subnet {} {}", portOpEntry.getPortId(), subnetId.getValue(), e);
        }
    }

    public void onInterfaceDown(final BigInteger dpnId, final String interfaceName) {
        boolean isRouteAdvertised = false;
        logger.info("onInterfaceDown: Port " + interfaceName);
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        PortOpDataEntry portOpEntry = subOpDpnManager.getPortOpDataEntry(interfaceName);
        if (portOpEntry == null) {
            logger.info("onInterfaceDown: Port " + interfaceName  + "is part of a subnet not in VPN, ignoring");
            return;
        }
        if ((dpnId  == null) ||(dpnId == BigInteger.ZERO)) {
            logger.error("onInterfaceDown: Unable to determine the DPNID for port " + interfaceName);
            return;
        }
        Uuid subnetId = portOpEntry.getSubnetId();
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                logger.debug("onInterfaceDown: Updating the SubnetOpDataEntry node for subnet: " +  subnetId.getValue());
                boolean last = subOpDpnManager.removeInterfaceFromDpn(subnetId, dpnId, interfaceName);
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                        LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.error("onInterfaceDown: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " is not available");
                    return;
                }
                SubnetOpDataEntry subOpEntry = null;
                List<SubnetToDpn> subDpnList = null;
                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                Long elanTag = subOpBuilder.getElanTag();
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                if ((nhDpnId != null) && (nhDpnId.equals(dpnId))) {
                    // select another NhDpnId
                    if (last) {
                        logger.debug("onInterfaceDown: Last active port " + interfaceName + " on the subnet: " +  subnetId.getValue());
                        // last port on this DPN, so we need to swap the NHDpnId
                        subDpnList = subOpBuilder.getSubnetToDpn();
                        if (subDpnList.isEmpty()) {
                            subOpBuilder.setNhDpnId(null);
                            try {
                                // Withdraw route from BGP for this subnet
                                deleteSubnetRouteFromFib(rd, subnetIp, vpnName);
                                subOpBuilder.setRouteAdvState(TaskState.Na);
                            } catch (Exception ex) {
                                logger.error("onInterfaceDown: Withdrawing NextHopDPN " + dpnId + " information for subnet " +
                                  subnetId.getValue() + " from BGP failed {}" + ex);
                                subOpBuilder.setRouteAdvState(TaskState.Pending);
                            }
                        } else {
                            nhDpnId = subDpnList.get(0).getDpnId();
                            subOpBuilder.setNhDpnId(nhDpnId);
                            logger.debug("onInterfaceDown: Swapping the Designated DPN to " + nhDpnId + " for subnet " + subnetId.getValue());
                            try {
                                // Best effort Withdrawal of route from BGP for this subnet
                                //withdrawSubnetRoutefromBgp(rd, subnetIp);
                                int label = getLabel(rd, subnetIp);
                                if (label == 0) {
                                    logger.error("Unable to fetch label from Id Manager. Bailing out of handling interface down event for port {} in subnet {} for vpn {}", interfaceName, subnetIp, vpnName);
                                    return;
                                }
                                isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                                if(isRouteAdvertised) {
                                    subOpBuilder.setRouteAdvState(TaskState.Done);
                                } else {
                                    subOpBuilder.setNhDpnId(null);
                                    subOpBuilder.setRouteAdvState(TaskState.Na);
                                }
                            } catch (Exception ex) {
                                logger.error("onInterfaceDown: Swapping Withdrawing NextHopDPN " + dpnId + " information for subnet " +
                                        subnetId.getValue() + " to BGP failed {}" + ex);
                                subOpBuilder.setRouteAdvState(TaskState.Pending);
                            }
                        }
                    }
                }
                subOpEntry = subOpBuilder.build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                logger.info("onInterfaceDown: Updated subnetopdataentry to OP Datastore port down " + interfaceName);
            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle interface down event for port {} in subnet {} {}", portOpEntry.getPortId(), subnetId.getValue(), e);
        }
    }

    @Override
    public void onRouterAssociatedToVpn(RouterAssociatedToVpn notification) {
    }

    @Override
    public void onRouterDisassociatedFromVpn(RouterDisassociatedFromVpn notification) {
    }

    public void updateSubnetRouteOnTunnelUpEvent(Uuid subnetId, BigInteger dpnId) {
        boolean isRouteAdvertised = false;
        logger.info("updateSubnetRouteOnTunnelUpEvent: Subnet {} Dpn {}", subnetId.getValue(), dpnId.toString());
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                        LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.error("updateSubnetRouteOnTunnelUpEvent: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " is not available");
                    return;
                }
                SubnetOpDataEntry subOpEntry = null;
                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                String rd = subOpBuilder.getVrfId();
                String subnetIp = subOpBuilder.getSubnetCidr();
                String vpnName = subOpBuilder.getVpnName();
                List<SubnetToDpn> subDpnList = subOpBuilder.getSubnetToDpn();
                long elanTag = subOpBuilder.getElanTag();
                if ((subOpBuilder.getRouteAdvState() == TaskState.Pending) || (subOpBuilder.getRouteAdvState() == TaskState.Na)) {
                    for (SubnetToDpn subDpn : subDpnList) {
                        if (subDpn.getDpnId().equals(dpnId)) {
                            if (subOpBuilder.getNhDpnId() == null) {
                                try {
                                    subOpBuilder.setNhDpnId(dpnId);
                                    int label = getLabel(rd, subnetIp);
                                    isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, dpnId, vpnName, elanTag, label, subnetId);
                                    if(isRouteAdvertised) {
                                        subOpBuilder.setRouteAdvState(TaskState.Done);
                                    } else {
                                        subOpBuilder.setNhDpnId(null);
                                        subOpBuilder.setRouteAdvState(TaskState.Na);
                                    }
                                } catch(Exception ex) {
                                    logger.error("updateSubnetRouteOnTunnelUpEvent: Advertising NextHopDPN " + dpnId + " information for subnet " +
                                            subnetId.getValue() + " to BGP failed {}" + ex);
                                }
                            }
                        }
                    }
                    subOpEntry = subOpBuilder.build();
                    MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                    logger.info("updateSubnetRouteOnTunnelUpEvent: Updated subnetopdataentry to OP Datastore tunnel up on dpn {} for subnet {}",
                            dpnId.toString(), subnetId.getValue());
                }
            } catch (Exception ex) {
                logger.error("Creation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle tunnel up event for subnetId {} dpnId {}", subnetId.getValue(), dpnId.toString());
        }
    }

    public void updateSubnetRouteOnTunnelDownEvent(Uuid subnetId, BigInteger dpnId) {
        logger.info("updateSubnetRouteOnTunnelDownEvent: Subnet {} Dpn {}", subnetId.getValue(), dpnId.toString());
        //TODO(vivek): Change this to use more granularized lock at subnetId level
        try {
            VpnUtil.lockSubnet(lockManager, subnetId.getValue());
            try {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(dataBroker,
                        LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    logger.error("updateSubnetRouteOnTunnelDownEvent: SubnetOpDataEntry for subnet " + subnetId.getValue() +
                            " is not available");
                    return;
                }
                SubnetOpDataEntry subOpEntry = null;
                SubnetOpDataEntryBuilder subOpBuilder = new SubnetOpDataEntryBuilder(optionalSubs.get());
                BigInteger nhDpnId = subOpBuilder.getNhDpnId();
                if ((nhDpnId != null) && (nhDpnId.equals(dpnId))) {
                    electNewDPNForSubNetRoute(subOpBuilder, dpnId, subnetId);
                    subOpEntry = subOpBuilder.build();
                    MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, subOpIdentifier, subOpEntry);
                    logger.info("updateSubnetRouteOnTunnelDownEvent: Updated subnetopdataentry to OP Datastore tunnnel down on dpn {} for subnet {}",
                            dpnId.toString(), subnetId.getValue());
                }
            } catch (Exception ex) {
                logger.error("Updation of SubnetOpDataEntry for subnet " +
                        subnetId.getValue() + " failed {}" + ex);
            } finally {
                VpnUtil.unlockSubnet(lockManager, subnetId.getValue());
            }
        } catch (Exception e) {
            logger.error("Unable to handle tunnel down event for subnetId {} dpnId {}", subnetId.getValue(), dpnId.toString());
        }
    }

    private boolean addSubnetRouteToFib(String rd, String subnetIp, BigInteger nhDpnId, String vpnName,
                                     Long elanTag, int label, Uuid subnetId) throws Exception {
        Preconditions.checkNotNull(rd, "RouteDistinguisher cannot be null or empty!");
        Preconditions.checkNotNull(subnetIp, "SubnetRouteIp cannot be null or empty!");
        Preconditions.checkNotNull(vpnName, "vpnName cannot be null or empty!");
        Preconditions.checkNotNull(elanTag, "elanTag cannot be null or empty!");
        String nexthopIp = null;
        try {
            nexthopIp = InterfaceUtils.getEndpointIpAddressForDPN(dataBroker, nhDpnId);
        } catch (Exception e) {
            logger.warn("Unable to find nexthopip for subnetroute subnetip {}", subnetIp);
            return false;
        }
        if (nexthopIp != null) {
            VpnUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, VpnUtil.getPrefixToInterfaceIdentifier(VpnUtil.getVpnId(dataBroker, vpnName), subnetIp), VpnUtil.getPrefixToInterface(nhDpnId, subnetId.getValue(), subnetIp));
            vpnInterfaceManager.addSubnetRouteFibEntryToDS(rd, vpnName, subnetIp, nexthopIp, label, elanTag, nhDpnId, null);
            try {
                //BGP manager will handle withdraw and advertise internally if prefix
                //already exist
                bgpManager.advertisePrefix(rd, null /*macAddress*/, subnetIp, Arrays.asList(nexthopIp),
                        VrfEntry.EncapType.Mplsgre, label, 0 /*l3vni*/, null /*gatewayMacAddress*/);
            } catch (Exception e) {
                logger.error("Fail: Subnet route not advertised for rd {} subnetIp {}", rd, subnetIp, e);
                throw e;
            }
        } else {
            logger.warn("The nexthopip is empty for subnetroute subnetip {}, ignoring fib route addition", subnetIp);
            return false;
        }
        return true;
    }

    private int getLabel(String rd, String subnetIp) {
        int label = VpnUtil.getUniqueId(idManager, VpnConstants.VPN_IDPOOL_NAME,
                                        VpnUtil.getNextHopLabelKey(rd, subnetIp));
        logger.trace("Allocated subnetroute label {} for rd {} prefix {}", label, rd, subnetIp);
        return label;
    }

    private void deleteSubnetRouteFromFib(String rd, String subnetIp, String vpnName) throws Exception {
        Preconditions.checkNotNull(rd, "RouteDistinguisher cannot be null or empty!");
        Preconditions.checkNotNull(subnetIp, "SubnetRouteIp cannot be null or empty!");
        vpnInterfaceManager.deleteSubnetRouteFibEntryFromDS(rd, subnetIp, vpnName);
        try {
            bgpManager.withdrawPrefix(rd, subnetIp);
        } catch (Exception e) {
            logger.error("Fail: Subnet route not withdrawn for rd {} subnetIp {}", rd, subnetIp, e);
            throw e;
        }
    }

    private void electNewDPNForSubNetRoute(SubnetOpDataEntryBuilder subOpBuilder , BigInteger dpnId, Uuid subnetId) {
        List<SubnetToDpn> subDpnList = null;
        boolean isRouteAdvertised = false;
        subDpnList = subOpBuilder.getSubnetToDpn();
        String rd = subOpBuilder.getVrfId();
        String subnetIp = subOpBuilder.getSubnetCidr();
        String vpnName = subOpBuilder.getVpnName();
        long elanTag = subOpBuilder.getElanTag();
        BigInteger nhDpnId = null;
        boolean isAlternateDpnSelected = false;
        Iterator<SubnetToDpn> subNetIt = subDpnList.iterator();
        int label = getLabel(rd, subnetIp);
        while (subNetIt.hasNext()) {
            SubnetToDpn subnetToDpn = subNetIt.next();
            nhDpnId = subnetToDpn.getDpnId();
            if (!nhDpnId.equals(dpnId)) {
                try {
                    //update the VRF entry for the subnetroute.
                    isRouteAdvertised = addSubnetRouteToFib(rd, subnetIp, nhDpnId, vpnName, elanTag, label, subnetId);
                    if (isRouteAdvertised) {
                        subOpBuilder.setRouteAdvState(TaskState.Done);
                        subOpBuilder.setNhDpnId(nhDpnId);
                        isAlternateDpnSelected = true;
                        break;
                    }
                } catch (Exception ex) {
                    logger.error("electNewDPNForSubNetRoute: Swapping and trying to configure NextHopDPN {} for subnet {} failed ex {}", dpnId.toString(), subnetId.getValue(), ex);
                    subOpBuilder.setRouteAdvState(TaskState.Na);
                }
            }
        }

        //If no alternate Dpn is selected as nextHopDpn ,withdraw the subnetroute.
        if (!isAlternateDpnSelected) {
            logger.info("No alternate DPN available for subnet {}.Prefix withdrawn from BGP", subnetIp);
            try {
                // Withdraw route from BGP for this subnet
                deleteSubnetRouteFromFib(rd, subnetIp, vpnName);
                subOpBuilder.setNhDpnId(null);
                subOpBuilder.setRouteAdvState(TaskState.Na);
            } catch (Exception ex) {
                logger.error("electNewDPNForSubNetRoute: Withdrawing NextHopDPN " + dpnId.toString() + " information for subnet " +
                        subnetId.getValue() + " from BGP failed {}" + ex);
                subOpBuilder.setRouteAdvState(TaskState.Pending);
            }
        }
    }
}

