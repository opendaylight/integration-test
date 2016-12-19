/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.clustering.ClusteringUtils;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundUtils;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface.OperStatus;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetExternalTunnelInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetExternalTunnelInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.DesignatedSwitchesForExternalTunnels;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.designated.switches._for.external.tunnels.DesignatedSwitchForTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.designated.switches._for.external.tunnels.DesignatedSwitchForTunnelBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.dhcp.rev160428.designated.switches._for.external.tunnels.DesignatedSwitchForTunnelKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSetBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpExternalTunnelManager {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpExternalTunnelManager.class);
    public static final String UNKNOWN_DMAC = "00:00:00:00:00:00";

    private final DataBroker broker;
    private final IMdsalApiManager mdsalUtil;
    private final ItmRpcService itmRpcService;
    private final EntityOwnershipService entityOwnershipService;
    private final IInterfaceManager interfaceManager;

    private final ConcurrentMap<BigInteger, Set<Pair<IpAddress, String>>> designatedDpnsToTunnelIpElanNameCache =
            new ConcurrentHashMap<>();
    private final ConcurrentMap<Pair<IpAddress, String>, Set<String>> tunnelIpElanNameToVmMacCache =
            new ConcurrentHashMap<>();
    private final ConcurrentMap<Pair<IpAddress, String>, Set<String>> availableVMCache = new ConcurrentHashMap<>();
    private final ConcurrentMap<Pair<BigInteger, String>, Port> vniMacAddressToPortCache = new ConcurrentHashMap<>();


    public DhcpExternalTunnelManager(final DataBroker broker,
            final IMdsalApiManager mdsalUtil, final ItmRpcService itmRpcService,
            final EntityOwnershipService entityOwnershipService, final IInterfaceManager interfaceManager) {
        this.broker = broker;
        this.mdsalUtil = mdsalUtil;
        this.itmRpcService = itmRpcService;
        this.entityOwnershipService = entityOwnershipService;
        this.interfaceManager = interfaceManager;
    }

    public void init() {
        initilizeCaches();
    }

    private void initilizeCaches() {
        LOG.trace("Loading designatedDpnsToTunnelIpElanNameCache");
        InstanceIdentifier<DesignatedSwitchesForExternalTunnels> instanceIdentifier =
                InstanceIdentifier.builder(DesignatedSwitchesForExternalTunnels.class).build();
        Optional<DesignatedSwitchesForExternalTunnels> designatedSwitchForTunnelOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, instanceIdentifier);
        if (designatedSwitchForTunnelOptional.isPresent()) {
            List<DesignatedSwitchForTunnel> list =
                    designatedSwitchForTunnelOptional.get().getDesignatedSwitchForTunnel();
            for (DesignatedSwitchForTunnel designatedSwitchForTunnel : list) {
                Set<Pair<IpAddress, String>> setOfTunnelIpElanNamePair =
                        designatedDpnsToTunnelIpElanNameCache.get(designatedSwitchForTunnel.getDpId());
                if (setOfTunnelIpElanNamePair == null) {
                    setOfTunnelIpElanNamePair = new CopyOnWriteArraySet<>();
                }
                Pair<IpAddress, String> tunnelIpElanNamePair =
                        new ImmutablePair<>(designatedSwitchForTunnel.getTunnelRemoteIpAddress(),
                                designatedSwitchForTunnel.getElanInstanceName());
                setOfTunnelIpElanNamePair.add(tunnelIpElanNamePair);
                designatedDpnsToTunnelIpElanNameCache.put(BigInteger.valueOf(designatedSwitchForTunnel.getDpId()),
                        setOfTunnelIpElanNamePair);
            }
        }
        LOG.trace("Loading vniMacAddressToPortCache");
        InstanceIdentifier<Ports> inst = InstanceIdentifier.builder(Neutron.class).child(Ports.class).build();
        Optional<Ports> optionalPorts = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (optionalPorts.isPresent()) {
            List<Port> list = optionalPorts.get().getPort();
            for (Port port : list) {
                if (NeutronUtils.isPortVnicTypeNormal(port)) {
                    continue;
                }
                String macAddress = port.getMacAddress().getValue();
                Uuid networkId = port.getNetworkId();
                String segmentationId = DhcpServiceUtils.getSegmentationId(networkId, broker);
                if (segmentationId == null) {
                    return;
                }
                updateVniMacToPortCache(new BigInteger(segmentationId), macAddress, port);
            }
        }
    }

    public BigInteger designateDpnId(IpAddress tunnelIp, String elanInstanceName, List<BigInteger> dpns) {
        BigInteger designatedDpnId = readDesignatedSwitchesForExternalTunnel(tunnelIp, elanInstanceName);
        if (designatedDpnId != null && !designatedDpnId.equals(DhcpMConstants.INVALID_DPID)) {
            LOG.trace("Dpn {} already designated for tunnelIp - elan : {} - {}", designatedDpnId, tunnelIp,
                    elanInstanceName);
            return designatedDpnId;
        }
        return chooseDpn(tunnelIp, elanInstanceName, dpns);
    }

    public void installDhcpFlowsForVms(final IpAddress tunnelIp, String elanInstanceName, final List<BigInteger> dpns,
            final BigInteger designatedDpnId, final String vmMacAddress) {
        LOG.trace("In installDhcpFlowsForVms ipAddress {}, elanInstanceName {}, dpn {}, vmMacAddress {}", tunnelIp,
                elanInstanceName, designatedDpnId, vmMacAddress);
        // TODO: Make use a util that directly tells if this is the owner or not rather than making use of callbacks.
        ListenableFuture<Boolean> checkEntityOwnerFuture = ClusteringUtils.checkNodeEntityOwner(
                entityOwnershipService, HwvtepSouthboundConstants.ELAN_ENTITY_TYPE,
                HwvtepSouthboundConstants.ELAN_ENTITY_NAME);
        Futures.addCallback(checkEntityOwnerFuture, new FutureCallback<Boolean>() {
            @Override
            public void onSuccess(Boolean isOwner) {
                if (isOwner) {
                    synchronized (getTunnelIpDpnKey(tunnelIp, designatedDpnId)) {
                        WriteTransaction tx = broker.newWriteOnlyTransaction();
                        dpns.remove(designatedDpnId);
                        for (BigInteger dpn : dpns) {
                            installDhcpDropAction(dpn, vmMacAddress, tx);
                        }
                        installDhcpEntries(designatedDpnId, vmMacAddress, tx);
                        DhcpServiceUtils.submitTransaction(tx);
                    }
                } else {
                    LOG.trace("Exiting installDhcpEntries since this cluster node is not the owner for dpn");
                }
            }

            @Override
            public void onFailure(Throwable error) {
                LOG.error("Error while fetching checkNodeEntityOwner", error);
            }
        });
        updateLocalCache(tunnelIp, elanInstanceName, vmMacAddress);
    }

    public void installDhcpFlowsForVms(BigInteger designatedDpnId, Set<String> listVmMacAddress, WriteTransaction tx) {
        for (String vmMacAddress : listVmMacAddress) {
            installDhcpEntries(designatedDpnId, vmMacAddress, tx);
        }
    }

    public void unInstallDhcpFlowsForVms(String elanInstanceName, List<BigInteger> dpns, String vmMacAddress) {
        unInstallDhcpEntriesOnDpns(dpns, vmMacAddress);
        removeFromLocalCache(elanInstanceName, vmMacAddress);
    }

    public void unInstallDhcpFlowsForVms(String elanInstanceName, IpAddress tunnelIp, List<BigInteger> dpns) {
        Pair<IpAddress, String> tunnelIpElanNamePair = new ImmutablePair<>(tunnelIp, elanInstanceName);
        Set<String> vmMacs = tunnelIpElanNameToVmMacCache.get(tunnelIpElanNamePair);
        LOG.trace("In unInstallFlowsForVms elanInstanceName {}, tunnelIp {}, dpns {}, vmMacs {}",
                elanInstanceName, tunnelIp, dpns, vmMacs);
        if (vmMacs == null) {
            return;
        }
        for (String vmMacAddress : vmMacs) {
            unInstallDhcpEntriesOnDpns(dpns, vmMacAddress);
        }
        tunnelIpElanNameToVmMacCache.remove(tunnelIpElanNamePair);
    }

    public BigInteger readDesignatedSwitchesForExternalTunnel(IpAddress tunnelIp, String elanInstanceName) {
        if (tunnelIp == null || elanInstanceName == null || elanInstanceName.isEmpty()) {
            return null;
        }
        InstanceIdentifier<DesignatedSwitchForTunnel> instanceIdentifier =
                InstanceIdentifier.builder(DesignatedSwitchesForExternalTunnels.class)
                        .child(DesignatedSwitchForTunnel.class,
                                new DesignatedSwitchForTunnelKey(elanInstanceName, tunnelIp)).build();
        Optional<DesignatedSwitchForTunnel> designatedSwitchForTunnelOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, instanceIdentifier);
        if (designatedSwitchForTunnelOptional.isPresent()) {
            return BigInteger.valueOf(designatedSwitchForTunnelOptional.get().getDpId());
        }
        return null;
    }

    public void writeDesignatedSwitchForExternalTunnel(BigInteger dpnId, IpAddress tunnelIp,
                                                       String elanInstanceName) {
        DesignatedSwitchForTunnelKey designatedSwitchForTunnelKey =
                new DesignatedSwitchForTunnelKey(elanInstanceName, tunnelIp);
        InstanceIdentifier<DesignatedSwitchForTunnel> instanceIdentifier =
                InstanceIdentifier.builder(DesignatedSwitchesForExternalTunnels.class)
                        .child(DesignatedSwitchForTunnel.class, designatedSwitchForTunnelKey).build();
        DesignatedSwitchForTunnel designatedSwitchForTunnel =
                new DesignatedSwitchForTunnelBuilder().setDpId(dpnId.longValue())
                        .setElanInstanceName(elanInstanceName).setTunnelRemoteIpAddress(tunnelIp)
                        .setKey(designatedSwitchForTunnelKey).build();
        LOG.trace("Writing into CONFIG DS tunnelIp {}, elanInstanceName {}, dpnId {}", tunnelIp, elanInstanceName,
                dpnId);
        MDSALUtil.syncUpdate(broker, LogicalDatastoreType.CONFIGURATION, instanceIdentifier, designatedSwitchForTunnel);
        updateLocalCache(dpnId, tunnelIp, elanInstanceName);
    }

    public void removeDesignatedSwitchForExternalTunnel(BigInteger dpnId, IpAddress tunnelIp,
                                                        String elanInstanceName) {
        DesignatedSwitchForTunnelKey designatedSwitchForTunnelKey =
                new DesignatedSwitchForTunnelKey(elanInstanceName, tunnelIp);
        InstanceIdentifier<DesignatedSwitchForTunnel> instanceIdentifier =
                InstanceIdentifier.builder(DesignatedSwitchesForExternalTunnels.class)
                        .child(DesignatedSwitchForTunnel.class, designatedSwitchForTunnelKey).build();
        LOG.trace("Removing from CONFIG DS tunnelIp {}, elanInstanceName {}, dpnId {}", tunnelIp,
                elanInstanceName, dpnId);
        MDSALUtil.syncDelete(broker, LogicalDatastoreType.CONFIGURATION, instanceIdentifier);
        removeFromLocalCache(dpnId, tunnelIp, elanInstanceName);
    }

    public void installDhcpDropActionOnDpn(BigInteger dpId) {
        List<String> vmMacs = getAllVmMacs();
        LOG.trace("Installing drop actions to this new DPN {} VMs {}", dpId, vmMacs);
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        for (String vmMacAddress : vmMacs) {
            installDhcpDropAction(dpId, vmMacAddress, tx);
        }
        DhcpServiceUtils.submitTransaction(tx);
    }

    private List<String> getAllVmMacs() {
        List<String> vmMacs = new LinkedList<>();
        Collection<Set<String>> listOfVmMacs = tunnelIpElanNameToVmMacCache.values();
        for (Set<String> list : listOfVmMacs) {
            vmMacs.addAll(list);
        }
        return vmMacs;
    }

    public void updateLocalCache(BigInteger designatedDpnId, IpAddress tunnelIp, String elanInstanceName) {
        Pair<IpAddress, String> tunnelIpElanName = new ImmutablePair<>(tunnelIp, elanInstanceName);
        Set<Pair<IpAddress, String>> tunnelIpElanNameSet;
        tunnelIpElanNameSet = designatedDpnsToTunnelIpElanNameCache.get(designatedDpnId);
        if (tunnelIpElanNameSet == null) {
            tunnelIpElanNameSet = new CopyOnWriteArraySet<>();
        }
        tunnelIpElanNameSet.add(tunnelIpElanName);
        LOG.trace("Updating designatedDpnsToTunnelIpElanNameCache for designatedDpn {} value {}", designatedDpnId,
                tunnelIpElanNameSet);
        designatedDpnsToTunnelIpElanNameCache.put(designatedDpnId, tunnelIpElanNameSet);
    }

    public void updateLocalCache(IpAddress tunnelIp, String elanInstanceName, String vmMacAddress) {
        Pair<IpAddress, String> tunnelIpElanName = new ImmutablePair<>(tunnelIp, elanInstanceName);
        Set<String> setOfExistingVmMacAddress;
        setOfExistingVmMacAddress = tunnelIpElanNameToVmMacCache.get(tunnelIpElanName);
        if (setOfExistingVmMacAddress == null) {
            setOfExistingVmMacAddress = new CopyOnWriteArraySet<>();
        }
        setOfExistingVmMacAddress.add(vmMacAddress);
        LOG.trace("Updating tunnelIpElanNameToVmMacCache for tunnelIpElanName {} value {}", tunnelIpElanName,
                setOfExistingVmMacAddress);
        tunnelIpElanNameToVmMacCache.put(tunnelIpElanName, setOfExistingVmMacAddress);
        updateExistingVMTunnelIPCache(tunnelIp, elanInstanceName, vmMacAddress);
    }

    public void updateExistingVMTunnelIPCache(IpAddress tunnelIp, String elanInstanceName, String vmMacAddress) {
        Pair<IpAddress, String> tunnelIpElanName = new ImmutablePair<IpAddress, String>(tunnelIp, elanInstanceName);
        Set<String> listExistingVmMacAddress;
        listExistingVmMacAddress = availableVMCache.get(tunnelIpElanName);
        if (listExistingVmMacAddress == null) {
            listExistingVmMacAddress = new CopyOnWriteArraySet<>();
        }
        listExistingVmMacAddress.add(vmMacAddress);
        LOG.trace("Updating availableVMCache for tunnelIpElanName {} value {}", tunnelIpElanName,
                listExistingVmMacAddress);
        availableVMCache.put(tunnelIpElanName, listExistingVmMacAddress);
    }

    public void handleDesignatedDpnDown(BigInteger dpnId, List<BigInteger> listOfDpns) {
        LOG.trace("In handleDesignatedDpnDown dpnId {}, listOfDpns {}", dpnId, listOfDpns);
        try {
            Set<Pair<IpAddress, String>> setOfTunnelIpElanNamePairs = designatedDpnsToTunnelIpElanNameCache.get(dpnId);
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            if (!dpnId.equals(DhcpMConstants.INVALID_DPID)) {
                List<String> listOfVms = getAllVmMacs();
                for (String vmMacAddress : listOfVms) {
                    unInstallDhcpEntries(dpnId, vmMacAddress, tx);
                }
            }
            if (setOfTunnelIpElanNamePairs == null || setOfTunnelIpElanNamePairs.isEmpty()) {
                LOG.trace("No tunnelIpElanName to handle for dpn {}. Returning", dpnId);
                return;
            }
            for (Pair<IpAddress, String> pair : setOfTunnelIpElanNamePairs) {
                updateCacheAndInstallNewFlows(dpnId, listOfDpns, pair, tx);
            }
            DhcpServiceUtils.submitTransaction(tx);
        } catch (ExecutionException e) {
            LOG.error("Error in handleDesignatedDpnDown {}", e);
        }
    }

    public void updateCacheAndInstallNewFlows(BigInteger dpnId,
            List<BigInteger> listOfDpns, Pair<IpAddress, String> pair, WriteTransaction tx)
            throws ExecutionException {
        BigInteger newDesignatedDpn = chooseDpn(pair.getLeft(), pair.getRight(), listOfDpns);
        if (newDesignatedDpn.equals(DhcpMConstants.INVALID_DPID)) {
            return;
        }
        Set<String> setOfVmMacs = tunnelIpElanNameToVmMacCache.get(pair);
        if (setOfVmMacs != null && !setOfVmMacs.isEmpty()) {
            LOG.trace("Updating DHCP flows for VMs {} with new designated DPN {}", setOfVmMacs, newDesignatedDpn);
            installDhcpFlowsForVms(newDesignatedDpn, setOfVmMacs, tx);
        }
    }

    private void changeExistingFlowToDrop(Pair<IpAddress, String> tunnelIpElanNamePair, BigInteger dpnId,
                                          WriteTransaction tx) {
        Set<String> setOfVmMacAddress = tunnelIpElanNameToVmMacCache.get(tunnelIpElanNamePair);
        if (setOfVmMacAddress == null || setOfVmMacAddress.isEmpty()) {
            return;
        }
        for (String vmMacAddress : setOfVmMacAddress) {
            installDhcpDropAction(dpnId, vmMacAddress, tx);
        }
    }

    /**
     * Choose a dpn among the list of elanDpns such that it has lowest count of being the designated dpn.
     * @param tunnelIp The tunnel Ip address
     * @param elanInstanceName The elan instance name
     * @param dpns The data path nodes
     * @return The designated dpn
     */
    private BigInteger chooseDpn(IpAddress tunnelIp, String elanInstanceName,
            List<BigInteger> dpns) {
        BigInteger designatedDpnId = DhcpMConstants.INVALID_DPID;
        if (dpns != null && dpns.size() != 0) {
            List<BigInteger> candidateDpns = DhcpServiceUtils.getDpnsForElan(elanInstanceName, broker);
            candidateDpns.retainAll(dpns);
            LOG.trace("Choosing new dpn for tunnelIp {}, elanInstanceName {}, among elanDpns {}",
                    tunnelIp, elanInstanceName, candidateDpns);
            boolean elanDpnAvailableFlag = true;
            if (candidateDpns == null || candidateDpns.isEmpty()) {
                candidateDpns = dpns;
                elanDpnAvailableFlag = false;
            }
            int size = 0;
            L2GatewayDevice device = getDeviceFromTunnelIp(elanInstanceName, tunnelIp);
            if (device == null) {
                LOG.trace("Could not find any device for elanInstanceName {} and tunnelIp {}",
                        elanInstanceName, tunnelIp);
                handleUnableToDesignateDpn(tunnelIp, elanInstanceName);
                return designatedDpnId;
            }
            for (BigInteger dpn : candidateDpns) {
                String hwvtepNodeId = device.getHwvtepNodeId();
                if (!elanDpnAvailableFlag) {
                    if (!isTunnelConfigured(dpn, hwvtepNodeId)) {
                        LOG.trace("Tunnel is not configured on dpn {} to TOR {}", dpn, hwvtepNodeId);
                        continue;
                    }
                } else if (!isTunnelUp(hwvtepNodeId, dpn)) {
                    LOG.trace("Tunnel is not up between dpn {} and TOR {}", dpn, hwvtepNodeId);
                    continue;
                }
                Set<Pair<IpAddress, String>> tunnelIpElanNameSet = designatedDpnsToTunnelIpElanNameCache.get(dpn);
                if (tunnelIpElanNameSet == null) {
                    designatedDpnId = dpn;
                    break;
                }
                if (size == 0 || tunnelIpElanNameSet.size() < size) {
                    size = tunnelIpElanNameSet.size();
                    designatedDpnId = dpn;
                }
            }
            writeDesignatedSwitchForExternalTunnel(designatedDpnId, tunnelIp, elanInstanceName);
            return designatedDpnId;
        }
        handleUnableToDesignateDpn(tunnelIp, elanInstanceName);
        return designatedDpnId;
    }

    private void handleUnableToDesignateDpn(IpAddress tunnelIp, String elanInstanceName) {
        writeDesignatedSwitchForExternalTunnel(DhcpMConstants.INVALID_DPID, tunnelIp, elanInstanceName);
    }

    private void installDhcpEntries(BigInteger dpnId, String vmMacAddress, WriteTransaction tx) {
        DhcpServiceUtils.setupDhcpFlowEntry(dpnId, NwConstants.DHCP_TABLE_EXTERNAL_TUNNEL,
                vmMacAddress, NwConstants.ADD_FLOW, mdsalUtil, tx);
    }

    public void unInstallDhcpEntries(BigInteger dpnId, String vmMacAddress, WriteTransaction tx) {
        DhcpServiceUtils.setupDhcpFlowEntry(dpnId, NwConstants.DHCP_TABLE_EXTERNAL_TUNNEL,
                vmMacAddress, NwConstants.DEL_FLOW, mdsalUtil, tx);
    }

    private void installDhcpDropAction(BigInteger dpn, String vmMacAddress, WriteTransaction tx) {
        DhcpServiceUtils.setupDhcpDropAction(dpn, NwConstants.DHCP_TABLE_EXTERNAL_TUNNEL,
                vmMacAddress, NwConstants.ADD_FLOW, mdsalUtil, tx);
    }

    public void handleTunnelStateDown(IpAddress tunnelIp, BigInteger interfaceDpn,
                                      List<ListenableFuture<Void>> futures) {
        LOG.trace("In handleTunnelStateDown tunnelIp {}, interfaceDpn {}", tunnelIp, interfaceDpn);
        if (interfaceDpn == null) {
            return;
        }
        try {
            synchronized (getTunnelIpDpnKey(tunnelIp, interfaceDpn)) {
                Set<Pair<IpAddress, String>> tunnelElanPairSet =
                        designatedDpnsToTunnelIpElanNameCache.get(interfaceDpn);
                if (tunnelElanPairSet == null || tunnelElanPairSet.isEmpty()) {
                    return;
                }
                WriteTransaction tx = broker.newWriteOnlyTransaction();
                for (Pair<IpAddress, String> tunnelElanPair : tunnelElanPairSet) {
                    IpAddress tunnelIpInDpn = tunnelElanPair.getLeft();
                    if (tunnelIpInDpn.equals(tunnelIp)) {
                        if (!checkL2GatewayConnection(tunnelElanPair)) {
                            LOG.trace("Couldn't find device for given tunnelIpElanPair {} in L2GwConnCache",
                                    tunnelElanPair);
                            return;
                        }
                        List<BigInteger> dpns = DhcpServiceUtils.getListOfDpns(broker);
                        dpns.remove(interfaceDpn);
                        changeExistingFlowToDrop(tunnelElanPair, interfaceDpn, tx);
                        updateCacheAndInstallNewFlows(interfaceDpn, dpns, tunnelElanPair, tx);
                    }
                }
                futures.add(tx.submit());
            }
        } catch (ExecutionException e) {
            LOG.error("Error in handleTunnelStateDown {}", e.getMessage());
            LOG.trace("Exception details {}", e);
        }
    }

    private boolean checkL2GatewayConnection(Pair<IpAddress, String> tunnelElanPair) {
        ConcurrentMap<String, L2GatewayDevice> l2GwDevices =
                ElanL2GwCacheUtils.getInvolvedL2GwDevices(tunnelElanPair.getRight());
        for (L2GatewayDevice device : l2GwDevices.values()) {
            if (device.getTunnelIp().equals(tunnelElanPair.getLeft())) {
                return true;
            }
        }
        return false;
    }

    private String getTunnelIpDpnKey(IpAddress tunnelIp, BigInteger interfaceDpn) {
        return tunnelIp.toString() + interfaceDpn;
    }

    private void removeFromLocalCache(String elanInstanceName, String vmMacAddress) {
        Set<Pair<IpAddress, String>> tunnelIpElanNameKeySet = tunnelIpElanNameToVmMacCache.keySet();
        for (Pair<IpAddress, String> pair : tunnelIpElanNameKeySet) {
            if (pair.getRight().trim().equalsIgnoreCase(elanInstanceName.trim())) {
                Set<String> setOfExistingVmMacAddress;
                setOfExistingVmMacAddress = tunnelIpElanNameToVmMacCache.get(pair);
                if (setOfExistingVmMacAddress == null || setOfExistingVmMacAddress.isEmpty()) {
                    continue;
                }
                LOG.trace("Removing vmMacAddress {} from listOfMacs {} for elanInstanceName {}", vmMacAddress,
                        setOfExistingVmMacAddress, elanInstanceName);
                setOfExistingVmMacAddress.remove(vmMacAddress);
                if (setOfExistingVmMacAddress.size() > 0) {
                    tunnelIpElanNameToVmMacCache.put(pair, setOfExistingVmMacAddress);
                    return;
                }
                tunnelIpElanNameToVmMacCache.remove(pair);
            }
        }
    }

    public void removeFromLocalCache(BigInteger designatedDpnId, IpAddress tunnelIp, String elanInstanceName) {
        Pair<IpAddress, String> tunnelIpElanName = new ImmutablePair<>(tunnelIp, elanInstanceName);
        Set<Pair<IpAddress, String>> tunnelIpElanNameSet;
        tunnelIpElanNameSet = designatedDpnsToTunnelIpElanNameCache.get(designatedDpnId);
        if (tunnelIpElanNameSet != null) {
            LOG.trace("Removing tunnelIpElan {} from designatedDpnsToTunnelIpElanNameCache. Existing list {} for "
                            + "designatedDpnId {}",
                    tunnelIpElanName, tunnelIpElanNameSet, designatedDpnId);
            tunnelIpElanNameSet.remove(tunnelIpElanName);
            if (tunnelIpElanNameSet.size() != 0) {
                designatedDpnsToTunnelIpElanNameCache.put(designatedDpnId, tunnelIpElanNameSet);
            } else {
                designatedDpnsToTunnelIpElanNameCache.remove(designatedDpnId);
            }
        }
    }

    public void updateVniMacToPortCache(BigInteger vni, String macAddress, Port port) {
        if (macAddress == null) {
            return;
        }
        Pair<BigInteger, String> vniMacAddressPair = new ImmutablePair<>(vni, macAddress.toUpperCase());
        LOG.trace("Updating vniMacAddressToPortCache with vni {} , mac {} , pair {} and port {}", vni,
                macAddress.toUpperCase(), vniMacAddressPair, port);
        vniMacAddressToPortCache.put(vniMacAddressPair, port);
    }

    public void removeVniMacToPortCache(BigInteger vni, String macAddress) {
        if (macAddress == null) {
            return;
        }
        Pair<BigInteger, String> vniMacAddressPair = new ImmutablePair<>(vni, macAddress.toUpperCase());
        vniMacAddressToPortCache.remove(vniMacAddressPair);
    }

    public Port readVniMacToPortCache(BigInteger vni, String macAddress) {
        if (macAddress == null) {
            return null;
        }
        Pair<BigInteger, String> vniMacAddressPair = new ImmutablePair<>(vni, macAddress.toUpperCase());
        LOG.trace("Reading vniMacAddressToPortCache with vni {} , mac {} , pair {} and port {}",
                vni, macAddress.toUpperCase(), vniMacAddressPair, vniMacAddressToPortCache.get(vniMacAddressPair));
        return vniMacAddressToPortCache.get(vniMacAddressPair);
    }

    public String getExternalTunnelInterfaceName(String sourceNode, String dstNode) {
        String tunnelInterfaceName = null;
        Class<? extends TunnelTypeBase> tunType = TunnelTypeVxlan.class;
        try {
            Future<RpcResult<GetExternalTunnelInterfaceNameOutput>> output = itmRpcService
                    .getExternalTunnelInterfaceName(new GetExternalTunnelInterfaceNameInputBuilder()
                            .setSourceNode(sourceNode).setDestinationNode(dstNode).setTunnelType(tunType).build());

            RpcResult<GetExternalTunnelInterfaceNameOutput> rpcResult = output.get();
            if (rpcResult.isSuccessful()) {
                tunnelInterfaceName = rpcResult.getResult().getInterfaceName();
                LOG.trace("Tunnel interface name: {}", tunnelInterfaceName);
            } else {
                LOG.warn("RPC call to ITM.GetExternalTunnelInterfaceName failed with error: {}", rpcResult.getErrors());
            }
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.error("Failed to get external tunnel interface name for sourceNode: {} and dstNode: {}: {} ",
                    sourceNode, dstNode, e);
        }
        return tunnelInterfaceName;
    }

    public static Optional<Node> getNode(DataBroker dataBroker, String physicalSwitchNodeId) {
        InstanceIdentifier<Node> psNodeId = HwvtepSouthboundUtils
                .createInstanceIdentifier(new NodeId(physicalSwitchNodeId));
        return MDSALUtil.read(LogicalDatastoreType.CONFIGURATION, psNodeId, dataBroker);
    }

    public RemoteMcastMacs createRemoteMcastMac(Node dstDevice, String logicalSwitchName, IpAddress internalTunnelIp) {
        List<LocatorSet> locators = new ArrayList<>();
        for (TerminationPoint tp : dstDevice.getTerminationPoint()) {
            HwvtepPhysicalLocatorAugmentation aug = tp.getAugmentation(HwvtepPhysicalLocatorAugmentation.class);
            if (internalTunnelIp.getIpv4Address().equals(aug.getDstIp().getIpv4Address())) {
                HwvtepPhysicalLocatorRef phyLocRef = new HwvtepPhysicalLocatorRef(
                        HwvtepSouthboundUtils.createPhysicalLocatorInstanceIdentifier(dstDevice.getNodeId(), aug));
                locators.add(new LocatorSetBuilder().setLocatorRef(phyLocRef).build());
            }
        }
        HwvtepLogicalSwitchRef lsRef = new HwvtepLogicalSwitchRef(HwvtepSouthboundUtils
                .createLogicalSwitchesInstanceIdentifier(dstDevice.getNodeId(), new HwvtepNodeName(logicalSwitchName)));

        RemoteMcastMacs remoteUcastMacs = new RemoteMcastMacsBuilder()
                .setMacEntryKey(new MacAddress(UNKNOWN_DMAC))
                .setLogicalSwitchRef(lsRef).setLocatorSet(locators).build();
        return remoteUcastMacs;
    }

    private WriteTransaction putRemoteMcastMac(WriteTransaction transaction, String elanName,
                                               L2GatewayDevice device, IpAddress internalTunnelIp) {
        Optional<Node> optionalNode = getNode(broker, device.getHwvtepNodeId());
        Node dstNode = optionalNode.get();
        if (dstNode == null) {
            LOG.trace("could not get device node {} ", device.getHwvtepNodeId());
            return null;
        }
        RemoteMcastMacs macs = createRemoteMcastMac(dstNode, elanName, internalTunnelIp);
        HwvtepUtils.putRemoteMcastMac(transaction, dstNode.getNodeId(), macs);
        return transaction;
    }

    public void installRemoteMcastMac(final BigInteger designatedDpnId, final IpAddress tunnelIp,
                                      final String elanInstanceName) {
        if (designatedDpnId.equals(DhcpMConstants.INVALID_DPID)) {
            return;
        }
        ListenableFuture<Boolean> checkEntityOwnerFuture = ClusteringUtils.checkNodeEntityOwner(entityOwnershipService,
                HwvtepSouthboundConstants.ELAN_ENTITY_TYPE, HwvtepSouthboundConstants.ELAN_ENTITY_NAME);
        Futures.addCallback(checkEntityOwnerFuture, new FutureCallback<Boolean>() {
            @Override
            public void onSuccess(Boolean isOwner) {
                if (isOwner) {
                    LOG.info("Installing remote McastMac");
                    L2GatewayDevice device = getDeviceFromTunnelIp(elanInstanceName, tunnelIp);
                    String tunnelInterfaceName = getExternalTunnelInterfaceName(String.valueOf(designatedDpnId),
                            device.getHwvtepNodeId());
                    IpAddress internalTunnelIp = null;
                    if (tunnelInterfaceName != null) {
                        Interface tunnelInterface =
                                interfaceManager.getInterfaceInfoFromConfigDataStore(tunnelInterfaceName);
                        if (tunnelInterface == null) {
                            LOG.trace("Tunnel Interface is not present {}", tunnelInterfaceName);
                            return;
                        }
                        internalTunnelIp = tunnelInterface.getAugmentation(IfTunnel.class).getTunnelSource();
                        WriteTransaction transaction = broker.newWriteOnlyTransaction();
                        putRemoteMcastMac(transaction, elanInstanceName, device, internalTunnelIp);
                        if (transaction != null) {
                            transaction.submit();
                        }
                    }
                } else {
                    LOG.info("Installing remote McastMac is not executed for this node.");
                }
            }

            @Override
            public void onFailure(Throwable error) {
                LOG.error("Failed to install remote McastMac", error);
            }
        });
    }

    private L2GatewayDevice getDeviceFromTunnelIp(String elanInstanceName, IpAddress tunnelIp) {
        ConcurrentMap<String, L2GatewayDevice> devices = L2GatewayCacheUtils.getCache();
        LOG.trace("In getDeviceFromTunnelIp devices {}", devices);
        for (L2GatewayDevice device : devices.values()) {
            if (tunnelIp.equals(device.getTunnelIp())) {
                return device;
            }
        }
        return null;
    }

    private boolean isTunnelUp(String nodeName, BigInteger dpn) {
        String tunnelInterfaceName = getExternalTunnelInterfaceName(String.valueOf(dpn), nodeName);
        if (tunnelInterfaceName == null) {
            LOG.trace("Tunnel Interface is not present on node {} with dpn {}", nodeName, dpn);
            return false;
        }
        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state
                .Interface tunnelInterface =
                DhcpServiceUtils.getInterfaceFromOperationalDS(tunnelInterfaceName, broker);
        if (tunnelInterface == null) {
            LOG.trace("Interface {} is not present in interface state", tunnelInterfaceName);
            return false;
        }
        return tunnelInterface.getOperStatus() == OperStatus.Up;
    }

    public void handleTunnelStateUp(IpAddress tunnelIp, BigInteger interfaceDpn, List<ListenableFuture<Void>> futures) {
        LOG.trace("In handleTunnelStateUp tunnelIp {}, interfaceDpn {}", tunnelIp, interfaceDpn);
        synchronized (getTunnelIpDpnKey(tunnelIp, interfaceDpn)) {
            Set<Pair<IpAddress, String>> tunnelIpElanPair =
                    designatedDpnsToTunnelIpElanNameCache.get(DhcpMConstants.INVALID_DPID);
            List<BigInteger> dpns = DhcpServiceUtils.getListOfDpns(broker);
            if (tunnelIpElanPair == null || tunnelIpElanPair.isEmpty()) {
                LOG.trace("There are no undesignated DPNs");
                return;
            }
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            for (Pair<IpAddress, String> pair : tunnelIpElanPair) {
                if (tunnelIp.equals(pair.getLeft())) {
                    BigInteger newDesignatedDpn = designateDpnId(tunnelIp, pair.getRight(), dpns);
                    if (newDesignatedDpn != null && !newDesignatedDpn.equals(DhcpMConstants.INVALID_DPID)) {
                        Set<String> vmMacAddress = tunnelIpElanNameToVmMacCache.get(pair);
                        if (vmMacAddress != null && !vmMacAddress.isEmpty()) {
                            LOG.trace("Updating DHCP flow for macAddress {} with newDpn {}",
                                    vmMacAddress, newDesignatedDpn);
                            installDhcpFlowsForVms(newDesignatedDpn, vmMacAddress, tx);
                        }
                    }
                }
            }
            futures.add(tx.submit());
        }
    }

    private boolean isTunnelConfigured(BigInteger dpn, String hwVtepNodeId) {
        String tunnelInterfaceName = getExternalTunnelInterfaceName(String.valueOf(dpn), hwVtepNodeId);
        if (tunnelInterfaceName == null) {
            return false;
        }
        Interface tunnelInterface = interfaceManager.getInterfaceInfoFromConfigDataStore(tunnelInterfaceName);
        if (tunnelInterface == null) {
            LOG.trace("Tunnel Interface is not present {}", tunnelInterfaceName);
            return false;
        }
        return true;
    }

    public void removeFromAvailableCache(Pair<IpAddress, String> tunnelIpElanName) {
        availableVMCache.remove(tunnelIpElanName);
    }

    private void unInstallDhcpEntriesOnDpns(final List<BigInteger> dpns, final String vmMacAddress) {
        // TODO: Make use a util that directly tells if this is the owner or not rather than making use of callbacks.
        ListenableFuture<Boolean> checkEntityOwnerFuture = ClusteringUtils.checkNodeEntityOwner(
                entityOwnershipService, HwvtepSouthboundConstants.ELAN_ENTITY_TYPE,
                HwvtepSouthboundConstants.ELAN_ENTITY_NAME);
        Futures.addCallback(checkEntityOwnerFuture, new FutureCallback<Boolean>() {
            @Override
            public void onSuccess(Boolean isOwner) {
                if (isOwner) {
                    WriteTransaction tx = broker.newWriteOnlyTransaction();
                    for (final BigInteger dpn : dpns) {
                        unInstallDhcpEntries(dpn, vmMacAddress, tx);
                    }
                    DhcpServiceUtils.submitTransaction(tx);
                } else {
                    LOG.trace("Exiting unInstallDhcpEntries since this cluster node is not the owner for dpn");
                }
            }

            @Override
            public void onFailure(Throwable error) {
                LOG.error("Error while fetching checkNodeEntityOwner", error);
            }
        });
    }

    public IpAddress getTunnelIpBasedOnElan(String elanInstanceName, String vmMacAddress) {
        LOG.trace("DhcpExternalTunnelManager getTunnelIpBasedOnElan elanInstanceName {}", elanInstanceName);
        IpAddress tunnelIp = null;
        Set<Pair<IpAddress, String>> tunnelElanKeySet = availableVMCache.keySet();
        Set<String> listExistingVmMacAddress;
        for (Pair<IpAddress, String> pair : tunnelElanKeySet) {
            LOG.trace("DhcpExternalTunnelManager getTunnelIpBasedOnElan left {} right {}", pair.getLeft(),
                    pair.getRight());
            if (pair.getRight().trim().equalsIgnoreCase(elanInstanceName.trim())) {
                listExistingVmMacAddress = availableVMCache.get(pair);
                if (listExistingVmMacAddress != null && !listExistingVmMacAddress.isEmpty()
                        && listExistingVmMacAddress.contains(vmMacAddress)) {
                    tunnelIp = pair.getLeft();
                    break;
                }
            }
        }
        LOG.trace("DhcpExternalTunnelManager getTunnelIpBasedOnElan returned tunnelIP {}", tunnelIp);
        return tunnelIp;
    }
}
