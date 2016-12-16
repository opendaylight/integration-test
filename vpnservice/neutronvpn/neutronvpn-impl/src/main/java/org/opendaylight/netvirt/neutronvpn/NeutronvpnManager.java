/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.EventListener;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.NotificationPublishService;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.VpnTargets;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.VpnTargetsBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTarget;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTargetBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTargetKey;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstanceBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstanceKey;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.vpn.instance.Ipv4FamilyBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstanceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.Adjacencies;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.AdjacenciesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.AdjacencyBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.AdjacencyKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.config.rev160806.NeutronvpnConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateNetworksInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateNetworksOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateNetworksOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateRouterInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DissociateNetworksInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DissociateNetworksOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DissociateNetworksOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DissociateRouterInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetFixedIPsForNeutronPortInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetFixedIPsForNeutronPortOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetFixedIPsForNeutronPortOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetL3VPNInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetL3VPNInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetL3VPNOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.createl3vpn.input.L3vpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetL3VPNOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterAssociatedToVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterAssociatedToVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterDisassociatedFromVpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterDisassociatedFromVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterInterfacesMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetAddedToVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetDeletedFromVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.SubnetUpdatedInVpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.VpnMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.getl3vpn.output.L3vpnInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.getl3vpn.output.L3vpnInstancesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.InterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.InterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveStaticRouteInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveStaticRouteInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.VpnRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.l3.attributes.Routes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.Router;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcError;
import org.opendaylight.yangtools.yang.common.RpcError.ErrorType;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yangtools.yang.common.RpcResultBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;

public class NeutronvpnManager implements NeutronvpnService, AutoCloseable, EventListener {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronvpnManager.class);
    private final DataBroker dataBroker;
    private final NeutronvpnNatManager nvpnNatManager;
    private final NotificationPublishService notificationPublishService;
    private final VpnRpcService vpnRpcService;
    private final NeutronFloatingToFixedIpMappingChangeListener floatingIpMapListener;
    private final NeutronvpnConfig neutronvpnConfig;
    private final IMdsalApiManager mdsalUtil;
    private final IElanService elanService;
    Boolean isExternalVpn;

    /**
     * @param dataBroker DataBroker reference
     * @param mdsalManager MDSAL Util API access
     * @param notiPublishService notificationPublishService
     * @param vpnNatMgr VPN NAT manager service
     * @param vpnRpcSrv VPN RPC service
     * @param elanService ELAN service
     * @param neutronFloatingToFixedIpMappingChangeListener FIP to FixedIP listener
     * @param neutronvpnConfig Neutronvpn configuration service
     */
    public NeutronvpnManager(
            final DataBroker dataBroker, final IMdsalApiManager mdsalManager,
            final NotificationPublishService notiPublishService, final NeutronvpnNatManager vpnNatMgr,
            final VpnRpcService vpnRpcSrv, final IElanService elanService,
            final NeutronFloatingToFixedIpMappingChangeListener neutronFloatingToFixedIpMappingChangeListener,
            final NeutronvpnConfig neutronvpnConfig) {
        this.dataBroker = dataBroker;
        mdsalUtil = mdsalManager;
        nvpnNatManager = vpnNatMgr;
        notificationPublishService = notiPublishService;
        vpnRpcService = vpnRpcSrv;
        this.elanService = elanService;
        floatingIpMapListener = neutronFloatingToFixedIpMappingChangeListener;
        LOG.info("neutronvpnConfig: {}", neutronvpnConfig);
        this.neutronvpnConfig = neutronvpnConfig;
    }

    @Override
    public void close() throws Exception {
        LOG.info("{} close", getClass().getSimpleName());
    }

    public NeutronvpnConfig getNeutronvpnConfig() {
        return neutronvpnConfig;
    }

    protected void updateSubnetNodeWithFixedIps(Uuid subnetId, Uuid routerId,
                                                Uuid routerInterfaceName, String fixedIp,
                                                String routerIntfMacAddress) {
        Subnetmap subnetmap = null;
        SubnetmapBuilder builder = null;
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class).
                child(Subnetmap.class, new SubnetmapKey(subnetId)).build();
        try {
            synchronized (subnetId.getValue().intern()) {
                Optional<Subnetmap> sn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
                if (sn.isPresent()) {
                    builder = new SubnetmapBuilder(sn.get());
                    LOG.debug("WithRouterFixedIPs: Updating existing subnetmap node for subnet ID {}", subnetId.getValue());
                } else {
                    builder = new SubnetmapBuilder().setKey(new SubnetmapKey(subnetId)).setId(subnetId);
                    LOG.debug("WithRouterFixedIPs: creating new subnetmap node for subnet ID {}", subnetId.getValue());
                }
                if (routerId != null) {
                    builder.setRouterId(routerId);
                } else {
                    builder.setRouterId(null);
                }
                if (routerInterfaceName != null) {
                    builder.setRouterInterfaceName(routerInterfaceName);
                } else {
                    builder.setRouterInterfaceName(null);
                }
                if (routerIntfMacAddress != null) {
                    builder.setRouterIntfMacAddress(routerIntfMacAddress);
                } else {
                    builder.setRouterIntfMacAddress(null);
                }
                if (fixedIp != null) {
                    List<String> fixedIps = builder.getRouterInterfaceFixedIps();
                    if (fixedIps == null) {
                        fixedIps = new ArrayList<>();
                    }
                    fixedIps.add(fixedIp);
                    builder.setRouterInterfaceFixedIps(fixedIps);
                } else {
                    builder.setRouterInterfaceFixedIps(null);
                }
                subnetmap = builder.build();
                LOG.debug("WithRouterFixedIPs Creating/Updating subnetMap node for Router FixedIps: {} ", subnetId.getValue());
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id, subnetmap);
            }
        } catch (Exception e) {
            LOG.error("WithRouterFixedIPs: Updation of subnetMap for Router FixedIps failed for node: {}", subnetId.getValue());
        }
    }

    protected Subnetmap updateSubnetNode(Uuid subnetId, String subnetIp, Uuid tenantId, Uuid networkId, Uuid routerId,
                                         Uuid vpnId) {
        Subnetmap subnetmap = null;
        SubnetmapBuilder builder = null;
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class)
                .child(Subnetmap.class, new SubnetmapKey(subnetId))
                .build();
        try {
            synchronized (subnetId.getValue().intern()) {
                Optional<Subnetmap> sn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
                if (sn.isPresent()) {
                    builder = new SubnetmapBuilder(sn.get());
                    LOG.debug("updating existing subnetmap node for subnet ID {}", subnetId.getValue());
                } else {
                    builder = new SubnetmapBuilder().setKey(new SubnetmapKey(subnetId)).setId(subnetId);
                    LOG.debug("creating new subnetmap node for subnet ID {}", subnetId.getValue());
                }

                if (subnetIp != null) {
                    builder.setSubnetIp(subnetIp);
                }
                if (routerId != null) {
                    builder.setRouterId(routerId);
                }
                if (networkId != null) {
                    builder.setNetworkId(networkId);
                }
                if (vpnId != null) {
                    builder.setVpnId(vpnId);
                }
                if (tenantId != null) {
                    builder.setTenantId(tenantId);
                }

                subnetmap = builder.build();
                LOG.debug("Creating/Updating subnetMap node: {} ", subnetId.getValue());
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id, subnetmap);
            }
        } catch (Exception e) {
            LOG.error("Updation of subnetMap failed for node: {}", subnetId.getValue());
        }
        return subnetmap;
    }

    protected Subnetmap removeFromSubnetNode(Uuid subnetId, Uuid networkId, Uuid routerId, Uuid vpnId, Uuid portId) {
        Subnetmap subnetmap = null;
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class)
                .child(Subnetmap.class, new SubnetmapKey(subnetId))
                .build();
        try {
            synchronized (subnetId.getValue().intern()) {
                Optional<Subnetmap> sn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
                if (sn.isPresent()) {
                    SubnetmapBuilder builder = new SubnetmapBuilder(sn.get());
                    if (routerId != null) {
                        builder.setRouterId(null);
                    }
                    if (networkId != null) {
                        builder.setNetworkId(null);
                    }
                    if (vpnId != null) {
                        builder.setVpnId(null);
                    }
                    if (portId != null && builder.getPortList() != null) {
                        List<Uuid> portList = builder.getPortList();
                        portList.remove(portId);
                        builder.setPortList(portList);
                    }

                    subnetmap = builder.build();
                    LOG.debug("Removing from existing subnetmap node: {} ", subnetId.getValue());
                    MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id, subnetmap);
                } else {
                    LOG.warn("removing from non-existing subnetmap node: {} ", subnetId.getValue());
                }
            }
        } catch (Exception e) {
            LOG.error("Removal from subnetmap failed for node: {}", subnetId.getValue());
        }
        return subnetmap;
    }

    protected Subnetmap updateSubnetmapNodeWithPorts(Uuid subnetId, Uuid portId, Uuid directPortId) {
        Subnetmap subnetmap = null;
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class).child(Subnetmap.class,
                new SubnetmapKey(subnetId)).build();
        try {
            synchronized (subnetId.getValue().intern()) {
                Optional<Subnetmap> sn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
                if (sn.isPresent()) {
                    SubnetmapBuilder builder = new SubnetmapBuilder(sn.get());
                    if (null != portId) {
                        List<Uuid> portList = builder.getPortList();
                        if (null == portList) {
                            portList = new ArrayList<Uuid>();
                        }
                        portList.add(portId);
                        builder.setPortList(portList);
                        LOG.debug("Updating existing subnetmap node {} with port {}", subnetId.getValue(),
                                portId.getValue());
                    }
                    if (null != directPortId) {
                        List<Uuid> directPortList = builder.getDirectPortList();
                        if (null == directPortList) {
                            directPortList = new ArrayList<Uuid>();
                        }
                        directPortList.add(directPortId);
                        builder.setDirectPortList(directPortList);
                        LOG.debug("Updating existing subnetmap node {} with port {}", subnetId.getValue(),
                                directPortId.getValue());
                    }
                    subnetmap = builder.build();
                    MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id, subnetmap);
                } else {
                    LOG.error("Trying to update non-existing subnetmap node {} ", subnetId.getValue());
                }
            }
        } catch (Exception e) {
            LOG.error("Updating port list of a given subnetMap failed for node: {} with exception{}",
                    subnetId.getValue(), e);
        }
        return subnetmap;
    }

    protected Subnetmap removePortsFromSubnetmapNode(Uuid subnetId, Uuid portId, Uuid directPortId) {
        Subnetmap subnetmap = null;
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class).child(Subnetmap.class,
                new SubnetmapKey(subnetId)).build();
        try {
            synchronized (subnetId.getValue().intern()) {
                Optional<Subnetmap> sn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
                if (sn.isPresent()) {
                    SubnetmapBuilder builder = new SubnetmapBuilder(sn.get());
                    if (null != portId && null != builder.getPortList()) {
                        List<Uuid> portList = builder.getPortList();
                        portList.remove(portId);
                        builder.setPortList(portList);
                        LOG.debug("Removing port {} from existing subnetmap node: {} ", portId.getValue(),
                                subnetId.getValue());
                    }
                    if (null != directPortId && null != builder.getDirectPortList()) {
                        List<Uuid> directPortList = builder.getDirectPortList();
                        directPortList.remove(directPortId);
                        builder.setDirectPortList(directPortList);
                        LOG.debug("Removing direct port {} from existing subnetmap node: {} ", directPortId
                                .getValue(), subnetId.getValue());
                    }
                    subnetmap = builder.build();
                    MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, id, subnetmap);
                } else {
                    LOG.error("Trying to remove port from non-existing subnetmap node {}", subnetId.getValue());
                }
            }
        } catch (Exception e) {
            LOG.error("Removing a port from port list of a subnetmap failed for node: {} with expection {}",
                    subnetId.getValue(), e);
        }
        return subnetmap;
    }

    protected void deleteSubnetMapNode(Uuid subnetId) {
        InstanceIdentifier<Subnetmap> subnetMapIdentifier =
                InstanceIdentifier.builder(Subnetmaps.class).child(Subnetmap.class,new SubnetmapKey(subnetId)).build();
        LOG.debug("removing subnetMap node: {} ", subnetId.getValue());
        try {
            synchronized (subnetId.getValue().intern()) {
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, subnetMapIdentifier);
            }
        } catch (Exception e) {
            LOG.error("Delete subnetMap node failed for subnet : {} ", subnetId.getValue());
        }
    }

    private void updateVpnInstanceNode(String vpnName, List<String> rd, List<String> irt, List<String> ert, VpnInstance.Type type, long l3vni) {

        VpnInstanceBuilder builder = null;
        List<VpnTarget> vpnTargetList = new ArrayList<>();
        boolean isLockAcquired = false;
        InstanceIdentifier<VpnInstance> vpnIdentifier = InstanceIdentifier.builder(VpnInstances.class).child
                (VpnInstance.class, new VpnInstanceKey(vpnName)).build();
        try {
            Optional<VpnInstance> optionalVpn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    vpnIdentifier);
            LOG.debug("Creating/Updating a new vpn-instance node: {} ", vpnName);
            if (optionalVpn.isPresent()) {
                builder = new VpnInstanceBuilder(optionalVpn.get());
                LOG.debug("updating existing vpninstance node");
            } else {
                builder = new VpnInstanceBuilder().setKey(new VpnInstanceKey(vpnName)).setVpnInstanceName(vpnName).setType(type).setL3vni(l3vni);
            }
            if (irt != null && !irt.isEmpty()) {
                if (ert != null && !ert.isEmpty()) {
                    List<String> commonRT = new ArrayList<>(irt);
                    commonRT.retainAll(ert);

                    for (String common : commonRT) {
                        irt.remove(common);
                        ert.remove(common);
                        VpnTarget vpnTarget =
                                new VpnTargetBuilder().setKey(new VpnTargetKey(common)).setVrfRTValue(common)
                                        .setVrfRTType(VpnTarget.VrfRTType.Both).build();
                        vpnTargetList.add(vpnTarget);
                    }
                }
                for (String importRT : irt) {
                    VpnTarget vpnTarget =
                            new VpnTargetBuilder().setKey(new VpnTargetKey(importRT)).setVrfRTValue(importRT)
                                    .setVrfRTType(VpnTarget.VrfRTType.ImportExtcommunity).build();
                    vpnTargetList.add(vpnTarget);
                }
            }

            if (ert != null && !ert.isEmpty()) {
                for (String exportRT : ert) {
                    VpnTarget vpnTarget =
                            new VpnTargetBuilder().setKey(new VpnTargetKey(exportRT)).setVrfRTValue(exportRT)
                                    .setVrfRTType(VpnTarget.VrfRTType.ExportExtcommunity).build();
                    vpnTargetList.add(vpnTarget);
                }
            }

            VpnTargets vpnTargets = new VpnTargetsBuilder().setVpnTarget(vpnTargetList).build();

            Ipv4FamilyBuilder ipv4vpnBuilder = new Ipv4FamilyBuilder().setVpnTargets(vpnTargets);

            if (rd != null && !rd.isEmpty()) {
                ipv4vpnBuilder.setRouteDistinguisher(rd.get(0));
            }

            VpnInstance newVpn = builder.setIpv4Family(ipv4vpnBuilder.build()).build();
            isLockAcquired = NeutronvpnUtils.lock(vpnName);
            LOG.debug("Creating/Updating vpn-instance for {} ", vpnName);
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIdentifier, newVpn);
        } catch (Exception e) {
            LOG.error("Update VPN Instance node failed for node: {} {} {} {}", vpnName, rd, irt, ert);
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(vpnName);
            }
        }
    }

    private void deleteVpnMapsNode(Uuid vpnid) {
        boolean isLockAcquired = false;
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class)
                .child(VpnMap.class, new VpnMapKey(vpnid))
                .build();
        LOG.debug("removing vpnMaps node: {} ", vpnid.getValue());
        try {
            isLockAcquired = NeutronvpnUtils.lock(vpnid.getValue());
            MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier);
        } catch (Exception e) {
            LOG.error("Delete vpnMaps node failed for vpn : {} ", vpnid.getValue());
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(vpnid.getValue());
            }
        }
    }

    private void updateVpnMaps(Uuid vpnId, String name, Uuid router, Uuid tenantId, List<Uuid> networks) {
        VpnMapBuilder builder;
        boolean isLockAcquired = false;
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class)
                .child(VpnMap.class, new VpnMapKey(vpnId))
                .build();
        try {
            Optional<VpnMap> optionalVpnMap = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    vpnMapIdentifier);
            if (optionalVpnMap.isPresent()) {
                builder = new VpnMapBuilder(optionalVpnMap.get());
            } else {
                builder = new VpnMapBuilder().setKey(new VpnMapKey(vpnId)).setVpnId(vpnId);
            }

            if (name != null) {
                builder.setName(name);
            }
            if (tenantId != null) {
                builder.setTenantId(tenantId);
            }
            if (router != null) {
                builder.setRouterId(router);
            }
            if (networks != null) {
                List<Uuid> nwList = builder.getNetworkIds();
                if (nwList == null) {
                    nwList = new ArrayList<>();
                }
                nwList.addAll(networks);
                builder.setNetworkIds(nwList);
            }

            isLockAcquired = NeutronvpnUtils.lock(vpnId.getValue());
            LOG.debug("Creating/Updating vpnMaps node: {} ", vpnId.getValue());
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier, builder.build());
            LOG.debug("VPNMaps DS updated for VPN {} ", vpnId.getValue());
        } catch (Exception e) {
            LOG.error("UpdateVpnMaps failed for node: {} ", vpnId.getValue());
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(vpnId.getValue());
            }
        }
    }

    private void clearFromVpnMaps(Uuid vpnId, Uuid routerId, List<Uuid> networkIds) {
        boolean isLockAcquired = false;
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class)
                .child(VpnMap.class, new VpnMapKey(vpnId))
                .build();
        Optional<VpnMap> optionalVpnMap = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                vpnMapIdentifier);
        if (optionalVpnMap.isPresent()) {
            VpnMap vpnMap = optionalVpnMap.get();
            VpnMapBuilder vpnMapBuilder = new VpnMapBuilder(vpnMap);
            if (routerId != null) {
                if (vpnMap.getNetworkIds() == null && routerId.equals(vpnMap.getVpnId())) {
                    try {
                        // remove entire node in case of internal VPN
                        isLockAcquired = NeutronvpnUtils.lock(vpnId.getValue());
                        LOG.debug("removing vpnMaps node: {} ", vpnId);
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier);
                    } catch (Exception e) {
                        LOG.error("Deletion of vpnMaps node failed for vpn {}", vpnId.getValue());
                    } finally {
                        if (isLockAcquired) {
                            NeutronvpnUtils.unlock(vpnId.getValue());
                        }
                    }
                    return;
                }
                vpnMapBuilder.setRouterId(null);
            }
            if (networkIds != null) {
                List<Uuid> vpnNw = vpnMap.getNetworkIds();
                for (Uuid nw : networkIds) {
                    vpnNw.remove(nw);
                }
                if (vpnNw.isEmpty()) {
                    LOG.debug("setting networks null in vpnMaps node: {} ", vpnId.getValue());
                    vpnMapBuilder.setNetworkIds(null);
                } else {
                    vpnMapBuilder.setNetworkIds(vpnNw);
                }
            }

            try {
                isLockAcquired = NeutronvpnUtils.lock(vpnId.getValue());
                LOG.debug("clearing from vpnMaps node: {} ", vpnId.getValue());
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier,
                        vpnMapBuilder.build());
            } catch (Exception e) {
                LOG.error("Clearing from vpnMaps node failed for vpn {}", vpnId.getValue());
            } finally {
                if (isLockAcquired) {
                    NeutronvpnUtils.unlock(vpnId.getValue());
                }
            }
        } else {
            LOG.error("VPN : {} not found", vpnId.getValue());
        }
        LOG.debug("Clear from VPNMaps DS successful for VPN {} ", vpnId.getValue());
    }

    private void deleteVpnInstance(Uuid vpnId) {
        boolean isLockAcquired = false;
        InstanceIdentifier<VpnInstance> vpnIdentifier = InstanceIdentifier.builder(VpnInstances.class)
                .child(VpnInstance.class,
                        new VpnInstanceKey(vpnId.getValue()))
                .build();
        try {
            isLockAcquired = NeutronvpnUtils.lock(vpnId.getValue());
            LOG.debug("Deleting vpnInstance {}", vpnId.getValue());
            MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIdentifier);
        } catch (Exception e) {
            LOG.error("Deletion of VPNInstance node failed for VPN {}", vpnId.getValue());
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(vpnId.getValue());
            }
        }
    }

    protected void createVpnInterface(Uuid vpnId, Uuid routerId, Port port,
                                      WriteTransaction wrtConfigTxn) {
        String infName = port.getUuid().getValue();
        List<Adjacency> adjList = new ArrayList<>();
        List<FixedIps> ips = port.getFixedIps();
        Boolean isRouterInterface = false;
        if (port.getDeviceOwner() != null) {
            isRouterInterface = port.getDeviceOwner().equals(NeutronConstants.DEVICE_OWNER_ROUTER_INF);
        }
        LOG.trace("createVpnInterface - isRouterInterface:{}", isRouterInterface);
        Router rtr = null;
        if (routerId != null) {
            rtr = NeutronvpnUtils.getNeutronRouter(dataBroker, routerId);
        }
        // create adjacency list
        for (FixedIps ip : ips) {
            // create vm adjacency
            String ipValue = String.valueOf(ip.getIpAddress().getValue());
            String ipPrefix = (ip.getIpAddress().getIpv4Address() != null) ? ipValue + "/32" : ipValue + "/128";
            Adjacency vmAdj = new AdjacencyBuilder().setKey(new AdjacencyKey(ipPrefix)).setIpAddress(ipPrefix)
                    .setMacAddress(port.getMacAddress().getValue()).setPrimaryAdjacency(true)
                    .setSubnetId(ip.getSubnetId()).build();
            adjList.add(vmAdj);
            // create extra route adjacency
            if (rtr != null && rtr.getRoutes() != null) {
                List<Routes> routeList = rtr.getRoutes();
                List<Adjacency> erAdjList = getAdjacencyforExtraRoute(vpnId, routeList, ipValue);
                if (erAdjList != null && !erAdjList.isEmpty()) {
                    adjList.addAll(erAdjList);
                }
            }
            NeutronvpnUtils.createVpnPortFixedIpToPort(dataBroker, vpnId.getValue(), ipValue, infName, port
                            .getMacAddress().getValue(), isRouterInterface, true, false);
        }
        // create vpn-interface on this neutron port
        Adjacencies adjs = new AdjacenciesBuilder().setAdjacency(adjList).build();
        writeVpnInterfaceToDs(vpnId, infName, adjs, isRouterInterface, wrtConfigTxn);
        if (routerId != null) {
            addToNeutronRouterInterfacesMap(routerId, infName);
        }
    }

    protected void deleteVpnInterface(Uuid vpnId, Uuid routerId, Port port, WriteTransaction wrtConfigTxn) {
        Boolean wrtConfigTxnPresent = true;
        if (wrtConfigTxn == null) {
            wrtConfigTxnPresent = false;
            wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
        }
        String infName = port.getUuid().getValue();
        InstanceIdentifier<VpnInterface> vpnIfIdentifier = NeutronvpnUtils.buildVpnInterfaceIdentifier(infName);
        try {
            LOG.debug("Deleting vpn interface {}", infName);
            wrtConfigTxn.delete(LogicalDatastoreType.CONFIGURATION, vpnIfIdentifier);

            List<FixedIps> ips = port.getFixedIps();
            for (FixedIps ip : ips) {
                String ipValue = String.valueOf(ip.getIpAddress().getValue());
                NeutronvpnUtils.removeVpnPortFixedIpToPort(dataBroker, vpnId.getValue(), ipValue);
            }
        } catch (Exception ex) {
            LOG.error("Deletion of vpninterface {} failed due to {}", infName, ex);
        }
        if (routerId != null) {
            removeFromNeutronRouterInterfacesMap(routerId, infName);
        }
        if (!wrtConfigTxnPresent) {
            wrtConfigTxn.submit();
        }
    }

    protected void updateVpnInterface(Uuid vpnId, Uuid oldVpnId, Port port, boolean  isBeingAssociated, boolean isSubnetIp) {
        if (vpnId == null || port == null) {
            return;
        }
        boolean isLockAcquired = false;
        String infName = port.getUuid().getValue();
        InstanceIdentifier<VpnInterface> vpnIfIdentifier = NeutronvpnUtils.buildVpnInterfaceIdentifier(infName);
        try {
            isLockAcquired = NeutronvpnUtils.lock(infName);
            Optional<VpnInterface> optionalVpnInterface = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, vpnIfIdentifier);
            if (optionalVpnInterface.isPresent()) {
                VpnInterfaceBuilder vpnIfBuilder = new VpnInterfaceBuilder(optionalVpnInterface.get())
                        .setVpnInstanceName(vpnId.getValue());
                LOG.debug("Updating vpn interface {}", infName);
                if (!isBeingAssociated) {
                    Adjacencies adjs = vpnIfBuilder.getAugmentation(Adjacencies.class);
                    List<Adjacency> adjacencyList = (adjs != null) ? adjs.getAdjacency() : new ArrayList<Adjacency>();
                    Iterator<Adjacency> adjacencyIter = adjacencyList.iterator();
                    while (adjacencyIter.hasNext()) {
                        Adjacency adjacency = adjacencyIter.next();
                        String mipToQuery = adjacency.getIpAddress().split("/")[0];
                        InstanceIdentifier<VpnPortipToPort> id = NeutronvpnUtils.buildVpnPortipToPortIdentifier
                                (oldVpnId.getValue(), mipToQuery);
                        Optional<VpnPortipToPort> optionalVpnPort = NeutronvpnUtils.read(dataBroker,
                                LogicalDatastoreType
                                .OPERATIONAL, id);
                        if (!optionalVpnPort.isPresent() || optionalVpnPort.get().isLearnt()) {
                            LOG.trace("Removing adjacencies from vpninterface {} upon dissociation of router {} " +
                                    "from VPN " + "{}", infName, vpnId, oldVpnId);
                            adjacencyIter.remove();
                            NeutronvpnUtils.removeVpnPortFixedIpToPort(dataBroker, oldVpnId.getValue(), mipToQuery);
                            LOG.trace("Entry for fixedIP {} for port {} on VPN removed from " +
                                    "VpnPortFixedIPToPortData", mipToQuery, infName, vpnId.getValue());
                        }
                    }
                    Adjacencies adjacencies = new AdjacenciesBuilder().setAdjacency(adjacencyList).build();
                    vpnIfBuilder.addAugmentation(Adjacencies.class, adjacencies);
                }
                List<FixedIps> ips = port.getFixedIps();
                for (FixedIps ip : ips) {
                    String ipValue = String.valueOf(ip.getIpAddress().getValue());
                    if (oldVpnId != null) {
                        NeutronvpnUtils.removeVpnPortFixedIpToPort(dataBroker, oldVpnId.getValue(), ipValue);
                    }
                    NeutronvpnUtils.createVpnPortFixedIpToPort(dataBroker, vpnId.getValue(), ipValue, infName, port
                            .getMacAddress().getValue(), isSubnetIp, true, false);
                }
                MDSALUtil.syncUpdate(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIfIdentifier, vpnIfBuilder
                        .build());
            } else {
                LOG.error("VPN Interface {} not found", infName);
            }
        } catch (Exception ex) {
            LOG.error("Updation of vpninterface {} failed due to {}", infName, ex);
        } finally {
            if (isLockAcquired) {
                NeutronvpnUtils.unlock(infName);
            }
        }
    }

    public void createL3InternalVpn(Uuid vpn, String name, Uuid tenant, List<String> rd, List<String> irt,
                                    List<String> ert, Uuid router, List<Uuid> networks) {

        // Update VPN Instance node
        updateVpnInstanceNode(vpn.getValue(), rd, irt, ert, VpnInstance.Type.L3, 0 /*l3vni*/);

        // Update local vpn-subnet DS
        updateVpnMaps(vpn, name, router, tenant, networks);

        if (router != null) {
            Uuid existingVpn = NeutronvpnUtils.getVpnForRouter(dataBroker, router, true);
            if (existingVpn != null) {
                // use case when a cluster is rebooted and router add DCN is received, triggering #createL3InternalVpn

                // if before reboot, router was already associated to VPN, should not proceed associating router to
                // internal VPN. Adding to RouterInterfacesMap is also not needed since it's a config DS and will be
                // preserved upon reboot.
                // For a non-reboot case #associateRouterToInternalVPN already takes care of adding to
                // RouterInterfacesMap via #createVPNInterface call.
                LOG.info("Associating router to Internal VPN skipped for VPN {} due to router {} already associated " +
                        "to external VPN {}", vpn.getValue(), router.getValue(), existingVpn.getValue());
                return;
            }
            associateRouterToInternalVpn(vpn, router);
        }
    }

    /**
     * Performs the creation of a Neutron VPN, associating the new VPN to the
     * specified Neutron Networks and Routers
     *
     * @param vpn Uuid of the VPN tp be created
     * @param name Representative name of the new VPN
     * @param tenant Uuid of the Tenant under which the VPN is going to be created
     * @param rd Route-distinguisher for the VPN
     * @param irt A list of Import Route Targets
     * @param ert A list of Export Route Targets
     * @param router UUID of the neutron router the VPN may be associated to
     * @param networks UUID of the neutron network the VPN may be associated to
     * @throws Exception if association of L3VPN failed
     */
    public void createVpn(Uuid vpn, String name, Uuid tenant, List<String> rd, List<String> irt, List<String> ert,
                            Uuid router, List<Uuid> networks, VpnInstance.Type type, long l3vni) throws Exception {

        // Update VPN Instance node
        updateVpnInstanceNode(vpn.getValue(), rd, irt, ert, type, l3vni);

        // Please note that router and networks will be filled into VPNMaps
        // by subsequent calls here to associateRouterToVpn and
        // associateNetworksToVpn
        updateVpnMaps(vpn, name, null, tenant, null);

        if (router != null) {
            associateRouterToVpn(vpn, router);
        }
        if (networks != null) {
            List<String> failStrings = associateNetworksToVpn(vpn, networks);
            if (failStrings != null &&  !failStrings.isEmpty()) {
                LOG.error("VPN {} association to networks failed with error message {}. ",
                        vpn.getValue(), failStrings.get(0));
                throw new Exception(failStrings.get(0));
            }
        }
    }

    /**
     * It handles the invocations to the createVPN RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#createL3VPN
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNInput)
     */
    @Override
    public Future<RpcResult<CreateL3VPNOutput>> createL3VPN(CreateL3VPNInput input) {

        CreateL3VPNOutputBuilder opBuilder = new CreateL3VPNOutputBuilder();
        SettableFuture<RpcResult<CreateL3VPNOutput>> result = SettableFuture.create();
        List<RpcError> errorList = new ArrayList<>();
        int failurecount = 0;
        int warningcount = 0;

        List<L3vpn> vpns = input.getL3vpn();
        for (L3vpn vpn : vpns) {
            List<String> existingRDs = NeutronvpnUtils.getExistingRDs(dataBroker);
            RpcError error = null;
            String msg;
            if (vpn.getRouteDistinguisher() == null || vpn.getImportRT() == null || vpn.getExportRT() == null) {
                msg = String.format("Creation of L3VPN failed for VPN %s due to absence of RD/iRT/eRT input",
                        vpn.getId().getValue());
                LOG.warn(msg);
                error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                errorList.add(error);
                warningcount++;
                continue;
            }
            VpnInstance.Type vpnInstanceType = VpnInstance.Type.L3;
            long l3vni = 0;
            if (vpn.getL3vni() != null) {
                l3vni = vpn.getL3vni();
            }

            if (vpn.getRouteDistinguisher().size() > 1) {
                msg = String.format("Creation of VPN failed for VPN %s due to multiple RD input %s",
                        vpn.getId().getValue(), vpn.getRouteDistinguisher());
                LOG.warn(msg);
                error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                errorList.add(error);
                warningcount++;
                continue;
            }
            if (existingRDs.contains(vpn.getRouteDistinguisher().get(0))) {
                msg = String.format("Creation of L3VPN failed for VPN %s as another VPN with the same RD %s is already configured",
                        vpn.getId().getValue(), vpn.getRouteDistinguisher().get(0));
                LOG.warn(msg);
                error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                errorList.add(error);
                warningcount++;
                continue;
            }
            if (vpn.getRouterId() != null) {
                if (NeutronvpnUtils.getNeutronRouter(dataBroker, vpn.getRouterId()) == null) {
                    msg = String.format("Creation of L3VPN failed for VPN %s due to router not found %s",
                            vpn.getId().getValue(), vpn.getRouterId().getValue());
                    LOG.warn(msg);
                    error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                    errorList.add(error);
                    warningcount++;
                    continue;
                }
                Uuid vpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, vpn.getRouterId(), true);
                if (vpnId != null) {
                    msg = String.format("Creation of L3VPN failed for VPN %s due to router %s already associated to "
                                    + "another VPN %s", vpn.getId().getValue(), vpn.getRouterId().getValue(),
                            vpnId.getValue());
                    LOG.warn(msg);
                    error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                    errorList.add(error);
                    warningcount++;
                    continue;
                }
            }
            if (vpn.getNetworkIds() != null) {
                for (Uuid nw : vpn.getNetworkIds()) {
                    Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, nw);
                    Uuid vpnId = NeutronvpnUtils.getVpnForNetwork(dataBroker, nw);
                    if (network == null) {
                        msg = String.format("Creation of L3VPN failed for VPN %s due to network not found %s",
                                vpn.getId().getValue(), nw.getValue());
                        LOG.warn(msg);
                        error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                        errorList.add(error);
                        warningcount++;
                    } else if (vpnId != null) {
                        msg = String.format("Creation of L3VPN failed for VPN %s due to network %s already associated"
                                        + " to another VPN %s", vpn.getId().getValue(), nw.getValue(),
                                vpnId.getValue());
                        LOG.warn(msg);
                        error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-input", msg);
                        errorList.add(error);
                        warningcount++;
                    }
                }
                if (error != null) {
                    continue;
                }
            }
            try {
                createVpn(vpn.getId(), vpn.getName(), vpn.getTenantId(), vpn.getRouteDistinguisher(),
                        vpn.getImportRT(), vpn.getExportRT(), vpn.getRouterId(), vpn.getNetworkIds(),
                        vpnInstanceType, l3vni);
            } catch (Exception ex) {
                msg = String.format("Creation of VPN failed for VPN %s", vpn.getId().getValue());
                LOG.error(msg, ex);
                error = RpcResultBuilder.newError(ErrorType.APPLICATION, msg, ex.getMessage());
                errorList.add(error);
                failurecount++;
            }
        }
        // if at least one succeeds; result is success
        // if none succeeds; result is failure
        if (failurecount + warningcount == vpns.size()) {
            result.set(RpcResultBuilder.<CreateL3VPNOutput> failed().withRpcErrors(errorList).build());
        } else {
            List<String> errorResponseList = new ArrayList<>();
            if (!errorList.isEmpty()) {
                for (RpcError rpcError : errorList) {
                    String errorResponse = String.format("ErrorType: %s, ErrorTag: %s, ErrorMessage: %s", rpcError
                            .getErrorType(), rpcError.getTag(), rpcError.getMessage());
                    errorResponseList.add(errorResponse);
                }
            } else {
                errorResponseList.add("Operation successful with no errors");
            }
            opBuilder.setResponse(errorResponseList);
            result.set(RpcResultBuilder.<CreateL3VPNOutput> success().withResult(opBuilder.build()).build());
        }
        return result;
    }

    /**
     * It handles the invocations to the neutronvpn:getL3VPN RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#getL3VPN
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetL3VPNInput)
     */
    @Override
    public Future<RpcResult<GetL3VPNOutput>> getL3VPN(GetL3VPNInput input) {

        GetL3VPNOutputBuilder opBuilder = new GetL3VPNOutputBuilder();
        SettableFuture<RpcResult<GetL3VPNOutput>> result = SettableFuture.create();
        Uuid inputVpnId = input.getId();
        List<VpnInstance> vpns = new ArrayList<>();

        try {
            if (inputVpnId == null) {
                // get all vpns
                InstanceIdentifier<VpnInstances> vpnsIdentifier = InstanceIdentifier.builder(VpnInstances.class)
                        .build();
                Optional<VpnInstances> optionalVpns = NeutronvpnUtils.read(dataBroker,
                        LogicalDatastoreType.CONFIGURATION,
                        vpnsIdentifier);
                if (optionalVpns.isPresent() && optionalVpns.get().getVpnInstance() != null) {
                    for (VpnInstance vpn : optionalVpns.get().getVpnInstance()) {
                        // eliminating internal VPNs from getL3VPN output
                        if (vpn.getIpv4Family().getRouteDistinguisher() != null) {
                            vpns.add(vpn);
                        }
                    }
                } else {
                    // No VPN present
                    result.set(RpcResultBuilder.<GetL3VPNOutput>failed().withWarning(ErrorType.PROTOCOL, "", "No VPN " +
                            "is present").build());
                    return result;
                }
            } else {
                String name = inputVpnId.getValue();
                InstanceIdentifier<VpnInstance> vpnIdentifier = InstanceIdentifier.builder(VpnInstances.class)
                        .child(VpnInstance.class,
                                new VpnInstanceKey(name))
                        .build();
                // read VpnInstance Info
                Optional<VpnInstance> optionalVpn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                        vpnIdentifier);
                if (optionalVpn.isPresent()) {
                    vpns.add(optionalVpn.get());
                } else {
                    String message = String.format("GetL3VPN failed because VPN %s is not present", name);
                    LOG.error(message);
                    result.set(RpcResultBuilder.<GetL3VPNOutput>failed().withWarning(ErrorType.PROTOCOL,
                            "invalid-value", message).build());
                }
            }
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.getl3vpn.output.L3vpnInstances> l3vpnList = new ArrayList<>();
            for (VpnInstance vpnInstance : vpns) {
                Uuid vpnId = new Uuid(vpnInstance.getVpnInstanceName());
                // create VpnMaps id
                InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class).child(VpnMap
                        .class, new VpnMapKey(vpnId)).build();
                L3vpnInstancesBuilder l3vpn = new L3vpnInstancesBuilder();

                List<String> rd = Arrays.asList(vpnInstance.getIpv4Family().getRouteDistinguisher().split(","));
                List<VpnTarget> vpnTargetList = vpnInstance.getIpv4Family().getVpnTargets().getVpnTarget();

                List<String> ertList = new ArrayList<>();
                List<String> irtList = new ArrayList<>();

                for (VpnTarget vpnTarget : vpnTargetList) {
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.ExportExtcommunity) {
                        ertList.add(vpnTarget.getVrfRTValue());
                    }
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.ImportExtcommunity) {
                        irtList.add(vpnTarget.getVrfRTValue());
                    }
                    if (vpnTarget.getVrfRTType() == VpnTarget.VrfRTType.Both) {
                        ertList.add(vpnTarget.getVrfRTValue());
                        irtList.add(vpnTarget.getVrfRTValue());
                    }
                }

                l3vpn.setId(vpnId).setRouteDistinguisher(rd).setImportRT(irtList).setExportRT(ertList);
                Optional<VpnMap> optionalVpnMap = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                        vpnMapIdentifier);
                if (optionalVpnMap.isPresent()) {
                    VpnMap vpnMap = optionalVpnMap.get();
                    l3vpn.setRouterId(vpnMap.getRouterId()).setNetworkIds(vpnMap.getNetworkIds())
                            .setTenantId(vpnMap.getTenantId()).setName(vpnMap.getName());
                }
                l3vpnList.add(l3vpn.build());
            }

            opBuilder.setL3vpnInstances(l3vpnList);
            result.set(RpcResultBuilder.<GetL3VPNOutput> success().withResult(opBuilder.build()).build());

        } catch (Exception ex) {
            String message = String.format("GetVPN failed due to %s", ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<GetL3VPNOutput> failed().withError(ErrorType.APPLICATION, message).build());
        }
        return result;
    }

    /**
     * It handles the invocations to the neutronvpn:deleteL3VPN RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#deleteL3VPN
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNInput)
     */
    @Override
    public Future<RpcResult<DeleteL3VPNOutput>> deleteL3VPN(DeleteL3VPNInput input) {

        DeleteL3VPNOutputBuilder opBuilder = new DeleteL3VPNOutputBuilder();
        SettableFuture<RpcResult<DeleteL3VPNOutput>> result = SettableFuture.create();
        List<RpcError> errorList = new ArrayList<>();

        int failurecount = 0;
        int warningcount = 0;
        List<Uuid> vpns = input.getId();
        for (Uuid vpn : vpns) {
            RpcError error;
            String msg;
            try {
                InstanceIdentifier<VpnInstance> vpnIdentifier =
                        InstanceIdentifier.builder(VpnInstances.class).child(VpnInstance.class, new VpnInstanceKey
                                (vpn.getValue())).build();
                Optional<VpnInstance> optionalVpn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                        .CONFIGURATION, vpnIdentifier);
                if (optionalVpn.isPresent()) {
                    removeVpn(vpn);
                } else {
                    msg = String.format("VPN with vpnid: %s does not exist", vpn.getValue());
                    LOG.warn(msg);
                    error = RpcResultBuilder.newWarning(ErrorType.PROTOCOL, "invalid-value", msg);
                    errorList.add(error);
                    warningcount++;
                }
            } catch (Exception ex) {
                msg = String.format("Deletion of L3VPN failed when deleting for uuid %s", vpn.getValue());
                LOG.error(msg, ex);
                error = RpcResultBuilder.newError(ErrorType.APPLICATION, msg, ex.getMessage());
                errorList.add(error);
                failurecount++;
            }
        }
        // if at least one succeeds; result is success
        // if none succeeds; result is failure
        if (failurecount + warningcount == vpns.size()) {
            result.set(RpcResultBuilder.<DeleteL3VPNOutput> failed().withRpcErrors(errorList).build());
        } else {
            List<String> errorResponseList = new ArrayList<>();
            if (!errorList.isEmpty()) {
                for (RpcError rpcError : errorList) {
                    String errorResponse = String.format("ErrorType: %s, ErrorTag: %s, ErrorMessage: %s", rpcError
                            .getErrorType(), rpcError.getTag(), rpcError.getMessage());
                    errorResponseList.add(errorResponse);
                }
            } else {
                errorResponseList.add("Operation successful with no errors");
            }
            opBuilder.setResponse(errorResponseList);
            result.set(RpcResultBuilder.<DeleteL3VPNOutput> success().withResult(opBuilder.build()).build());
        }
        return result;
    }

    protected void addSubnetToVpn(final Uuid vpnId, Uuid subnet) {
        LOG.debug("Adding subnet {} to vpn {}", subnet.getValue(), vpnId.getValue());
        Subnetmap sn = updateSubnetNode(subnet, null, null, null, null, vpnId);
        final Uuid routerId = NeutronvpnUtils.getVpnMap(dataBroker, vpnId).getRouterId();
        // send subnet added to vpn notification
        isExternalVpn = vpnId.equals(routerId) ? false : true;
        String elanInstanceName = sn.getNetworkId().getValue();
        InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder(ElanInstances.class)
                .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
        try {
            Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, elanIdentifierId);
            if (elanInstance.isPresent()) {
                long elanTag = elanInstance.get().getElanTag();
                checkAndPublishSubnetAddNotification(subnet, sn.getSubnetIp(), vpnId.getValue(), isExternalVpn,
                        elanTag);
                LOG.debug("Subnet added to VPN notification sent for subnet {} on VPN {}", subnet.getValue(),
                        vpnId.getValue());
            } else {
                LOG.error("Subnet added to VPN notification failed for subnet {}  on VPN {} because of failure in " +
                        "reading ELANInstance {}", subnet.getValue(), vpnId.getValue(), elanInstanceName);
            }
        } catch (Exception e) {
            LOG.error("Subnet added to VPN notification failed for subnet {} on VPN {}", subnet.getValue(), vpnId
                    .getValue(), e);
        }
        // Check if there are ports on this subnet and add corresponding
        // vpn-interfaces
        List<Uuid> portList = sn.getPortList();
        if (portList != null) {
            for (final Uuid portId : sn.getPortList()) {
                LOG.debug("adding vpn-interface for port {}", portId.getValue());
                final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                portDataStoreCoordinator.enqueueJob("PORT-" + portId.getValue(), new
                        Callable<List<ListenableFuture<Void>>>() {
                    @Override
                    public List<ListenableFuture<Void>> call() throws Exception {
                        WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                        List<ListenableFuture<Void>> futures = new ArrayList<>();
                        createVpnInterface(vpnId, routerId, NeutronvpnUtils.getNeutronPort(dataBroker, portId),
                                wrtConfigTxn);
                        futures.add(wrtConfigTxn.submit());
                        return futures;
                    }
                });
            }
        }
    }

    protected void updateVpnForSubnet(Uuid vpnId, Uuid subnet, boolean isBeingAssociated) {
        LOG.debug("Updating VPN {} for subnet {}", vpnId.getValue(), subnet.getValue());
        // Read the subnet first to see if its already associated to a VPN
        Uuid oldVpnId = null;
        InstanceIdentifier<Subnetmap> snId = InstanceIdentifier.builder(Subnetmaps.class).
                child(Subnetmap.class, new SubnetmapKey(subnet)).build();
        Subnetmap sn = null;
        Optional<Subnetmap> optSn = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, snId);
        if (optSn.isPresent()) {
            sn = optSn.get();
            oldVpnId = sn.getVpnId();
            List<String> ips = sn.getRouterInterfaceFixedIps();
            for (String ipValue : ips) {
                // Update the association of router-interface to external vpn
                String PortName = NeutronvpnUtils.getNeutronPortNameFromVpnPortFixedIp(dataBroker, oldVpnId.getValue(), ipValue);
                updateVpnInterface(vpnId, oldVpnId, NeutronvpnUtils.getNeutronPort(dataBroker, new Uuid(PortName)),
                        isBeingAssociated, true);
            }
        }
        sn = updateSubnetNode(subnet, null, null, null, null, vpnId);
        // send vpn updated for subnet notification
        String elanInstanceName = sn.getNetworkId().getValue();
        InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder(ElanInstances.class)
                .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
        try {
            Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, elanIdentifierId);
            if (elanInstance.isPresent()) {
                long elanTag = elanInstance.get().getElanTag();
                checkAndPublishSubnetUpdNotification(subnet, sn.getSubnetIp(), vpnId.getValue(), isBeingAssociated,
                        elanTag);
                LOG.debug("VPN updated for subnet notification sent for subnet {} on VPN {}", subnet.getValue(),
                        vpnId.getValue());
            } else {
                LOG.error("VPN updated for subnet notification failed for subnet {} on VPN {} because of failure " +
                        "in reading ELANInstance {}", subnet.getValue(), vpnId.getValue(), elanInstanceName);
            }
        } catch (Exception e) {
            LOG.error("VPN updated for subnet notification failed for subnet {} on VPN {}", subnet.getValue(),
                    vpnId.getValue(), e);
        }
        // Check for ports on this subnet and update association of
        // corresponding vpn-interfaces to external vpn
        List<Uuid> portList = sn.getPortList();
        if (portList != null) {
            for (Uuid port : sn.getPortList()) {
                LOG.debug("Updating vpn-interface for port {} isBeingAssociated {}", port.getValue(), isBeingAssociated);
                updateVpnInterface(vpnId, oldVpnId, NeutronvpnUtils.getNeutronPort(dataBroker, port),
                        isBeingAssociated, false);
            }
        }
    }

    public InstanceIdentifier<RouterInterfaces> getRouterInterfacesId(Uuid routerId) {
        return InstanceIdentifier.builder(RouterInterfacesMap.class)
                .child(RouterInterfaces.class, new RouterInterfacesKey(routerId)).build();
    }

    protected void addToNeutronRouterInterfacesMap(Uuid routerId, String interfaceName) {
        synchronized (routerId.getValue().intern()) {
            InstanceIdentifier<RouterInterfaces> routerInterfacesId = getRouterInterfacesId(routerId);
            Optional<RouterInterfaces> optRouterInterfaces = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, routerInterfacesId);
            Interfaces routerInterface = new InterfacesBuilder().setKey(new InterfacesKey(interfaceName)).setInterfaceId
                    (interfaceName).build();
            if (optRouterInterfaces.isPresent()) {
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, routerInterfacesId.child(Interfaces
                        .class, new InterfacesKey(interfaceName)), routerInterface);
            } else {
                RouterInterfacesBuilder builder = new RouterInterfacesBuilder().setRouterId(routerId);
                List<Interfaces> interfaces = new ArrayList<>();
                interfaces.add(routerInterface);
                MDSALUtil.syncUpdate(dataBroker, LogicalDatastoreType.CONFIGURATION, routerInterfacesId.child(Interfaces
                        .class, new InterfacesKey(interfaceName)), routerInterface);
            }
        }
    }

    protected void removeFromNeutronRouterInterfacesMap(Uuid routerId, String interfaceName) {
        synchronized (routerId.getValue().intern()) {
            InstanceIdentifier<RouterInterfaces> routerInterfacesId = getRouterInterfacesId(routerId);
            Optional<RouterInterfaces> optRouterInterfaces = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, routerInterfacesId);
            Interfaces routerInterface = new InterfacesBuilder().setKey(new InterfacesKey(interfaceName)).setInterfaceId
                    (interfaceName).build();
            if (optRouterInterfaces.isPresent()) {
                RouterInterfaces routerInterfaces = optRouterInterfaces.get();
                List<Interfaces> interfaces = routerInterfaces.getInterfaces();
                if (interfaces != null && interfaces.remove(routerInterface)) {
                    if (interfaces.isEmpty()) {
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, routerInterfacesId);
                    } else {
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION,
                                routerInterfacesId.child(Interfaces.class, new InterfacesKey(interfaceName)));
                    }
                }
            }
        }
    }

    /**
     * Creates the corresponding static routes in the specified VPN. These static routes must be point to an
     * InterVpnLink endpoint and the specified VPN must be the other end of the InterVpnLink. Otherwise the
     * route will be ignored.
     *
     * @param vpnName the VPN identifier
     * @param interVpnLinkRoutes The list of static routes
     * @param nexthopsXinterVpnLinks A Map with the correspondence nextHop-InterVpnLink
     */
    public void addInterVpnRoutes(Uuid vpnName, List<Routes> interVpnLinkRoutes,
                                  HashMap<String, InterVpnLink> nexthopsXinterVpnLinks) {
        for ( Routes route : interVpnLinkRoutes ) {
            String nexthop = String.valueOf(route.getNexthop().getValue());
            String destination = String.valueOf(route.getDestination().getValue());
            InterVpnLink interVpnLink = nexthopsXinterVpnLinks.get(nexthop);
            if ( isNexthopTheOtherVpnLinkEndpoint(nexthop, vpnName.getValue(), interVpnLink) ) {
                AddStaticRouteInput rpcInput =
                        new AddStaticRouteInputBuilder().setDestination(destination).setNexthop(nexthop)
                                .setVpnInstanceName(vpnName.getValue())
                                .build();
                Future<RpcResult<AddStaticRouteOutput>> labelOuputFtr = vpnRpcService.addStaticRoute(rpcInput);
                RpcResult<AddStaticRouteOutput> rpcResult;
                try {
                    rpcResult = labelOuputFtr.get();
                    if ( rpcResult.isSuccessful() ) {
                        LOG.debug("Label generated for destination {} is: {}",
                                destination, rpcResult.getResult().getLabel());
                    } else {
                        LOG.warn("RPC call to add a static Route to {} with nexthop {} returned with errors {}",
                                destination, nexthop, rpcResult.getErrors());
                    }
                } catch (InterruptedException | ExecutionException e) {
                    LOG.warn("Error happened while invoking addStaticRoute RPC: ", e);
                }
            } else {
                // Any other case is a fault.
                LOG.warn("route with destination {} and nexthop {} does not apply to any InterVpnLink",
                        String.valueOf(route.getDestination().getValue()), nexthop );
                continue;
            }
        }
    }

    /**
     * Removes the corresponding static routes from the specified VPN. These static routes point to an
     * InterVpnLink endpoint and the specified VPN must be the other end of the InterVpnLink.
     *
     * @param vpnName the VPN identifier
     * @param interVpnLinkRoutes The list of static routes
     * @param nexthopsXinterVpnLinks A Map with the correspondence nextHop-InterVpnLink
     */
    public void removeInterVpnRoutes(Uuid vpnName, List<Routes> interVpnLinkRoutes,
                                     HashMap<String, InterVpnLink> nexthopsXinterVpnLinks) {
        for ( Routes route : interVpnLinkRoutes ) {
            String nexthop = String.valueOf(route.getNexthop().getValue());
            String destination = String.valueOf(route.getDestination().getValue());
            InterVpnLink interVpnLink = nexthopsXinterVpnLinks.get(nexthop);
            if ( isNexthopTheOtherVpnLinkEndpoint(nexthop, vpnName.getValue(), interVpnLink) ) {
                RemoveStaticRouteInput rpcInput =
                        new RemoveStaticRouteInputBuilder().setDestination(destination).setNexthop(nexthop)
                                .setVpnInstanceName(vpnName.getValue())
                                .build();
                vpnRpcService.removeStaticRoute(rpcInput);
            } else {
                // Any other case is a fault.
                LOG.warn("route with destination {} and nexthop {} does not apply to any InterVpnLink",
                        String.valueOf(route.getDestination().getValue()), nexthop );
                continue;
            }
        }
    }

    /*
     * Returns true if the specified nexthop is the other endpoint in an
     * InterVpnLink, regarding one of the VPN's point of view.
     */
    private boolean isNexthopTheOtherVpnLinkEndpoint(String nexthop, String thisVpnUuid, InterVpnLink interVpnLink) {
        return
                interVpnLink != null
                        && (   (interVpnLink.getFirstEndpoint().getVpnUuid().getValue().equals(thisVpnUuid)
                        && interVpnLink.getSecondEndpoint().getIpAddress().getValue().equals(nexthop))
                        || (interVpnLink.getSecondEndpoint().getVpnUuid().getValue().equals(thisVpnUuid )
                        && interVpnLink.getFirstEndpoint().getIpAddress().getValue().equals(nexthop)) );
    }

    protected List<Adjacency> getAdjacencyforExtraRoute(Uuid vpnId, List<Routes> routeList, String fixedIp) {
        List<Adjacency> adjList = new ArrayList<>();
        Map<String, List<String>> adjMap = new HashMap<>();
        for (Routes route : routeList) {
            if (route == null || route.getNexthop() == null || route.getDestination() == null) {
                LOG.error("Incorrect input received for extra route. {}", route);
            } else {
                String nextHop = String.valueOf(route.getNexthop().getValue());
                String destination = String.valueOf(route.getDestination().getValue());
                if (!nextHop.equals(fixedIp)) {
                    LOG.trace("FixedIP {} is not extra route nexthop for destination {}", fixedIp, destination);
                    continue;
                }
                LOG.trace("Adding extra route for destination {} onto vpn {} with nexthop {} ", destination,
                        vpnId.getValue(), nextHop);
                List<String> hops = adjMap.get(destination);
                if (hops == null) {
                    hops = new ArrayList<>();
                    adjMap.put(destination, hops);
                }
                if (!hops.contains(nextHop)) {
                    hops.add(nextHop);
                }
            }
        }

        for (String destination : adjMap.keySet()) {
            Adjacency erAdj = new AdjacencyBuilder().setIpAddress(destination).setNextHopIpList(adjMap.get
                    (destination)).setKey(new AdjacencyKey(destination)).build();
            adjList.add(erAdj);
        }
        return  adjList;
    }

    protected void updateVpnInterfaceWithExtraRouteAdjacency(Uuid vpnId, List<Routes> routeList) {
        for (Routes route : routeList) {
            if (route == null || route.getNexthop() == null || route.getDestination() == null) {
                LOG.error("Incorrect input received for extra route. {}", route);
            } else {
                String nextHop = String.valueOf(route.getNexthop().getValue());
                String destination = String.valueOf(route.getDestination().getValue());
                String infName = NeutronvpnUtils.getNeutronPortNameFromVpnPortFixedIp(dataBroker, vpnId.getValue(),
                        nextHop);
                if (infName != null) {
                    LOG.trace("Updating extra route for destination {} onto vpn {} with nexthop {} and infName {}", destination,
                            vpnId.getValue(), nextHop, infName);
                    boolean isLockAcquired = false;
                    try {
                        InstanceIdentifier<VpnInterface> identifier = InstanceIdentifier.builder(VpnInterfaces.class)
                                .child(VpnInterface.class, new VpnInterfaceKey(infName)).build();
                        InstanceIdentifier<Adjacency> path = identifier.augmentation(Adjacencies.class).
                                child(Adjacency.class, new AdjacencyKey(destination));
                        Adjacency erAdj = new AdjacencyBuilder().setIpAddress(destination).setNextHopIpList(Arrays.asList(nextHop)).
                                setKey(new AdjacencyKey(destination)).build();
                        isLockAcquired = NeutronvpnUtils.lock(infName);
                        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, path, erAdj);
                    } catch (Exception e) {
                        LOG.error("exception in adding extra route with destination: {}, next hop: {}", destination, nextHop, e);
                    } finally {
                        if (isLockAcquired) {
                            NeutronvpnUtils.unlock(infName);
                        }
                    }
                } else {
                    LOG.debug("Unable to find VPN NextHop interface to apply extra-route destination {} on VPN {} " +
                            "with nexthop {}", destination, vpnId.getValue(), nextHop);
                }
            }
        }
    }

    protected void removeAdjacencyforExtraRoute(Uuid vpnId, List<Routes> routeList) {
        for (Routes route : routeList) {
            if (route != null && route.getNexthop() != null && route.getDestination() != null) {
                boolean isLockAcquired = false;
                String nextHop = String.valueOf(route.getNexthop().getValue());
                String destination = String.valueOf(route.getDestination().getValue());
                String infName = NeutronvpnUtils.getNeutronPortNameFromVpnPortFixedIp(dataBroker, vpnId.getValue(),
                        nextHop);
                if (infName == null) {
                    LOG.error("Unable to find VPN NextHop interface to remove extra-route destination {} on VPN {} " +
                                    "with nexthop {}",
                            destination, vpnId.getValue(), nextHop);
                    // Proceed to remove the next extra-route
                    continue;
                }
                LOG.trace("Removing extra route for destination {} on vpn {} with nexthop {} and infName {}",
                        destination, vpnId.getValue(), nextHop, infName);

                InstanceIdentifier<Adjacency> adjacencyIdentifier =
                        InstanceIdentifier.builder(VpnInterfaces.class)
                                .child(VpnInterface.class, new VpnInterfaceKey(infName))
                                .augmentation(Adjacencies.class)
                                .child(Adjacency.class, new AdjacencyKey(destination))
                                .build();

                // Looking for existing prefix in MDSAL database
                Optional<Adjacency> adjacency = MDSALUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                        adjacencyIdentifier);
                boolean updateNextHops = false;
                List<String> nextHopList = new ArrayList<>();
                if (adjacency.isPresent()) {
                    List<String> nhListRead = adjacency.get().getNextHopIpList();
                    if (nhListRead.size() > 1) { // ECMP case
                        for (String nextHopRead : nhListRead) {
                            if (nextHopRead.equals(nextHop)) {
                                updateNextHops = true;
                            } else {
                                nextHopList.add(nextHopRead);
                            }
                        }
                    }
                }

                try {
                    isLockAcquired = NeutronvpnUtils.lock(infName);
                    if (updateNextHops) {
                        // An update must be done, not including the current next hop
                        InstanceIdentifier<VpnInterface> vpnIfIdentifier = InstanceIdentifier.builder(
                                VpnInterfaces.class).child(VpnInterface.class, new VpnInterfaceKey(infName)).build();
                        Adjacency newAdj = new AdjacencyBuilder(adjacency.get()).setIpAddress(destination)
                                .setNextHopIpList(nextHopList)
                                .setKey(new AdjacencyKey(destination))
                                .build();
                        Adjacencies erAdjs = new AdjacenciesBuilder().setAdjacency(Arrays.asList(newAdj)).build();
                        VpnInterface vpnIf = new VpnInterfaceBuilder().setKey(new VpnInterfaceKey(infName))
                                .addAugmentation(Adjacencies.class, erAdjs).build();
                        MDSALUtil.syncUpdate(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIfIdentifier, vpnIf);
                    } else {
                        // Remove the whole route
                        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, adjacencyIdentifier);
                        LOG.trace("extra route {} deleted successfully", route);
                    }
                } catch (Exception e) {
                    LOG.error("exception in deleting extra route: {}" + e);
                } finally {
                    if (isLockAcquired) {
                        NeutronvpnUtils.unlock(infName);
                    }
                }
            } else {
                LOG.error("Incorrect input received for extra route. {}", route);
            }
        }
    }

    protected void removeVpn(Uuid id) {
        // read VPNMaps
        VpnMap vpnMap = NeutronvpnUtils.getVpnMap(dataBroker, id);
        Uuid router = vpnMap.getRouterId();
        // dissociate router
        if (router != null) {
            dissociateRouterFromVpn(id, router);
        }
        // dissociate networks
        if (!id.equals(router)) {
            dissociateNetworksFromVpn(id, vpnMap.getNetworkIds());
        }
        // remove entire vpnMaps node
        deleteVpnMapsNode(id);

        // remove vpn-instance
        deleteVpnInstance(id);
    }

    protected void removeSubnetFromVpn(final Uuid vpnId, Uuid subnet) {
        LOG.debug("Removing subnet {} from vpn {}", subnet.getValue(), vpnId.getValue());
        final Uuid routerId = NeutronvpnUtils.getVpnMap(dataBroker, vpnId).getRouterId();
        Subnetmap sn = NeutronvpnUtils.getSubnetmap(dataBroker, subnet);
        // send subnet removed from vpn notification
        isExternalVpn = vpnId.equals(routerId) ? false : true;
        String elanInstanceName = sn.getNetworkId().getValue();
        InstanceIdentifier<ElanInstance> elanIdentifierId = InstanceIdentifier.builder(ElanInstances.class)
                .child(ElanInstance.class, new ElanInstanceKey(elanInstanceName)).build();
        try {
            Optional<ElanInstance> elanInstance = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType
                    .CONFIGURATION, elanIdentifierId);
            if (elanInstance.isPresent()) {
                long elanTag = elanInstance.get().getElanTag();
                checkAndPublishSubnetDelNotification(subnet, sn.getSubnetIp(), vpnId.getValue(), isExternalVpn,
                        elanTag);
                LOG.debug("Subnet removed from VPN notification sent for subnet {} on VPN {}", subnet.getValue(),
                        vpnId.getValue());
            } else {
                LOG.error("Subnet removed from VPN notification failed for subnet {} on VPN {} because of failure " +
                        "in reading ELANInstance {}", subnet.getValue(), vpnId.getValue(), elanInstanceName);
            }
        } catch (Exception e) {
            LOG.error("Subnet removed from VPN notification failed for subnet {} on VPN {}", subnet.getValue(),
                    vpnId.getValue(), e);
        }
        if (sn != null) {
            // Check if there are ports on this subnet; remove corresponding vpn-interfaces
            List<Uuid> portList = sn.getPortList();
            if (portList != null) {
                for (final Uuid portId : sn.getPortList()) {
                    LOG.debug("removing vpn-interface for port {}", portId.getValue());
                    final DataStoreJobCoordinator portDataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                    portDataStoreCoordinator.enqueueJob("PORT-" + portId.getValue(), () -> {
                        WriteTransaction wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
                        List<ListenableFuture<Void>> futures = new ArrayList<>();
                        deleteVpnInterface(vpnId, routerId, NeutronvpnUtils.getNeutronPort(dataBroker, portId),
                                wrtConfigTxn);
                        futures.add(wrtConfigTxn.submit());
                        return futures;
                    });
                }
            }
            // update subnet-vpn association
            removeFromSubnetNode(subnet, null, null, vpnId, null);
        } else {
            LOG.warn("Subnetmap for subnet {} not found", subnet.getValue());
        }
    }

    protected void associateRouterToVpn(Uuid vpnId, Uuid routerId) {
        updateVpnMaps(vpnId, null, routerId, null, null);
        LOG.debug("Updating association of subnets to external vpn {}", vpnId.getValue());
        List<Uuid> routerSubnets = NeutronvpnUtils.getNeutronRouterSubnetIds(dataBroker, routerId);
        if (routerSubnets != null) {
            for (Uuid subnetId : routerSubnets) {
                updateVpnForSubnet(vpnId, subnetId, true);
            }
        }
        try {
            checkAndPublishRouterAssociatedtoVpnNotification(routerId, vpnId);
            LOG.debug("notification upon association of router {} to VPN {} published", routerId.getValue(),
                    vpnId.getValue());
        } catch (Exception e) {
            LOG.error("publishing of notification upon association of router {} to VPN {} failed : ", routerId
                    .getValue(), vpnId.getValue(), e);
        }
    }

    protected void associateRouterToInternalVpn(Uuid vpnId, Uuid routerId) {
        List<Uuid> routerSubnets = NeutronvpnUtils.getNeutronRouterSubnetIds(dataBroker, routerId);
        LOG.debug("Adding subnets to internal vpn {}", vpnId.getValue());
        for (Uuid subnet : routerSubnets) {
            addSubnetToVpn(vpnId, subnet);
        }
    }

    protected void dissociateRouterFromVpn(Uuid vpnId, Uuid routerId) {

        List<Uuid> routerSubnets = NeutronvpnUtils.getNeutronRouterSubnetIds(dataBroker, routerId);
        if (routerSubnets != null) {
            for (Uuid subnetId : routerSubnets) {
                LOG.debug("Updating association of subnets to internal vpn {}", routerId.getValue());
                updateVpnForSubnet(routerId, subnetId, false);
            }
        }
        clearFromVpnMaps(vpnId, routerId, null);
        try {
            checkAndPublishRouterDisassociatedFromVpnNotification(routerId, vpnId);
            LOG.debug("notification upon disassociation of router {} from VPN {} published", routerId.getValue(),
                    vpnId.getValue());
        } catch (Exception e) {
            LOG.error("publishing of notification upon disassociation of router {} from VPN {} failed : ", routerId
                    .getValue(), vpnId.getValue(), e);
        }
    }

    protected List<String> associateNetworksToVpn(Uuid vpn, List<Uuid> networks) {
        List<String> failedNwList = new ArrayList<>();
        List<Uuid> passedNwList = new ArrayList<>();
        if (!networks.isEmpty()) {
            // process corresponding subnets for VPN
            for (Uuid nw : networks) {
                Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, nw);
                NetworkProviderExtension providerExtension = network.getAugmentation(NetworkProviderExtension.class);
                if (providerExtension.getSegments() != null && providerExtension.getSegments().size() > 1) {
                    LOG.error("MultiSegmented networks not supported in VPN. Failed to associate network {} on vpn {}",
                            nw.getValue(), vpn.getValue());
                    failedNwList.add(String.format("Failed to associate network %s on vpn %s as it is multisegmented.", nw.getValue(), vpn.getValue()));
                    continue;
                }
                Uuid vpnId = NeutronvpnUtils.getVpnForNetwork(dataBroker, nw);
                if (network == null) {
                    failedNwList.add(String.format("network %s not found", nw.getValue()));
                } else if (vpnId != null) {
                    failedNwList.add(String.format("network %s already associated to another VPN %s", nw.getValue(),
                            vpnId.getValue()));
                } else {
                    List<Uuid> networkSubnets = NeutronvpnUtils.getSubnetIdsFromNetworkId(dataBroker, nw);
                    LOG.debug("Adding network subnets...{}", networkSubnets);
                    if (networkSubnets != null) {
                        for (Uuid subnet : networkSubnets) {
                            // check if subnet added as router interface to some router
                            Uuid subnetVpnId = NeutronvpnUtils.getVpnForSubnet(dataBroker, subnet);
                            if (subnetVpnId == null) {
                                addSubnetToVpn(vpn, subnet);
                                passedNwList.add(nw);
                            } else {
                                failedNwList.add(String.format("subnet %s already added as router interface bound to " +
                                        "internal/external VPN %s", subnet.getValue (), subnetVpnId.getValue()));
                            }
                        }
                    }
                    if (NeutronvpnUtils.getIsExternal(network)) {
                        nvpnNatManager.addExternalNetworkToVpn(network, vpn);
                    }
                }
            }
            updateVpnMaps(vpn, null, null, null, passedNwList);
        }
        return failedNwList;
    }

    protected List<String> dissociateNetworksFromVpn(Uuid vpn, List<Uuid> networks) {
        List<String> failedNwList = new ArrayList<>();
        List<Uuid> passedNwList = new ArrayList<>();
        if (networks != null && !networks.isEmpty()) {
            // process corresponding subnets for VPN
            for (Uuid nw : networks) {
                Network network = NeutronvpnUtils.getNeutronNetwork(dataBroker, nw);
                if (network == null) {
                    failedNwList.add(String.format("network %s not found", nw.getValue()));
                } else {
                    Uuid vpnId = NeutronvpnUtils.getVpnForNetwork(dataBroker, nw);
                    if (vpn.equals(vpnId)) {
                        List<Uuid> networkSubnets = NeutronvpnUtils.getSubnetIdsFromNetworkId(dataBroker, nw);
                        LOG.debug("Removing network subnets...");
                        if (networkSubnets != null) {
                            for (Uuid subnet : networkSubnets) {
                                removeSubnetFromVpn(vpn, subnet);
                                passedNwList.add(nw);
                            }
                        }
                    } else {
                        if (vpnId == null) {
                            failedNwList.add(String.format("input network %s not associated to any vpn yet", nw
                                    .getValue()));
                        } else {
                            failedNwList.add(String.format("input network %s associated to a another vpn %s instead " +
                                    "of the one given as input", nw.getValue(), vpnId.getValue()));
                        }
                    }
                    if (NeutronvpnUtils.getIsExternal(network)) {
                        nvpnNatManager.removeExternalNetworkFromVpn(network);
                    }
                }
            }
            clearFromVpnMaps(vpn, null, passedNwList);
        }
        return failedNwList;
    }

    /**
     * It handles the invocations to the neutronvpn:associateNetworks RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#associateNetworks
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateNetworksInput)
     */
    @Override
    public Future<RpcResult<AssociateNetworksOutput>> associateNetworks(AssociateNetworksInput input) {

        AssociateNetworksOutputBuilder opBuilder = new AssociateNetworksOutputBuilder();
        SettableFuture<RpcResult<AssociateNetworksOutput>> result = SettableFuture.create();
        LOG.debug("associateNetworks {}", input);
        StringBuilder returnMsg = new StringBuilder();
        Uuid vpnId = input.getVpnId();

        try {
            if (NeutronvpnUtils.getVpnMap(dataBroker, vpnId) != null) {
                List<Uuid> netIds = input.getNetworkId();
                if (netIds != null && !netIds.isEmpty()) {
                    List<String> failed = associateNetworksToVpn(vpnId, netIds);
                    if (!failed.isEmpty()) {
                        returnMsg.append(failed);
                    }
                }
            } else {
                returnMsg.append("VPN not found : ").append(vpnId.getValue());
            }
            if (returnMsg.length() != 0) {
                String message = String.format("associate Networks to vpn %s failed due to %s",
                        vpnId.getValue(), returnMsg);
                LOG.error(message);
                String errorResponse = String.format("ErrorType: PROTOCOL, ErrorTag: invalid-value, ErrorMessage: %s",
                        message);
                opBuilder.setResponse(errorResponse);
                result.set(RpcResultBuilder.<AssociateNetworksOutput> success().withResult(opBuilder.build()).build());
            } else {
                result.set(RpcResultBuilder.<AssociateNetworksOutput> success().build());
            }
        } catch (Exception ex) {
            String message = String.format("associate Networks to vpn %s failed due to %s",
                    input.getVpnId().getValue(), ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<AssociateNetworksOutput> failed().withError(ErrorType.APPLICATION, message)
                    .build());
        }
        LOG.debug("associateNetworks returns..");
        return result;
    }

    /**
     * It handles the invocations to the neutronvpn:associateRouter RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#associateRouter
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.AssociateRouterInput)
     */
    @Override
    public Future<RpcResult<Void>> associateRouter(AssociateRouterInput input) {

        SettableFuture<RpcResult<Void>> result = SettableFuture.create();
        LOG.debug("associateRouter {}", input);
        StringBuilder returnMsg = new StringBuilder();
        Uuid vpnId = input.getVpnId();
        Uuid routerId = input.getRouterId();
        try {
            VpnMap vpnMap = NeutronvpnUtils.getVpnMap(dataBroker, vpnId);
            Router rtr = NeutronvpnUtils.getNeutronRouter(dataBroker, routerId);
            if (vpnMap != null) {
                if (rtr != null) {
                    Uuid extVpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerId, true);
                    if (vpnMap.getRouterId() != null) {
                        returnMsg.append("vpn ").append(vpnId.getValue()).append(" already associated to router ")
                                .append(vpnMap.getRouterId().getValue());
                    } else if (extVpnId != null) {
                        returnMsg.append("router ").append(routerId.getValue()).append(" already associated to " +
                                "another VPN ").append(extVpnId.getValue());
                    } else {
                        associateRouterToVpn(vpnId, routerId);
                    }
                } else {
                    returnMsg.append("router not found : ").append(routerId.getValue());
                }
            } else {
                returnMsg.append("VPN not found : ").append(vpnId.getValue());
            }
            if (returnMsg.length() != 0) {
                String message = String.format("associate router to vpn %s failed due to %s", routerId.getValue(),
                        returnMsg);
                LOG.error(message);
                result.set(RpcResultBuilder.<Void> failed().withWarning(ErrorType.PROTOCOL, "invalid-value", message)
                        .build());
            } else {
                result.set(RpcResultBuilder.<Void> success().build());
            }
        } catch (Exception ex) {
            String message = String.format("associate router %s to vpn %s failed due to %s", routerId.getValue(),
                    vpnId.getValue(), ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<Void> failed().withError(ErrorType.APPLICATION, message).build());
        }
        LOG.debug("associateRouter returns..");
        return result;
    }

    /** It handles the invocations to the neutronvpn:getFixedIPsForNeutronPort RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService#getFixedIPsForNeutronPort
     * (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.GetFixedIPsForNeutronPortInput)
     */
    @Override
    public Future<RpcResult<GetFixedIPsForNeutronPortOutput>> getFixedIPsForNeutronPort(GetFixedIPsForNeutronPortInput input) {
        GetFixedIPsForNeutronPortOutputBuilder opBuilder = new GetFixedIPsForNeutronPortOutputBuilder();
        SettableFuture<RpcResult<GetFixedIPsForNeutronPortOutput>> result = SettableFuture.create();
        Uuid portId = input.getPortId();
        StringBuilder returnMsg = new StringBuilder();
        try {
            List<String> fixedIPList = new ArrayList<>();
            Port port = NeutronvpnUtils.getNeutronPort(dataBroker, portId);
            if (port != null) {
                List<FixedIps> fixedIPs = port.getFixedIps();
                for (FixedIps ip : fixedIPs) {
                    fixedIPList.add(String.valueOf(ip.getIpAddress().getValue()));
                }
            } else {
                returnMsg.append("neutron port: ").append(portId.getValue()).append(" not found");
            }
            if (returnMsg.length() != 0) {
                String message = String.format("Retrieval of FixedIPList for neutron port failed due to %s", returnMsg);
                LOG.error(message);
                result.set(RpcResultBuilder.<GetFixedIPsForNeutronPortOutput> failed()
                        .withWarning(ErrorType.PROTOCOL, "invalid-value", message).build());
            } else {
                opBuilder.setFixedIPs(fixedIPList);
                result.set(RpcResultBuilder.<GetFixedIPsForNeutronPortOutput> success().withResult(opBuilder.build())
                        .build());
                result.set(RpcResultBuilder.<GetFixedIPsForNeutronPortOutput> success().build());
            }
        } catch (Exception ex) {
            String message = String.format("Retrieval of FixedIPList for neutron port %s failed due to %s",
                    portId.getValue(), ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<GetFixedIPsForNeutronPortOutput> failed()
                    .withError(ErrorType.APPLICATION, message).build());
        }
        return result;
    }

    /**
     * It handles the invocations to the neutronvpn:dissociateNetworks RPC method
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn
     * .rev150602.NeutronvpnService#dissociateNetworks(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt
     * .neutronvpn.rev150602.DissociateNetworksInput)
     */
    @Override
    public Future<RpcResult<DissociateNetworksOutput>> dissociateNetworks(DissociateNetworksInput input) {

        DissociateNetworksOutputBuilder opBuilder = new DissociateNetworksOutputBuilder();
        SettableFuture<RpcResult<DissociateNetworksOutput>> result = SettableFuture.create();

        LOG.debug("dissociateNetworks {}", input);
        StringBuilder returnMsg = new StringBuilder();
        Uuid vpnId = input.getVpnId();

        try {
            if (NeutronvpnUtils.getVpnMap(dataBroker, vpnId) != null) {
                List<Uuid> netIds = input.getNetworkId();
                if (netIds != null && !netIds.isEmpty()) {
                    List<String> failed = dissociateNetworksFromVpn(vpnId, netIds);
                    if (!failed.isEmpty()) {
                        returnMsg.append(failed);
                    }
                }
            } else {
                returnMsg.append("VPN not found : ").append(vpnId.getValue());
            }
            if (returnMsg.length() != 0) {
                String message = String.format("dissociate Networks to vpn %s failed due to %s", vpnId.getValue(),
                        returnMsg);
                LOG.error(message);
                String errorResponse = String.format("ErrorType: PROTOCOL, ErrorTag: invalid-value, ErrorMessage: "
                        + message);
                opBuilder.setResponse(errorResponse);
                result.set(RpcResultBuilder.<DissociateNetworksOutput> success().withResult(opBuilder.build()).build());
            } else {
                result.set(RpcResultBuilder.<DissociateNetworksOutput> success().build());
            }
        } catch (Exception ex) {
            String message = String.format("dissociate Networks to vpn %s failed due to %s",
                    input.getVpnId().getValue(), ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<DissociateNetworksOutput> failed().withError(ErrorType.APPLICATION, message)
                    .build());
        }
        LOG.debug("dissociateNetworks returns..");
        return result;
    }

    /**
     * It handles the invocations to the neutronvpn:dissociateRouter RPC method.
     *
     * @see org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn
     * .rev150602.NeutronvpnService#dissociateRouter(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn
     * .rev150602.DissociateRouterInput)
     */
    @Override
    public Future<RpcResult<Void>> dissociateRouter(DissociateRouterInput input) {

        SettableFuture<RpcResult<Void>> result = SettableFuture.create();

        LOG.debug("dissociateRouter {}", input);
        StringBuilder returnMsg = new StringBuilder();
        Uuid vpnId = input.getVpnId();
        Uuid routerId = input.getRouterId();
        try {
            if (NeutronvpnUtils.getVpnMap(dataBroker, vpnId) != null) {
                if (routerId != null) {
                    Router rtr = NeutronvpnUtils.getNeutronRouter(dataBroker, routerId);
                    if (rtr != null) {
                        Uuid routerVpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerId, true);
                        if (vpnId.equals(routerVpnId)) {
                            dissociateRouterFromVpn(vpnId, routerId);
                        } else {
                            if (routerVpnId == null) {
                                returnMsg.append("input router ").append(routerId.getValue()).append(" not associated" +
                                        " to any vpn yet");
                            } else {
                                returnMsg.append("input router ").append(routerId.getValue()).append(" associated to " +
                                        "vpn ").append(routerVpnId.getValue()).append("instead of the vpn given as " +
                                        "input");
                            }
                        }
                    } else {
                        returnMsg.append("router not found : ").append(routerId.getValue());
                    }
                }
            } else {
                returnMsg.append("VPN not found : ").append(vpnId.getValue());
            }
            if (returnMsg.length() != 0) {
                String message = String.format("dissociate router %s to vpn %s failed due to %s", routerId.getValue(),
                        vpnId.getValue(), returnMsg);
                LOG.error(message);
                String errorResponse = String.format("ErrorType: PROTOCOL, ErrorTag: invalid-value, ErrorMessage: "
                        + message);
                result.set(RpcResultBuilder.<Void> failed().withWarning(ErrorType.PROTOCOL, "invalid-value", message)
                        .build());
            } else {
                result.set(RpcResultBuilder.<Void> success().build());
            }
        } catch (Exception ex) {
            String message = String.format("disssociate router %s to vpn %s failed due to %s", routerId.getValue(),
                    vpnId.getValue(), ex.getMessage());
            LOG.error(message, ex);
            result.set(RpcResultBuilder.<Void> failed().withError(ErrorType.APPLICATION, message).build());
        }
        LOG.debug("dissociateRouter returns..");

        return result;
    }

    protected void handleNeutronRouterDeleted(Uuid routerId, List<Uuid> routerSubnetIds) {
        // check if the router is associated to some VPN
        Uuid vpnId = NeutronvpnUtils.getVpnForRouter(dataBroker, routerId, true);
        if (vpnId != null) {
            // remove existing external vpn interfaces
            for (Uuid subnetId : routerSubnetIds) {
                removeSubnetFromVpn(vpnId, subnetId);
            }
            clearFromVpnMaps(vpnId, routerId, null);
        } else {
            // remove existing internal vpn interfaces
            for (Uuid subnetId : routerSubnetIds) {
                removeSubnetFromVpn(routerId, subnetId);
            }
        }
        // delete entire vpnMaps node for internal VPN
        deleteVpnMapsNode(routerId);

        // delete vpn-instance for internal VPN
        deleteVpnInstance(routerId);
    }

    protected Subnet getNeutronSubnet(Uuid subnetId){
        return NeutronvpnUtils.getNeutronSubnet(dataBroker, subnetId);
    }

    protected IpAddress getNeutronSubnetGateway(Uuid subnetId) {
        Subnet sn = NeutronvpnUtils.getNeutronSubnet(dataBroker, subnetId);
        if (null != sn) {
            return sn.getGatewayIp();
        }
        return null;
    }


    protected Network getNeutronNetwork(Uuid networkId) {
        return NeutronvpnUtils.getNeutronNetwork(dataBroker, networkId);
    }

    protected Port getNeutronPort(String name) {
        return NeutronvpnUtils.getNeutronPort(dataBroker, new Uuid(name));
    }

    protected Port getNeutronPort(Uuid portId) {
        return NeutronvpnUtils.getNeutronPort(dataBroker, portId);
    }

    protected List<Uuid> getSubnetsforVpn(Uuid vpnid) {
        List<Uuid> subnets = new ArrayList<>();
        // read subnetmaps
        InstanceIdentifier<Subnetmaps> subnetmapsid = InstanceIdentifier.builder(Subnetmaps.class).build();
        Optional<Subnetmaps> subnetmaps = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION,
                subnetmapsid);
        if (subnetmaps.isPresent() && subnetmaps.get().getSubnetmap() != null) {
            List<Subnetmap> subnetMapList = subnetmaps.get().getSubnetmap();
            for (Subnetmap subnetMap : subnetMapList) {
                if (subnetMap.getVpnId() != null && subnetMap.getVpnId().equals(vpnid)) {
                    subnets.add(subnetMap.getId());
                }
            }
        }
        return subnets;
    }

    /**
     * Implementation of the "vpnservice:neutron-ports-show" Karaf CLI command
     *
     * @return a List of String to be printed on screen
     */
    public List<String> showNeutronPortsCLI() {
        List<String> result = new ArrayList<>();
        result.add(String.format(" %-36s  %-19s  %-13s  %-20s ", "Port ID", "Mac Address", "Prefix Length", "IP " +
                "Address"));
        result.add("-------------------------------------------------------------------------------------------");
        InstanceIdentifier<Ports> portidentifier = InstanceIdentifier.create(Neutron.class).child(Ports.class);
        try {
            Optional<Ports> ports = NeutronvpnUtils.read(dataBroker, LogicalDatastoreType.CONFIGURATION, portidentifier);
            if (ports.isPresent() && ports.get().getPort() != null) {
                for (Port port : ports.get().getPort()) {
                    List<FixedIps> fixedIPs = port.getFixedIps();
                    try {
                        if (fixedIPs != null && !fixedIPs.isEmpty()) {
                            List<String> ipList = new ArrayList<>();
                            for (FixedIps fixedIp : fixedIPs) {
                                IpAddress ipAddress = fixedIp.getIpAddress();
                                if (ipAddress.getIpv4Address() != null) {
                                    ipList.add(ipAddress.getIpv4Address().getValue());
                                } else {
                                    ipList.add((ipAddress.getIpv6Address().getValue()));
                                }
                            }
                            result.add(String.format(" %-36s  %-19s  %-13s  %-20s ", port.getUuid().getValue(), port
                                    .getMacAddress().getValue(), NeutronvpnUtils.getIPPrefixFromPort(dataBroker, port),
                                    ipList.toString()));
                        } else {
                            result.add(String.format(" %-36s  %-19s  %-13s  %-20s ", port.getUuid().getValue(), port
                                    .getMacAddress().getValue(), "Not Assigned", "Not " + "Assigned"));
                        }
                    } catch (Exception e) {
                        LOG.error("Failed to retrieve neutronPorts info for port {}: ", port.getUuid().getValue(),
                                e);
                        System.out.println("Failed to retrieve neutronPorts info for port: " + port.getUuid()
                                .getValue() + ": " + e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            LOG.error("Failed to retrieve neutronPorts info : ", e);
            System.out.println("Failed to retrieve neutronPorts info : " + e.getMessage());
        }
        return result;
    }

    /**
     * Implementation of the "vpnservice:l3vpn-config-show" karaf CLI command
     *
     * @param vpnuuid Uuid of the VPN whose config must be shown
     * @return formatted output list
     */
    public List<String> showVpnConfigCLI(Uuid vpnuuid) {
        List<String> result = new ArrayList<>();
        if (vpnuuid == null) {
            System.out.println("");
            System.out.println("Displaying VPN config for all VPNs");
            System.out.println("To display VPN config for a particular VPN, use the following syntax");
            System.out.println(getshowVpnConfigCLIHelp());
        }
        try {
            RpcResult<GetL3VPNOutput> rpcResult = getL3VPN(new GetL3VPNInputBuilder().setId(vpnuuid).build()).get();
            if (rpcResult.isSuccessful()) {
                result.add("");
                result.add(String.format(" %-37s %-37s %-7s ", "VPN ID", "Tenant ID", "RD"));
                result.add("");
                result.add(String.format(" %-80s ", "Import-RTs"));
                result.add("");
                result.add(String.format(" %-80s ", "Export-RTs"));
                result.add("");
                result.add(String.format(" %-76s ", "Subnet IDs"));
                result.add("");
                result.add("------------------------------------------------------------------------------------");
                result.add("");
                List<L3vpnInstances> VpnList = rpcResult.getResult().getL3vpnInstances();
                for (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.VpnInstance Vpn : VpnList) {
                    String tenantId = Vpn.getTenantId() != null ? Vpn.getTenantId().getValue()
                            : "\"                 " + "                  \"";
                    result.add(String.format(" %-37s %-37s %-7s ", Vpn.getId().getValue(), tenantId,
                            Vpn.getRouteDistinguisher()));
                    result.add("");
                    result.add(String.format(" %-80s ", Vpn.getImportRT()));
                    result.add("");
                    result.add(String.format(" %-80s ", Vpn.getExportRT()));
                    result.add("");

                    Uuid vpnid = Vpn.getId();
                    List<Uuid> subnetList = getSubnetsforVpn(vpnid);
                    if (!subnetList.isEmpty()) {
                        for (Uuid subnetuuid : subnetList) {
                            result.add(String.format(" %-76s ", subnetuuid.getValue()));
                        }
                    } else {
                        result.add(String.format(" %-76s ", "\"                                    \""));
                    }
                    result.add("");
                    result.add("----------------------------------------");
                    result.add("");
                }
            } else {
                String errortag = rpcResult.getErrors().iterator().next().getTag();
                if (errortag == "") {
                    System.out.println("");
                    System.out.println("No VPN has been configured yet");
                } else if (errortag == "invalid-value") {
                    System.out.println("");
                    System.out.println("VPN " + vpnuuid.getValue() + " is not present");
                } else {
                    System.out.println("error getting VPN info : " + rpcResult.getErrors());
                    System.out.println(getshowVpnConfigCLIHelp());
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("error getting VPN info : ", e);
            System.out.println("error getting VPN info : " + e.getMessage());
        }
        return result;
    }

    protected void createExternalVpnInterfaces(Uuid extNetId) {
        if (extNetId == null) {
            LOG.trace("external network is null");
            return;
        }

        Collection<String> extElanInterfaces = elanService.getExternalElanInterfaces(extNetId.getValue());
        if (extElanInterfaces == null || extElanInterfaces.isEmpty()) {
            LOG.trace("No external ports attached to external network {}", extNetId.getValue());
            return;
        }

        for (String elanInterface : extElanInterfaces) {
            createExternalVpnInterface(extNetId, elanInterface);
        }
    }

    protected void removeExternalVpnInterfaces(Uuid extNetId) {
        Collection<String> extElanInterfaces = elanService.getExternalElanInterfaces(extNetId.getValue());
        if (extElanInterfaces == null || extElanInterfaces.isEmpty()) {
            LOG.trace("No external ports attached for external network {}", extNetId);
            return;
        }

        for (String elanInterface : extElanInterfaces) {
            boolean isLockAcquired = false;
            InstanceIdentifier<VpnInterface> vpnIfIdentifier = NeutronvpnUtils
                    .buildVpnInterfaceIdentifier(elanInterface);
            try {
                isLockAcquired = NeutronvpnUtils.lock(elanInterface);
                LOG.debug("removing vpn interface {}, vpnIfIdentifier", elanInterface, vpnIfIdentifier);
                MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIfIdentifier);
            } catch (Exception ex) {
                LOG.error("Removal of vpninterface {} failed due to {}", elanInterface, ex);
            } finally {
                if (isLockAcquired) {
                    NeutronvpnUtils.unlock(elanInterface);
                }
            }
        }
    }

    private void createExternalVpnInterface(Uuid vpnId, String infName) {
        writeVpnInterfaceToDs(vpnId, infName, null, false /* not a router iface */, null);
    }

    private void writeVpnInterfaceToDs(Uuid vpnId, String infName, Adjacencies adjacencies,
            Boolean isRouterInterface, WriteTransaction wrtConfigTxn) {
        if (vpnId == null || infName == null) {
            LOG.debug("vpn id or interface is null");
            return;
        }

        Boolean wrtConfigTxnPresent = true;
        if (wrtConfigTxn == null) {
            wrtConfigTxnPresent = false;
            wrtConfigTxn = dataBroker.newWriteOnlyTransaction();
        }

        InstanceIdentifier<VpnInterface> vpnIfIdentifier = NeutronvpnUtils.buildVpnInterfaceIdentifier(infName);
        VpnInterfaceBuilder vpnb = new VpnInterfaceBuilder().setKey(new VpnInterfaceKey(infName))
                .setName(infName)
                .setVpnInstanceName(vpnId.getValue())
                .setIsRouterInterface(isRouterInterface);
        if (adjacencies != null) {
            vpnb.addAugmentation(Adjacencies.class, adjacencies);
        }
        VpnInterface vpnIf = vpnb.build();
        try {
            LOG.info("Creating vpn interface {}", vpnIf);
            wrtConfigTxn.put(LogicalDatastoreType.CONFIGURATION, vpnIfIdentifier, vpnIf);
        } catch (Exception ex) {
            LOG.error("Creation of vpninterface {} failed due to {}", infName, ex);
        }

        if (!wrtConfigTxnPresent) {
            wrtConfigTxn.submit();
        }
    }

    private String getshowVpnConfigCLIHelp() {
        StringBuilder help = new StringBuilder("Usage:");
        help.append("display vpn-config [-vid/--vpnid <id>]");
        return help.toString();
    }

    private void checkAndPublishSubnetAddNotification(Uuid subnetId, String subnetIp, String vpnName,
                                                      Boolean isExternalvpn, Long elanTag) throws InterruptedException {
        SubnetAddedToVpnBuilder builder = new SubnetAddedToVpnBuilder();

        LOG.info("publish notification called");

        builder.setSubnetId(subnetId);
        builder.setSubnetIp(subnetIp);
        builder.setVpnName(vpnName);
        builder.setExternalVpn(isExternalvpn);
        builder.setElanTag(elanTag);

        notificationPublishService.putNotification(builder.build());
    }

    private void checkAndPublishSubnetDelNotification(Uuid subnetId, String subnetIp, String vpnName,
                                                      Boolean isExternalvpn, Long elanTag) throws InterruptedException {
        SubnetDeletedFromVpnBuilder builder = new SubnetDeletedFromVpnBuilder();

        LOG.info("publish notification called");

        builder.setSubnetId(subnetId);
        builder.setSubnetIp(subnetIp);
        builder.setVpnName(vpnName);
        builder.setExternalVpn(isExternalvpn);
        builder.setElanTag(elanTag);

        notificationPublishService.putNotification(builder.build());
    }

    private void checkAndPublishSubnetUpdNotification(Uuid subnetId, String subnetIp, String vpnName,
                                                      Boolean isExternalvpn, Long elanTag) throws InterruptedException {
        SubnetUpdatedInVpnBuilder builder = new SubnetUpdatedInVpnBuilder();

        LOG.info("publish notification called");

        builder.setSubnetId(subnetId);
        builder.setSubnetIp(subnetIp);
        builder.setVpnName(vpnName);
        builder.setExternalVpn(isExternalvpn);
        builder.setElanTag(elanTag);

        notificationPublishService.putNotification(builder.build());
    }

    private void checkAndPublishRouterAssociatedtoVpnNotification(Uuid routerId, Uuid vpnId) throws
            InterruptedException {
        RouterAssociatedToVpn routerAssociatedToVpn = new RouterAssociatedToVpnBuilder().setRouterId(routerId)
                .setVpnId(vpnId).build();
        LOG.info("publishing notification upon association of router to VPN");
        notificationPublishService.putNotification(routerAssociatedToVpn);
    }

    private void checkAndPublishRouterDisassociatedFromVpnNotification(Uuid routerId, Uuid vpnId) throws
            InterruptedException {
        RouterDisassociatedFromVpn routerDisassociatedFromVpn = new RouterDisassociatedFromVpnBuilder().setRouterId
                (routerId).setVpnId(vpnId).build();
        LOG.info("publishing notification upon disassociation of router from VPN");
        notificationPublishService.putNotification(routerDisassociatedFromVpn);
    }

    protected void dissociatefixedIPFromFloatingIP(String fixedNeutronPortName) {
        floatingIpMapListener.dissociatefixedIPFromFloatingIP(fixedNeutronPortName);
    }
}
