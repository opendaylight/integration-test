/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NWUtil;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.cache.DataStoreCache;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnAfConfig;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstanceKey;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdPools;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.id.pools.IdPool;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.id.pools.IdPoolKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.IfIndexesInterfaceMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.LockManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.TimeUnits;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.TryLockInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.TryLockInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.UnlockInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.lockmanager.rev160413.UnlockInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanTagNameMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.tag.name.map.ElanTagName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.tag.name.map.ElanTagNameKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.L3nexthop;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthops;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthopsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.Adjacencies;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.AdjacenciesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.PrefixToInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.RouterInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnIdToVpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceToVpnId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnToExtraroute;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.VpnIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.VpnIdsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.VpnIdsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.Prefixes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.PrefixesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.PrefixesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstanceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.Vpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.VpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.VpnKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.vpn.Extraroute;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.vpn.ExtrarouteBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.to.extraroute.vpn.ExtrarouteKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExtRouters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalNetworks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.NaptSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.RoutersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.NetworksKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdPools;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.id.pools.IdPool;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.id.pools.IdPoolKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.IfIndexesInterfaceMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.L3nexthop;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthops;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthopsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterInterfacesMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.IpVersionBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.IpVersionV4;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.SubnetKey;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yangtools.yang.data.impl.schema.tree.SchemaValidationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;
import com.google.common.primitives.Ints;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;

public class VpnUtil {
    private static final Logger LOG = LoggerFactory.getLogger(VpnUtil.class);
    private static final int DEFAULT_PREFIX_LENGTH = 32;
    private static final String PREFIX_SEPARATOR = "/";

    static InstanceIdentifier<VpnInterface> getVpnInterfaceIdentifier(String vpnInterfaceName) {
        return InstanceIdentifier.builder(VpnInterfaces.class)
                .child(VpnInterface.class, new VpnInterfaceKey(vpnInterfaceName)).build();
    }

    static InstanceIdentifier<VpnInstance> getVpnInstanceIdentifier(String vpnName) {
        return InstanceIdentifier.builder(VpnInstances.class)
                .child(VpnInstance.class, new VpnInstanceKey(vpnName)).build();
    }

    static VpnInterface getVpnInterface(String intfName, String vpnName, Adjacencies aug, BigInteger dpnId, Boolean isSheduledForRemove) {
        return new VpnInterfaceBuilder().setKey(new VpnInterfaceKey(intfName)).setVpnInstanceName(vpnName).setDpnId(dpnId)
                .setScheduledForRemove(isSheduledForRemove).addAugmentation(Adjacencies.class, aug)
                .build();
    }

    static InstanceIdentifier<Prefixes> getPrefixToInterfaceIdentifier(long vpnId, String ipPrefix) {
        return InstanceIdentifier.builder(PrefixToInterface.class)
                .child(VpnIds.class, new VpnIdsKey(vpnId)).child(Prefixes.class,
                        new PrefixesKey(ipPrefix)).build();
    }

    static InstanceIdentifier<VpnIds> getPrefixToInterfaceIdentifier(long vpnId) {
        return InstanceIdentifier.builder(PrefixToInterface.class)
                .child(VpnIds.class, new VpnIdsKey(vpnId)).build();
    }

    static VpnIds getPrefixToInterface(long vpnId) {
        return new VpnIdsBuilder().setKey(new VpnIdsKey(vpnId)).setVpnId(vpnId).build();
    }

    static Prefixes getPrefixToInterface(BigInteger dpId, String vpnInterfaceName, String ipPrefix) {
        return new PrefixesBuilder().setDpnId(dpId).setVpnInterfaceName(
                vpnInterfaceName).setIpAddress(ipPrefix).build();
    }

    static InstanceIdentifier<Extraroute> getVpnToExtrarouteIdentifier(String vrfId, String ipPrefix) {
        return InstanceIdentifier.builder(VpnToExtraroute.class)
                .child(Vpn.class, new VpnKey(vrfId)).child(Extraroute.class,
                        new ExtrarouteKey(ipPrefix)).build();
    }

    static InstanceIdentifier<Vpn> getVpnToExtrarouteIdentifier(String vrfId) {
        return InstanceIdentifier.builder(VpnToExtraroute.class)
                .child(Vpn.class, new VpnKey(vrfId)).build();
    }

    static Vpn getVpnToExtraRoute(String vrfId) {
        return new VpnBuilder().setKey(new VpnKey(vrfId)).setVrfId(vrfId).build();
    }

    /**
     * Get VRF table given a Route Distinguisher
     *
     * @param broker dataBroker service reference
     * @param rd Route-Distinguisher
     * @return VrfTables that holds the list of VrfEntries of the specified rd
     */
    public static VrfTables getVrfTable(DataBroker broker, String rd) {
        InstanceIdentifier<VrfTables> id =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).build();
        Optional<VrfTables> vrfTable = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        return vrfTable.isPresent() ? vrfTable.get() : null;
    }

    /**
     * Retrieves the VrfEntries that belong to a given VPN filtered out by
     * Origin, searching by its Route-Distinguisher
     *
     * @param broker dataBroker service reference
     * @param rd     Route-distinguisher of the VPN
     * @param originsToConsider Only entries whose origin is included in this
     *     list will be considered
     * @return the list of VrfEntries
     */
    public static List<VrfEntry> getVrfEntriesByOrigin(DataBroker broker, String rd,
                                                       List<RouteOrigin> originsToConsider) {
        List<VrfEntry> result = new ArrayList<VrfEntry>();
        List<VrfEntry> allVpnVrfEntries = getAllVrfEntries(broker, rd);
        for (VrfEntry vrfEntry : allVpnVrfEntries) {
            if (originsToConsider.contains(RouteOrigin.value(vrfEntry.getOrigin()))) {
                result.add(vrfEntry);
            }
        }
        return result;
    }

    static List<Prefixes> getAllPrefixesToInterface(DataBroker broker, long vpnId) {
        Optional<VpnIds> vpnIds = read(broker, LogicalDatastoreType.OPERATIONAL, getPrefixToInterfaceIdentifier(vpnId));
        if (vpnIds.isPresent()) {
            return vpnIds.get().getPrefixes();
        }
        return new ArrayList<Prefixes>();
    }

    static List<Extraroute> getAllExtraRoutes(DataBroker broker, String vrfId) {
        Optional<Vpn> extraRoutes = read(broker, LogicalDatastoreType.OPERATIONAL, getVpnToExtrarouteIdentifier(vrfId));
        if (extraRoutes.isPresent()) {
            return extraRoutes.get().getExtraroute();
        }
        return new ArrayList<Extraroute>();
    }

    /**
     * Retrieves all the VrfEntries that belong to a given VPN searching by its
     * Route-Distinguisher
     *
     * @param broker dataBroker service reference
     * @param rd     Route-distinguisher of the VPN
     * @return the list of VrfEntries
     */
    public static List<VrfEntry> getAllVrfEntries(DataBroker broker, String rd) {
        VrfTables vrfTables = VpnUtil.getVrfTable(broker, rd);
        return (vrfTables != null) ? vrfTables.getVrfEntry() : new ArrayList<VrfEntry>();
    }

    //FIXME: Implement caches for DS reads
    public static VpnInstance getVpnInstance(DataBroker broker, String vpnInstanceName) {
        InstanceIdentifier<VpnInstance> id = InstanceIdentifier.builder(VpnInstances.class).child(VpnInstance.class,
                new VpnInstanceKey(vpnInstanceName)).build();
        Optional<VpnInstance> vpnInstance = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        return (vpnInstance.isPresent()) ? vpnInstance.get() : null;
    }

    static List<VpnInstance> getAllVpnInstances(DataBroker broker) {
        InstanceIdentifier<VpnInstances> id = InstanceIdentifier.builder(VpnInstances.class).build();
        Optional<VpnInstances> optVpnInstances = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (optVpnInstances.isPresent()) {
            return optVpnInstances.get().getVpnInstance();
        } else {
            return Collections.emptyList();
        }
    }

    static List<VpnInstanceOpDataEntry> getAllVpnInstanceOpData(DataBroker broker) {
        InstanceIdentifier<VpnInstanceOpData> id = InstanceIdentifier.builder(VpnInstanceOpData.class).build();
        Optional<VpnInstanceOpData> vpnInstanceOpDataOptional = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, id);
        if (vpnInstanceOpDataOptional.isPresent()) {
            return vpnInstanceOpDataOptional.get().getVpnInstanceOpDataEntry();
        } else {
            return new ArrayList<VpnInstanceOpDataEntry>();
        }
    }

    public static List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn
            .instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces> getDpnVpnInterfaces(DataBroker broker,
                    VpnInstance vpnInstance, BigInteger dpnId) {
        String rd = getRdFromVpnInstance(vpnInstance);
        InstanceIdentifier<VpnToDpnList> dpnToVpnId = getVpnToDpnListIdentifier(rd, dpnId);
        Optional<VpnToDpnList> dpnInVpn = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, dpnToVpnId);
        return dpnInVpn.isPresent() ? dpnInVpn.get().getVpnInterfaces() : Collections.emptyList();
    }

    public static String getRdFromVpnInstance(VpnInstance vpnInstance) {
        VpnAfConfig vpnConfig = vpnInstance.getIpv4Family();
        LOG.trace("vpnConfig {}", vpnConfig);
        String rd = vpnConfig.getRouteDistinguisher();
        if (rd == null || rd.isEmpty()) {
            rd = vpnInstance.getVpnInstanceName();
            LOG.trace("rd is null or empty. Assigning VpnInstanceName to rd {}", rd);
        }

        return rd;
    }

    static VrfEntry getVrfEntry(DataBroker broker, String rd, String ipPrefix) {

        VrfTables vrfTable = getVrfTable(broker, rd);
        // TODO: why check VrfTables if we later go for the specific VrfEntry?
        if (vrfTable != null) {
            InstanceIdentifier<VrfEntry> vrfEntryId =
                    InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).
                            child(VrfEntry.class, new VrfEntryKey(ipPrefix)).build();
            Optional<VrfEntry> vrfEntry = read(broker, LogicalDatastoreType.CONFIGURATION, vrfEntryId);
            if (vrfEntry.isPresent()) {
                return vrfEntry.get();
            }
        }
        return null;
    }

    static List<Adjacency> getAdjacenciesForVpnInterfaceFromConfig(DataBroker broker, String intfName) {
        final InstanceIdentifier<VpnInterface> identifier = getVpnInterfaceIdentifier(intfName);
        InstanceIdentifier<Adjacencies> path = identifier.augmentation(Adjacencies.class);
        Optional<Adjacencies> adjacencies = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, path);

        if (adjacencies.isPresent()) {
            List<Adjacency> nextHops = adjacencies.get().getAdjacency();
            return nextHops;
        }
        return null;
    }

    static Extraroute getVpnToExtraroute(String ipPrefix, List<String> nextHopList) {
        return new ExtrarouteBuilder().setPrefix(ipPrefix).setNexthopIpList(nextHopList).build();
    }

    public static List<Extraroute> getVpnExtraroutes(DataBroker broker, String vpnRd) {
        InstanceIdentifier<Vpn> vpnExtraRoutesId =
                InstanceIdentifier.builder(VpnToExtraroute.class).child(Vpn.class, new VpnKey(vpnRd)).build();
        Optional<Vpn> vpnOpc = read(broker, LogicalDatastoreType.OPERATIONAL, vpnExtraRoutesId);
        return vpnOpc.isPresent() ? vpnOpc.get().getExtraroute() : new ArrayList<Extraroute>();
    }

    static Adjacencies getVpnInterfaceAugmentation(List<Adjacency> nextHopList) {
        return new AdjacenciesBuilder().setAdjacency(nextHopList).build();
    }

    public static InstanceIdentifier<IdPool> getPoolId(String poolName) {
        InstanceIdentifier.InstanceIdentifierBuilder<IdPool> idBuilder =
                InstanceIdentifier.builder(IdPools.class).child(IdPool.class, new IdPoolKey(poolName));
        InstanceIdentifier<IdPool> id = idBuilder.build();
        return id;
    }

    static InstanceIdentifier<VpnInterfaces> getVpnInterfacesIdentifier() {
        return InstanceIdentifier.builder(VpnInterfaces.class).build();
    }

    static InstanceIdentifier<Interface> getInterfaceIdentifier(String interfaceName) {
        return InstanceIdentifier.builder(Interfaces.class)
                .child(Interface.class, new InterfaceKey(interfaceName)).build();
    }

    static InstanceIdentifier<VpnToDpnList> getVpnToDpnListIdentifier(String rd, BigInteger dpnId) {
        return InstanceIdentifier.builder(VpnInstanceOpData.class)
                .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(rd))
                .child(VpnToDpnList.class, new VpnToDpnListKey(dpnId)).build();
    }

    public static BigInteger getCookieArpFlow(int interfaceTag) {
        return VpnConstants.COOKIE_L3_BASE.add(new BigInteger("0110000", 16)).add(
                BigInteger.valueOf(interfaceTag));
    }

    public static BigInteger getCookieL3(int vpnId) {
        return VpnConstants.COOKIE_L3_BASE.add(new BigInteger("0610000", 16)).add(BigInteger.valueOf(vpnId));
    }

    public static String getFlowRef(BigInteger dpnId, short tableId, int ethType, int lPortTag, int arpType) {
        return new StringBuffer().append(VpnConstants.FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR).append(ethType).append(lPortTag)
                .append(NwConstants.FLOWID_SEPARATOR).append(arpType).toString();
    }

    public static int getUniqueId(IdManagerService idManager, String poolName, String idKey) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();

        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                return rpcResult.getResult().getIdValue().intValue();
            } else {
                LOG.warn("RPC Call to Get Unique Id returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting Unique Id", e);
        }
        return 0;
    }

    public static void releaseId(IdManagerService idManager, String poolName, String idKey) {
        ReleaseIdInput idInput = new ReleaseIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();
        try {
            Future<RpcResult<Void>> result = idManager.releaseId(idInput);
            RpcResult<Void> rpcResult = result.get();
            if (!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to Get Unique Id returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting Unique Id for key {}", idKey, e);
        }
    }

    public static String getNextHopLabelKey(String rd, String prefix) {
        return rd + VpnConstants.SEPARATOR + prefix;
    }

    /**
     * Retrieves the VpnInstance name (typically the VPN Uuid) out from the
     * route-distinguisher
     *
     * @param broker dataBroker service reference
     * @param rd Route-Distinguisher
     * @return the VpnInstance name
     */
    public static String getVpnNameFromRd(DataBroker broker, String rd) {
        VpnInstanceOpDataEntry vpnInstanceOpData = getVpnInstanceOpData(broker, rd);
        return (vpnInstanceOpData != null) ? vpnInstanceOpData.getVpnInstanceName() : null;
    }

    /**
     * Retrieves the dataplane identifier of a specific VPN, searching by its
     * VpnInstance name.
     *
     * @param broker dataBroker service reference
     * @param vpnName Name of the VPN
     * @return the dataplane identifier of the VPN, the VrfTag.
     */
    public static long getVpnId(DataBroker broker, String vpnName) {

        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> id
                = getVpnInstanceToVpnIdIdentifier(vpnName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        long vpnId = VpnConstants.INVALID_ID;
        if (vpnInstance.isPresent()) {
            vpnId = vpnInstance.get().getVpnId();
        }
        return vpnId;
    }

    /**
     * Retrieves the VPN Route Distinguisher searching by its Vpn instance name
     *
     * @param broker dataBroker service reference
     * @param vpnName Name of the VPN
     * @return the route-distinguisher of the VPN
     */
    public static String getVpnRd(DataBroker broker, String vpnName) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> id
                = getVpnInstanceToVpnIdIdentifier(vpnName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        String rd = null;
        if (vpnInstance.isPresent()) {
            rd = vpnInstance.get().getVrfId();
        }
        return rd;
    }

    /**
     * Get VPN Route Distinguisher from VPN Instance Configuration
     *
     * @param broker dataBroker service reference
     * @param vpnName Name of the VPN
     * @return the route-distinguisher of the VPN
     */
    public static String getVpnRdFromVpnInstanceConfig(DataBroker broker, String vpnName) {
        InstanceIdentifier<VpnInstance> id = InstanceIdentifier.builder(VpnInstances.class)
                .child(VpnInstance.class, new VpnInstanceKey(vpnName)).build();
        Optional<VpnInstance> vpnInstance = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, id);
        String rd = null;
        if (vpnInstance.isPresent()) {
            VpnInstance instance = vpnInstance.get();
            VpnAfConfig config = instance.getIpv4Family();
            rd = config.getRouteDistinguisher();
        }
        return rd;
    }

    /**
     * Remove from MDSAL all those VrfEntries in a VPN that have an specific RouteOrigin
     *
     * @param broker dataBroker service reference
     * @param rd     Route Distinguisher
     * @param origin Origin of the Routes to be removed (see {@link RouteOrigin})
     */
    public static void removeVrfEntriesByOrigin(DataBroker broker, String rd, RouteOrigin origin) {
        InstanceIdentifier<VrfTables> vpnVrfTableIid =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).build();
        Optional<VrfTables> vrfTablesOpc = read(broker, LogicalDatastoreType.CONFIGURATION, vpnVrfTableIid);
        if (vrfTablesOpc.isPresent()) {
            VrfTables vrfTables = vrfTablesOpc.get();
            List<VrfEntry> newVrfEntries = new ArrayList<VrfEntry>();
            for (VrfEntry vrfEntry : vrfTables.getVrfEntry()) {
                if (origin == RouteOrigin.value(vrfEntry.getOrigin())) {
                    delete(broker, LogicalDatastoreType.CONFIGURATION, vpnVrfTableIid.child(VrfEntry.class,
                            vrfEntry.getKey()));
                }
            }
        }
    }

    public static List<VrfEntry> findVrfEntriesByNexthop(DataBroker broker, String rd, String nexthop) {
        InstanceIdentifier<VrfTables> vpnVrfTableIid =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).build();
        Optional<VrfTables> vrfTablesOpc = read(broker, LogicalDatastoreType.CONFIGURATION, vpnVrfTableIid);
        List<VrfEntry> matches = new ArrayList<VrfEntry>();

        if (vrfTablesOpc.isPresent()) {
            VrfTables vrfTables = vrfTablesOpc.get();
            for (VrfEntry vrfEntry : vrfTables.getVrfEntry()) {
                if (vrfEntry.getNextHopAddressList() != null && vrfEntry.getNextHopAddressList().contains(nexthop)) {
                    matches.add(vrfEntry);
                }
            }
        }
        return matches;
    }

    public static void removeVrfEntries(DataBroker broker, String rd, List<VrfEntry> vrfEntries) {
        InstanceIdentifier<VrfTables> vpnVrfTableIid =
            InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).build();
        for (VrfEntry vrfEntry : vrfEntries) {
            delete(broker, LogicalDatastoreType.CONFIGURATION, vpnVrfTableIid.child(VrfEntry.class,
                                                                                    vrfEntry.getKey()));
        }
    }

    static org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance
                getVpnInstanceToVpnId(String vpnName, long vpnId, String rd) {

        return new VpnInstanceBuilder().setVpnId(vpnId).setVpnInstanceName(vpnName).setVrfId(rd).build();

    }

    static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance>
                getVpnInstanceToVpnIdIdentifier(String vpnName) {
        return InstanceIdentifier.builder(VpnInstanceToVpnId.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance.class,
                        new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstanceKey(vpnName)).build();
    }

    static RouterInterface getConfiguredRouterInterface(DataBroker broker, String interfaceName) {
        Optional<RouterInterface> optRouterInterface = read(broker, LogicalDatastoreType.CONFIGURATION, VpnUtil.getRouterInterfaceId(interfaceName));
        if(optRouterInterface.isPresent()) {
            return optRouterInterface.get();
        }
        return null;
    }

    static org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds
                getVpnIdToVpnInstance(long vpnId, String vpnName, String rd, boolean isExternalVpn) {
        return new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIdsBuilder()
                .setVpnId(vpnId).setVpnInstanceName(vpnName).setVrfId(rd).setExternalVpn(isExternalVpn).build();

    }

    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds>
        getVpnIdToVpnInstanceIdentifier(long vpnId) {
        return InstanceIdentifier.builder(VpnIdToVpnInstance.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds.class,
                        new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIdsKey(Long.valueOf(vpnId))).build();
    }

    /**
     * Retrieves the Vpn Name searching by its VPN Tag.
     *
     * @param broker dataBroker service reference
     * @param vpnId Dataplane identifier of the VPN
     * @return the Vpn instance name
     */
    public static String getVpnName(DataBroker broker, long vpnId) {

        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds> id
                = getVpnIdToVpnInstanceIdentifier(vpnId);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        String vpnName = null;
        if (vpnInstance.isPresent()) {
            vpnName = vpnInstance.get().getVpnInstanceName();
        }
        return vpnName;
    }

    public static InstanceIdentifier<VpnInstanceOpDataEntry> getVpnInstanceOpDataIdentifier(String rd) {
        return InstanceIdentifier.builder(VpnInstanceOpData.class)
                .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(rd)).build();
    }

    static InstanceIdentifier<RouterInterface> getRouterInterfaceId(String interfaceName) {
        return InstanceIdentifier.builder(RouterInterfaces.class)
                .child(RouterInterface.class, new RouterInterfaceKey(interfaceName)).build();
    }

    static RouterInterface getRouterInterface(String interfaceName, String routerName) {
        return new RouterInterfaceBuilder().setKey(new RouterInterfaceKey(interfaceName))
                .setInterfaceName(interfaceName).setRouterName(routerName).build();
    }

    public static VpnInstanceOpDataEntry getVpnInstanceOpData(DataBroker broker, String rd) {
        InstanceIdentifier<VpnInstanceOpDataEntry> id = VpnUtil.getVpnInstanceOpDataIdentifier(rd);
        return read(broker, LogicalDatastoreType.OPERATIONAL, id).orNull();
    }

    static VpnInstanceOpDataEntry getVpnInstanceOpDataFromCache(DataBroker broker, String rd) {
        InstanceIdentifier<VpnInstanceOpDataEntry> id = VpnUtil.getVpnInstanceOpDataIdentifier(rd);
        return (VpnInstanceOpDataEntry) DataStoreCache.get(VpnConstants.VPN_OP_INSTANCE_CACHE_NAME, id, rd, broker, false);
    }

    static VpnInterface getConfiguredVpnInterface(DataBroker broker, String interfaceName) {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> configuredVpnInterface = read(broker, LogicalDatastoreType.CONFIGURATION, interfaceId);

        if (configuredVpnInterface.isPresent()) {
            return configuredVpnInterface.get();
        }
        return null;
    }

    static String getNeutronRouterFromInterface(DataBroker broker, String interfaceName) {
        InstanceIdentifier.InstanceIdentifierBuilder<RouterInterfacesMap> idBuilder =
                            InstanceIdentifier.builder(RouterInterfacesMap.class);
        InstanceIdentifier<RouterInterfacesMap> id = idBuilder.build();
        Optional<RouterInterfacesMap> RouterInterfacesMap = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (RouterInterfacesMap.isPresent()) {
              List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces> rtrInterfaces = RouterInterfacesMap.get().getRouterInterfaces();
              for (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces rtrInterface : rtrInterfaces) {
                  List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces> rtrIfc = rtrInterface.getInterfaces();
                  for(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces ifc : rtrIfc) {
                      if (ifc.getInterfaceId().equals(interfaceName)) {
                          return rtrInterface.getRouterId().getValue();
                      }
                  }
              }
        }
        return null;
    }

    static VpnInterface getOperationalVpnInterface(DataBroker broker, String interfaceName) {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> operationalVpnInterface = read(broker, LogicalDatastoreType.OPERATIONAL, interfaceId);

        if (operationalVpnInterface.isPresent()) {
            return operationalVpnInterface.get();
        }
        return null;
    }

    static boolean isVpnInterfaceConfigured(DataBroker broker, String interfaceName) {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> configuredVpnInterface = read(broker, LogicalDatastoreType.CONFIGURATION, interfaceId);

        if (configuredVpnInterface.isPresent()) {
            return true;
        }
        return false;
    }

    static boolean isInterfaceAssociatedWithVpn(DataBroker broker, String vpnName, String interfaceName) {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> optConfiguredVpnInterface = read(broker, LogicalDatastoreType.CONFIGURATION, interfaceId);

        if (optConfiguredVpnInterface.isPresent()) {
            String configuredVpnName = optConfiguredVpnInterface.get().getVpnInstanceName();
            if ((configuredVpnName != null) && (configuredVpnName.equalsIgnoreCase(vpnName))) {
                return true;
            }
        }
        return false;
    }

    static String getIpPrefix(String prefix) {
        String prefixValues[] = prefix.split("/");
        if (prefixValues.length == 1) {
            prefix = prefix + PREFIX_SEPARATOR + DEFAULT_PREFIX_LENGTH;
        }
        return prefix;
    }

    static final FutureCallback<Void> DEFAULT_CALLBACK =
            new FutureCallback<Void>() {
                @Override
                public void onSuccess(Void result) {
                    LOG.debug("Success in Datastore operation");
                }

                @Override
                public void onFailure(Throwable error) {
                    LOG.error("Error in Datastore operation", error);
                }

                ;
            };

    public static <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType,
                                                          InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
            tx.close();
        }

        return result;
    }

    public static <T extends DataObject> void asyncUpdate(DataBroker broker, LogicalDatastoreType datastoreType,
                                                          InstanceIdentifier<T> path, T data) {
        asyncUpdate(broker, datastoreType, path, data, DEFAULT_CALLBACK);
    }

    public static <T extends DataObject> void asyncUpdate(DataBroker broker, LogicalDatastoreType datastoreType,
                                                          InstanceIdentifier<T> path, T data, FutureCallback<Void> callback) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.merge(datastoreType, path, data, true);
        Futures.addCallback(tx.submit(), callback);
    }

    public static <T extends DataObject> void asyncWrite(DataBroker broker, LogicalDatastoreType datastoreType,
                                                         InstanceIdentifier<T> path, T data) {
        asyncWrite(broker, datastoreType, path, data, DEFAULT_CALLBACK);
    }

    public static <T extends DataObject> void asyncWrite(DataBroker broker, LogicalDatastoreType datastoreType,
                                                         InstanceIdentifier<T> path, T data, FutureCallback<Void> callback) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.put(datastoreType, path, data, true);
        Futures.addCallback(tx.submit(), callback);
    }

    public static <T extends DataObject> void tryDelete(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path) {
        try {
            delete(broker, datastoreType, path, DEFAULT_CALLBACK);
        } catch ( SchemaValidationFailedException sve ) {
            LOG.info("Could not delete {}. SchemaValidationFailedException: {}", path, sve.getMessage());
        } catch ( Exception e) {
            LOG.info("Could not delete {}. Unhandled error: {}", path, e.getMessage());
        }
    }

    public static <T extends DataObject> void delete(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path) {
        delete(broker, datastoreType, path, DEFAULT_CALLBACK);
    }


    public static <T extends DataObject> void delete(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path, FutureCallback<Void> callback) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.delete(datastoreType, path);
        Futures.addCallback(tx.submit(), callback);
    }

    public static <T extends DataObject> void syncWrite(DataBroker broker, LogicalDatastoreType datastoreType,
                                                        InstanceIdentifier<T> path, T data) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.put(datastoreType, path, data, true);
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error writing to datastore (path, data) : ({}, {})", path, data);
            throw new RuntimeException(e.getMessage());
        }
    }

    public static <T extends DataObject> void syncUpdate(DataBroker broker, LogicalDatastoreType datastoreType,
                                                         InstanceIdentifier<T> path, T data) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.merge(datastoreType, path, data, true);
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error writing to datastore (path, data) : ({}, {})", path, data);
            throw new RuntimeException(e.getMessage());
        }
    }

    public static long getRemoteBCGroup(long elanTag) {
        return VpnConstants.ELAN_GID_MIN + ((elanTag % VpnConstants.ELAN_GID_MIN) * 2);
    }

    // interface-index-tag operational container
    public static IfIndexInterface getInterfaceInfoByInterfaceTag(DataBroker broker, long interfaceTag) {
        InstanceIdentifier<IfIndexInterface> interfaceId = getInterfaceInfoEntriesOperationalDataPath(interfaceTag);
        Optional<IfIndexInterface> existingInterfaceInfo = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, interfaceId);
        if (existingInterfaceInfo.isPresent()) {
            return existingInterfaceInfo.get();
        }
        return null;
    }

    private static InstanceIdentifier<IfIndexInterface> getInterfaceInfoEntriesOperationalDataPath(long interfaceTag) {
        return InstanceIdentifier.builder(IfIndexesInterfaceMap.class).child(IfIndexInterface.class,
                new IfIndexInterfaceKey((int) interfaceTag)).build();
    }

    public static ElanTagName getElanInfoByElanTag(DataBroker broker, long elanTag) {
        InstanceIdentifier<ElanTagName> elanId = getElanInfoEntriesOperationalDataPath(elanTag);
        Optional<ElanTagName> existingElanInfo = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, elanId);
        if (existingElanInfo.isPresent()) {
            return existingElanInfo.get();
        }
        return null;
    }

    private static InstanceIdentifier<ElanTagName> getElanInfoEntriesOperationalDataPath(long elanTag) {
        return InstanceIdentifier.builder(ElanTagNameMap.class).child(ElanTagName.class,
                new ElanTagNameKey(elanTag)).build();
    }


    // TODO: Move this to NwUtil
    public static boolean isIpInSubnet(int ipAddress, String subnetCidr) {
        String[] subSplit = subnetCidr.split("/");
        if (subSplit.length < 2) {
            return false;
        }

        String subnetStr = subSplit[0];
        int subnet = 0;
        try {
            InetAddress subnetAddress = InetAddress.getByName(subnetStr);
            subnet = Ints.fromByteArray(subnetAddress.getAddress());
        } catch (Exception ex) {
            LOG.error("Passed in Subnet IP string not convertible to InetAdddress " + subnetStr);
            return false;
        }
        int prefixLength = Integer.valueOf(subSplit[1]);
        int mask = -1 << (32 - prefixLength);
        if ((subnet & mask) == (ipAddress & mask)) {
            return true;
        }
        return false;
    }

    /**
     * Returns the Path identifier to reach a specific interface in a specific DPN in a given VpnInstance
     *
     * @param vpnRd     Route-Distinguisher of the VpnInstance
     * @param dpnId     Id of the DPN where the interface is
     * @param ifaceName Interface name
     * @return the Instance Identifier
     */
    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn
            .instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces>
    getVpnToDpnInterfacePath(String vpnRd, BigInteger dpnId, String ifaceName) {

        return
                InstanceIdentifier.builder(VpnInstanceOpData.class)
                        .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(vpnRd))
                        .child(VpnToDpnList.class, new VpnToDpnListKey(dpnId))
                        .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn
                                .instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces.class,
                                new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn
                                        .instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesKey(ifaceName))
                        .build();
    }

    public static void removePrefixToInterfaceForVpnId(DataBroker broker, long vpnId, WriteTransaction writeTxn) {
        try {
            // Clean up PrefixToInterface Operational DS
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(PrefixToInterface.class).child(
                                VpnIds.class, new VpnIdsKey(vpnId)).build());
            } else {
                delete(broker, LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(PrefixToInterface.class).child(VpnIds.class, new VpnIdsKey(vpnId)).build(),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during cleanup of PrefixToInterface for VPN ID {}", vpnId, e);
        }
    }

    public static void removeVpnExtraRouteForVpn(DataBroker broker, String vpnName, WriteTransaction writeTxn) {
        try {
            // Clean up VPNExtraRoutes Operational DS
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(VpnToExtraroute.class).child(Vpn.class, new VpnKey(vpnName)).build());
            } else {
                delete(broker, LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(VpnToExtraroute.class).child(Vpn.class, new VpnKey(vpnName)).build(),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during cleanup of VPNToExtraRoute for VPN {}", vpnName, e);
        }
    }

    public static void removeVpnOpInstance(DataBroker broker, String vpnName, WriteTransaction writeTxn) {
        try {
            // Clean up VPNInstanceOpDataEntry
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.OPERATIONAL, getVpnInstanceOpDataIdentifier(vpnName));
            } else {
                delete(broker, LogicalDatastoreType.OPERATIONAL, getVpnInstanceOpDataIdentifier(vpnName),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during cleanup of VPNInstanceOpDataEntry for VPN {}", vpnName, e);
        }
    }

    public static void removeVpnInstanceToVpnId(DataBroker broker, String vpnName, WriteTransaction writeTxn) {
        try {
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.CONFIGURATION, getVpnInstanceToVpnIdIdentifier(vpnName));
            } else {
                delete(broker, LogicalDatastoreType.CONFIGURATION, getVpnInstanceToVpnIdIdentifier(vpnName),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during clean up of VpnInstanceToVpnId for VPN {}", vpnName, e);
        }
    }

    public static void removeVpnIdToVpnInstance(DataBroker broker, long vpnId, WriteTransaction writeTxn) {
        try {
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.CONFIGURATION, getVpnIdToVpnInstanceIdentifier(vpnId));
            } else {
                delete(broker, LogicalDatastoreType.CONFIGURATION, getVpnIdToVpnInstanceIdentifier(vpnId),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during clean up of VpnIdToVpnInstance for VPNID {}", vpnId, e);
        }
    }

    public static void removeVrfTableForVpn(DataBroker broker, String vpnName, WriteTransaction writeTxn) {
        // Clean up FIB Entries Config DS
        try {
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.CONFIGURATION,
                        InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(vpnName)).build());
            } else {
                delete(broker, LogicalDatastoreType.CONFIGURATION,
                        InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(vpnName)).build(),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during clean up of VrfTable from FIB for VPN {}", vpnName, e);
        }
    }

    public static void removeL3nexthopForVpnId(DataBroker broker, long vpnId, WriteTransaction writeTxn) {
        try {
            // Clean up L3NextHop Operational DS
            if (writeTxn != null) {
                writeTxn.delete(LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(L3nexthop.class).child(VpnNexthops.class, new VpnNexthopsKey(vpnId)).build());
            } else {
                delete(broker, LogicalDatastoreType.OPERATIONAL,
                        InstanceIdentifier.builder(L3nexthop.class).child(VpnNexthops.class, new VpnNexthopsKey(vpnId)).build(),
                        DEFAULT_CALLBACK);
            }
        } catch (Exception e) {
            LOG.error("Exception during cleanup of L3NextHop for VPN ID {}", vpnId, e);
        }
    }

    public static void scheduleVpnInterfaceForRemoval(DataBroker broker,String interfaceName, BigInteger dpnId,
                                                      String vpnInstanceName, Boolean isScheduledToRemove,
                                                      WriteTransaction writeOperTxn){
        InstanceIdentifier<VpnInterface> interfaceId = VpnUtil.getVpnInterfaceIdentifier(interfaceName);
        VpnInterface interfaceToUpdate = new VpnInterfaceBuilder().setKey(new VpnInterfaceKey(interfaceName)).setName(interfaceName)
                .setDpnId(dpnId).setVpnInstanceName(vpnInstanceName).setScheduledForRemove(isScheduledToRemove).build();
        if (writeOperTxn != null) {
            writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL, interfaceId, interfaceToUpdate, true);
        } else {
            VpnUtil.syncUpdate(broker, LogicalDatastoreType.OPERATIONAL, interfaceId, interfaceToUpdate);
        }
    }

    public static boolean isNeutronPortConfigured(DataBroker broker, String portId,
                                                  org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress targetIP) {
        InstanceIdentifier<Port> portIdentifier = InstanceIdentifier.create(Neutron.class).
                child(Ports.class).child(Port.class, new PortKey(new Uuid(portId)));
        Optional<Port> optPort = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, portIdentifier);
        if (optPort.isPresent()) {
            Port port = optPort.get();
            for (FixedIps ip : port.getFixedIps()) {
                if (Objects.equals(ip.getIpAddress(), targetIP)) {
                    return true;
                }
            }
        }

        LOG.trace("No neutron ports found matching portId {} with targetIp {}", portId, targetIP);
        return false;
    }

    protected static void createVpnPortFixedIpToPort(DataBroker broker, String vpnName, String fixedIp, String
            portName, String macAddress, boolean isSubnetIp, boolean isConfig, boolean isLearnt) {
        synchronized ((vpnName + fixedIp).intern()) {
            InstanceIdentifier<VpnPortipToPort> id = buildVpnPortipToPortIdentifier(vpnName, fixedIp);
            VpnPortipToPortBuilder builder = new VpnPortipToPortBuilder().setKey(
                    new VpnPortipToPortKey(fixedIp, vpnName)).setVpnName(vpnName).setPortFixedip(fixedIp).setPortName
                    (portName).setMacAddress(macAddress.toLowerCase()).setSubnetIp(isSubnetIp).setConfig(isConfig)
                    .setLearnt(isLearnt);
            MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, id, builder.build());
            LOG.debug("ARP learned for fixedIp: {}, vpn {}, interface {}, mac {}, isSubnetIp {} added to " +
                    "VpnPortipToPort DS", fixedIp, vpnName, portName, macAddress, isLearnt);
        }
    }

    protected static void removeVpnPortFixedIpToPort(DataBroker broker, String vpnName, String fixedIp) {
        synchronized ((vpnName + fixedIp).intern()) {
            InstanceIdentifier<VpnPortipToPort> id = buildVpnPortipToPortIdentifier(vpnName, fixedIp);
            MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, id);
            LOG.debug("Delete learned ARP for fixedIp: {}, vpn {} removed from VpnPortipToPort DS", fixedIp, vpnName);
        }
    }

    static InstanceIdentifier<VpnPortipToPort> buildVpnPortipToPortIdentifier(String vpnName, String fixedIp) {
        InstanceIdentifier<VpnPortipToPort> id = InstanceIdentifier.builder(NeutronVpnPortipPortData.class).child
                (VpnPortipToPort.class, new VpnPortipToPortKey(fixedIp, vpnName)).build();
        return id;
    }

    static VpnPortipToPort getNeutronPortFromVpnPortFixedIp(DataBroker broker, String vpnName, String fixedIp) {
        InstanceIdentifier id = buildVpnPortipToPortIdentifier(vpnName, fixedIp);
        Optional<VpnPortipToPort> vpnPortipToPortData = read(broker, LogicalDatastoreType.OPERATIONAL, id);
        if (vpnPortipToPortData.isPresent()) {
            return (vpnPortipToPortData.get());
        }
        return null;
    }

    public static List<BigInteger> getDpnsOnVpn(DataBroker dataBroker, String vpnInstanceName) {
        List<BigInteger> result = new ArrayList<BigInteger>();
        String rd = getVpnRd(dataBroker, vpnInstanceName);
        if ( rd == null ) {
            LOG.debug("Could not find Route-Distinguisher for VpnName={}", vpnInstanceName);
            return result;
        }

        VpnInstanceOpDataEntry vpnInstanceOpData = getVpnInstanceOpData(dataBroker, rd);
        if ( vpnInstanceOpData == null ) {
            LOG.debug("Could not find OpState for VpnName={}", vpnInstanceName);
            return result;
        }

        List<VpnToDpnList> vpnToDpnList = vpnInstanceOpData.getVpnToDpnList();
        if ( vpnToDpnList == null ) {
            LOG.debug("Could not find DPN footprint for VpnName={}", vpnInstanceName);
            return result;
        }
        for ( VpnToDpnList vpnToDpn : vpnToDpnList) {
            result.add(vpnToDpn.getDpnId());
        }
        return result;
    }

    static String getAssociatedExternalNetwork(DataBroker dataBroker, String routerId) {
        InstanceIdentifier<Routers> id = buildRouterIdentifier(routerId);
        Optional<Routers> routerData = read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            Uuid networkId = routerData.get().getNetworkId();
            if(networkId != null) {
                return networkId.getValue();
            }
        }
        return null;
    }

    static InstanceIdentifier<Routers> buildRouterIdentifier(String routerId) {
        InstanceIdentifier<Routers> routerInstanceIndentifier = InstanceIdentifier.builder(ExtRouters.class).child
                (Routers.class, new RoutersKey(routerId)).build();
        return routerInstanceIndentifier;
    }

    static Networks getExternalNetwork(DataBroker dataBroker, Uuid networkId) {
        InstanceIdentifier<Networks> netsIdentifier = InstanceIdentifier.builder(ExternalNetworks.class)
                .child(Networks.class, new NetworksKey(networkId)).build();
        Optional<Networks> optionalNets = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, netsIdentifier);
        return optionalNets.isPresent() ? optionalNets.get() : null;
    }

    static Uuid getExternalNetworkVpnId(DataBroker dataBroker, Uuid networkId) {
        Networks extNetwork = getExternalNetwork(dataBroker, networkId);
        return extNetwork != null ? extNetwork.getVpnid() : null;
    }

    static List<Uuid> getExternalNetworkRouterIds(DataBroker dataBroker, Uuid networkId) {
        Networks extNetwork = getExternalNetwork(dataBroker, networkId);
        return extNetwork != null ? extNetwork.getRouterIds() : null;
    }

    static Routers getExternalRouter(DataBroker dataBroker, String routerId) {
        InstanceIdentifier<Routers> id = InstanceIdentifier.builder(ExtRouters.class)
                .child(Routers.class, new RoutersKey(routerId)).build();
        Optional<Routers> routerData = read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        return routerData.isPresent() ? routerData.get() : null;
    }

    static Optional<List<String>> getAllSubnetGatewayMacAddressesforVpn(DataBroker broker, String vpnName) {
        Optional<List<String>> macAddressesOptional = Optional.absent();
        List<String> macAddresses = new ArrayList<>();
        Optional<Subnetmaps> subnetMapsData = read(broker, LogicalDatastoreType.CONFIGURATION, buildSubnetMapsWildCardPath());
        if (subnetMapsData.isPresent()) {
            List<Subnetmap> subnetMapList = subnetMapsData.get().getSubnetmap();
            if (subnetMapList != null && !subnetMapList.isEmpty()) {
                for (Subnetmap subnet: subnetMapList) {
                    if (subnet.getVpnId() !=null && subnet.getVpnId().equals(Uuid.getDefaultInstance(vpnName))) {
                        String routerIntfMacAddress = subnet.getRouterIntfMacAddress();
                        if (routerIntfMacAddress != null && !routerIntfMacAddress.isEmpty()) {
                            macAddresses.add(subnet.getRouterIntfMacAddress());
                        }
                    }
                }
            }
            if (!macAddresses.isEmpty()) {
                return Optional.of(macAddresses);
            }
        }
        return macAddressesOptional;
    }

    static InstanceIdentifier<Subnetmaps> buildSubnetMapsWildCardPath() {
        return InstanceIdentifier.create(Subnetmaps.class);
    }

    static void setupSubnetMacIntoVpnInstance(DataBroker dataBroker, IMdsalApiManager mdsalManager,
            String vpnName, String srcMacAddress, BigInteger dpnId, WriteTransaction writeTx, int addOrRemove) {
        long vpnId = getVpnId(dataBroker, vpnName);
        if (dpnId.equals(BigInteger.ZERO)) {
            /* Apply the MAC on all DPNs in a VPN */
            List<BigInteger> dpIds = getDpnsOnVpn(dataBroker, vpnName);
            if (dpIds == null || dpIds.isEmpty()) {
                return;
            }
            for (BigInteger dpId : dpIds) {
                addGwMacIntoTx(mdsalManager, srcMacAddress, writeTx, addOrRemove, vpnId, dpId);
            }
        } else {
            addGwMacIntoTx(mdsalManager, srcMacAddress, writeTx, addOrRemove, vpnId, dpnId);
        }
    }

    static void addGwMacIntoTx(IMdsalApiManager mdsalManager, String srcMacAddress, WriteTransaction writeTx,
            int addOrRemove, long vpnId, BigInteger dpId) {
        FlowEntity flowEntity = buildL3vpnGatewayFlow(dpId, srcMacAddress, vpnId);
        if (addOrRemove == NwConstants.ADD_FLOW) {
            mdsalManager.addFlowToTx(flowEntity, writeTx);
        } else {
            mdsalManager.removeFlowToTx(flowEntity, writeTx);
        }
    }

    public static FlowEntity buildL3vpnGatewayFlow(BigInteger dpId, String gwMacAddress, long vpnId) {
        List<MatchInfo> mkMatches = new ArrayList<MatchInfo>();
        mkMatches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(vpnId), MetaDataUtil.METADATA_MASK_VRFID }));
        mkMatches.add(new MatchInfo(MatchFieldType.eth_dst, new String[] { gwMacAddress }));
        List<InstructionInfo> mkInstructions = new ArrayList<InstructionInfo>();
        mkInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.L3_FIB_TABLE }));
        String flowId = getL3VpnGatewayFlowRef(NwConstants.L3_GW_MAC_TABLE, dpId, vpnId, gwMacAddress);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_GW_MAC_TABLE,
                flowId, 20, flowId, 0, 0, NwConstants.COOKIE_L3_GW_MAC_TABLE, mkMatches, mkInstructions);
        return flowEntity;
    }

    private static String getL3VpnGatewayFlowRef(short l3GwMacTable, BigInteger dpId, long vpnId, String gwMacAddress) {
        return gwMacAddress+NwConstants.FLOWID_SEPARATOR+vpnId+NwConstants.FLOWID_SEPARATOR+dpId+NwConstants.FLOWID_SEPARATOR+l3GwMacTable;
    }

    public static void lockSubnet(LockManagerService lockManager, String subnetId) {
        TryLockInput input = new TryLockInputBuilder().setLockName(subnetId).setTime(3000L).setTimeUnit(TimeUnits.Milliseconds).build();
        Future<RpcResult<Void>> result = lockManager.tryLock(input);
        String errMsg = "Unable to getLock for subnet " + subnetId;
        try {
            if ((result != null) && (result.get().isSuccessful())) {
                    LOG.debug("Acquired lock for {}", subnetId);
            } else {
                throw new RuntimeException(errMsg);
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error(errMsg);
            throw new RuntimeException(errMsg, e.getCause());
        }
    }

    public static void unlockSubnet(LockManagerService lockManager, String subnetId) {
        UnlockInput input = new UnlockInputBuilder().setLockName(subnetId).build();
        Future<RpcResult<Void>> result = lockManager.unlock(input);
        try {
            if ((result != null) && (result.get().isSuccessful())) {
                LOG.debug("Unlocked {}", subnetId);
            } else {
                LOG.debug("Unable to unlock subnet {}", subnetId);
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Unable to unlock subnet {}", subnetId);
            throw new RuntimeException(String.format("Unable to unlock subnetId %s", subnetId), e.getCause());
        }
    }

    static Optional<IpAddress> getGatewayIpAddressFromInterface(String srcInterface,
            INeutronVpnManager neutronVpnService, DataBroker dataBroker) {
        Optional <IpAddress> gatewayIp = Optional.absent();
        if (neutronVpnService != null) {
            //TODO(Gobinath): Need to fix this as assuming port will belong to only one Subnet would be incorrect"
            Port port = neutronVpnService.getNeutronPort(srcInterface);
            if (port != null && port.getFixedIps() != null && port.getFixedIps().get(0) != null && port.getFixedIps().get(0).getSubnetId() != null) {
                gatewayIp = Optional.of(neutronVpnService.getNeutronSubnet(port.getFixedIps().get(0).getSubnetId()).getGatewayIp());
            }
        } else {
            LOG.debug("neutron vpn service is not configured");
        }
        return gatewayIp;
    }

    static Optional<String> getGWMacAddressFromInterface(MacEntry macEntry, IpAddress gatewayIp,
            DataBroker dataBroker, OdlInterfaceRpcService interfaceRpc) {
        Optional <String> gatewayMac = Optional.absent();
        long vpnId = getVpnId(dataBroker, macEntry.getVpnName());
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds>
        vpnIdsInstanceIdentifier = VpnUtil.getVpnIdToVpnInstanceIdentifier(vpnId);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds> vpnIdsOptional
        = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIdsInstanceIdentifier);
        if (!vpnIdsOptional.isPresent()) {
            LOG.trace("VPN {} not configured", vpnId);
            return gatewayMac;
        }
        VpnPortipToPort vpnTargetIpToPort = VpnUtil.getNeutronPortFromVpnPortFixedIp(dataBroker,
                macEntry.getVpnName(), gatewayIp.getIpv4Address().getValue());
        if (vpnTargetIpToPort != null && vpnTargetIpToPort.isSubnetIp()) {
            gatewayMac = Optional.of(vpnTargetIpToPort.getMacAddress());
        } else {
            org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds vpnIds = vpnIdsOptional.get();
            if(vpnIds.isExternalVpn()) {
                gatewayMac = InterfaceUtils.getMacAddressForInterface(dataBroker, macEntry.getInterfaceName());
            }
        }
        return gatewayMac;

    }

    public static boolean isVpnIntfPresentInVpnToDpnList(DataBroker broker, VpnInterface vpnInterface) {
        BigInteger dpnId = vpnInterface.getDpnId();
        String rd = VpnUtil.getVpnRd(broker, vpnInterface.getVpnInstanceName());
        VpnInstanceOpDataEntry vpnInstanceOpData = VpnUtil.getVpnInstanceOpDataFromCache(broker, rd);
        if (vpnInstanceOpData != null) {
            List<VpnToDpnList> dpnToVpns = vpnInstanceOpData.getVpnToDpnList();
            if (dpnToVpns != null) {
                for (VpnToDpnList dpn : dpnToVpns) {
                    if (dpn.getDpnId().equals(dpnId)) {
                        if (dpn.getVpnInterfaces().contains(vpnInterface.getName())) {
                            return true;
                        } else {
                            return false;
                        }
                    }
                }
            }
        }
        return false;
    }

    public static void setupGwMacIfExternalVpn(DataBroker dataBroker, IMdsalApiManager mdsalManager, BigInteger dpnId, String interfaceName, long vpnId,
            WriteTransaction writeInvTxn, int addOrRemove) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds> vpnIdsInstanceIdentifier =
                getVpnIdToVpnInstanceIdentifier(vpnId);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds> vpnIdsOptional = read(dataBroker,
                LogicalDatastoreType.CONFIGURATION, vpnIdsInstanceIdentifier);
        if (vpnIdsOptional.isPresent() && vpnIdsOptional.get().isExternalVpn()) {
            Optional<String> gwMacAddressOptional = InterfaceUtils.getMacAddressForInterface(dataBroker, interfaceName);
            if (!gwMacAddressOptional.isPresent()) {
                LOG.error("Failed to get gwMacAddress for interface {}", interfaceName);
                return;
            }
            String gwMacAddress = gwMacAddressOptional.get();
            FlowEntity flowEntity = VpnUtil.buildL3vpnGatewayFlow(dpnId, gwMacAddress, vpnId);
            if (addOrRemove == NwConstants.ADD_FLOW) {
                mdsalManager.addFlowToTx(flowEntity, writeInvTxn);
            } else if (addOrRemove == NwConstants.DEL_FLOW) {
                mdsalManager.removeFlowToTx(flowEntity, writeInvTxn);
            }
        }
    }

    public static Optional<VpnPortipToPort> getRouterInterfaceForVpnInterface(DataBroker dataBroker,
                                                                              String interfaceName,
                                                                              String vpnName,
                                                                              Uuid subnetUuid) {
        Optional<VpnPortipToPort> gwPortOptional = Optional.absent();
        if (subnetUuid != null) {
            final Optional<String> gatewayIp = getVpnSubnetGatewayIp(dataBroker, subnetUuid);
            if (gatewayIp.isPresent()) {
                String gwIp = gatewayIp.get();
                gwPortOptional = Optional.fromNullable(getNeutronPortFromVpnPortFixedIp(dataBroker, vpnName, gwIp));
            }
        }
        return gwPortOptional;
    }

    public static Optional<String> getVpnSubnetGatewayIp(DataBroker dataBroker, final Uuid subnetUuid) {
        Optional<String> gwIpAddress = Optional.absent();
        final SubnetKey subnetkey = new SubnetKey(subnetUuid);
        final InstanceIdentifier<Subnet> subnetidentifier = InstanceIdentifier.create(Neutron.class)
                .child(Subnets.class)
                .child(Subnet.class, subnetkey);
        final Optional<Subnet> subnet = read(dataBroker, LogicalDatastoreType.CONFIGURATION, subnetidentifier);
        if (subnet.isPresent()) {
            Class<? extends IpVersionBase> ipVersionBase = subnet.get().getIpVersion();
            if (ipVersionBase.equals(IpVersionV4.class)) {
                LOG.trace("Obtained subnet {} for vpn interface", subnet.get().getUuid().getValue());
                gwIpAddress = Optional.of(subnet.get().getGatewayIp().getIpv4Address().getValue());
                return gwIpAddress;
            }
        }
        return gwIpAddress;
    }

    public static RouterToNaptSwitch getRouterToNaptSwitch(DataBroker dataBroker, String routerName) {
        InstanceIdentifier<RouterToNaptSwitch> id = InstanceIdentifier.builder(NaptSwitches.class)
                .child(RouterToNaptSwitch.class, new RouterToNaptSwitchKey(routerName)).build();
        Optional<RouterToNaptSwitch> routerToNaptSwitchData = read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        return routerToNaptSwitchData.isPresent() ? routerToNaptSwitchData.get() : null;
    }

    public static BigInteger getPrimarySwitchForRouter(DataBroker dataBroker, String routerName) {
        RouterToNaptSwitch routerToNaptSwitch = getRouterToNaptSwitch(dataBroker, routerName);
        return routerToNaptSwitch != null ? routerToNaptSwitch.getPrimarySwitchId() : null;
    }

    static boolean isL3VpnOverVxLan(Long l3Vni) {
        return (l3Vni != null && l3Vni != 0);
    }

    static   String getGatewayMac(String interfaceName) {
        //OUI based MAC creation and use
        return VpnConstants.DEFAULT_GATEWAY_MAC_ADDRESS;
    }

}
