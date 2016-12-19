/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn;

import com.google.common.base.Optional;
import java.util.Iterator;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.tuple.ImmutablePair;
import com.google.common.collect.ImmutableBiMap;
import com.google.common.collect.Sets;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.FloatingIpPortInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProviderTypes;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeFlat;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeVlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.NeutronRouterDpns;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExtRouters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.RoutersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.binding.rev150712.PortBindingExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.ext.rev150712.NetworkL3Extension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.Router;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.RouterKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeFlat;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.NetworkKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.portsecurity.rev150712.PortSecurityExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.qos.rev160613.qos.attributes.qos.policies.QosPolicy;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.SubnetKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NetworkMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.VpnMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinkStates;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkStateKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.IpPrefixOrAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.InterfaceAclBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairsBuilder;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronvpnUtils {

    private static final Logger logger = LoggerFactory.getLogger(NeutronvpnUtils.class);
    private static final ImmutableBiMap<Class<? extends NetworkTypeBase>, Class<? extends SegmentTypeBase>> NETWORK_MAP =
            new ImmutableBiMap.Builder<Class<? extends NetworkTypeBase>, Class<? extends SegmentTypeBase>>()
            .put(NetworkTypeFlat.class, SegmentTypeFlat.class)
            .put(NetworkTypeGre.class, SegmentTypeGre.class)
            .put(NetworkTypeVlan.class, SegmentTypeVlan.class)
            .put(NetworkTypeVxlan.class, SegmentTypeVxlan.class)
            .build();

    public static ConcurrentHashMap<Uuid, Network> networkMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, Router> routerMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, Port> portMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, Subnet> subnetMap = new ConcurrentHashMap<>();
    public static Map<IpAddress, Set<Uuid>> subnetGwIpMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, QosPolicy> qosPolicyMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, HashMap<Uuid, Port>> qosPortsMap = new ConcurrentHashMap<>();
    public static ConcurrentHashMap<Uuid, HashMap<Uuid, Network>> qosNetworksMap = new ConcurrentHashMap<>();
    private static final Set<Class<? extends NetworkTypeBase>> supportedNetworkTypes = Sets.newConcurrentHashSet();

    private static long LOCK_WAIT_TIME = 10L;
    private static TimeUnit secUnit = TimeUnit.SECONDS;

    static {
        registerSuppoprtedNetworkType(NetworkTypeFlat.class);
        registerSuppoprtedNetworkType(NetworkTypeVlan.class);
        registerSuppoprtedNetworkType(NetworkTypeVxlan.class);
        registerSuppoprtedNetworkType(NetworkTypeGre.class);
    }

    private NeutronvpnUtils() {
        throw new UnsupportedOperationException("Utility class should not be instantiated");
    }

    static ConcurrentHashMap<String, ImmutablePair<ReadWriteLock,AtomicInteger>> locks = new ConcurrentHashMap<>();

    public static void registerSuppoprtedNetworkType(Class<? extends NetworkTypeBase> netType) {
        supportedNetworkTypes.add(netType);
    }

    public static void unregisterSuppoprtedNetworkType(Class<? extends NetworkTypeBase> netType) {
        supportedNetworkTypes.remove(netType);
    }

    protected static Subnetmap getSubnetmap(DataBroker broker, Uuid subnetId) {
        InstanceIdentifier id = buildSubnetMapIdentifier(subnetId);
        Optional<Subnetmap> sn = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        if (sn.isPresent()) {
            return sn.get();
        }
        return null;
    }

    protected static VpnMap getVpnMap(DataBroker broker, Uuid id) {
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class).child(VpnMap.class,
                new VpnMapKey(id)).build();
        Optional<VpnMap> optionalVpnMap = read(broker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier);
        if (optionalVpnMap.isPresent()) {
            return optionalVpnMap.get();
        }
        logger.error("getVpnMap failed, VPN {} not present", id.getValue());
        return null;
    }

    protected static Uuid getVpnForNetwork(DataBroker broker, Uuid network) {
        InstanceIdentifier<VpnMaps> vpnMapsIdentifier = InstanceIdentifier.builder(VpnMaps.class).build();
        Optional<VpnMaps> optionalVpnMaps = read(broker, LogicalDatastoreType.CONFIGURATION, vpnMapsIdentifier);
        if (optionalVpnMaps.isPresent() && optionalVpnMaps.get().getVpnMap() != null) {
            List<VpnMap> allMaps = optionalVpnMaps.get().getVpnMap();
            for (VpnMap vpnMap : allMaps) {
                List<Uuid> netIds = vpnMap.getNetworkIds();
                if (netIds != null && netIds.contains(network)) {
                    return vpnMap.getVpnId();
                }
            }
        }
        return null;
    }

    protected static Uuid getVpnForSubnet(DataBroker broker, Uuid subnetId) {
        InstanceIdentifier<Subnetmap> subnetmapIdentifier = buildSubnetMapIdentifier(subnetId);
        Optional<Subnetmap> optionalSubnetMap = read(broker, LogicalDatastoreType.CONFIGURATION, subnetmapIdentifier);
        if (optionalSubnetMap.isPresent()) {
            return optionalSubnetMap.get().getVpnId();
        }
        return null;
    }

    // @param external vpn - true if external vpn being fetched, false for internal vpn
    protected static Uuid getVpnForRouter(DataBroker broker, Uuid routerId, Boolean externalVpn) {
        InstanceIdentifier<VpnMaps> vpnMapsIdentifier = InstanceIdentifier.builder(VpnMaps.class).build();
        Optional<VpnMaps> optionalVpnMaps = read(broker, LogicalDatastoreType.CONFIGURATION, vpnMapsIdentifier);
        if (optionalVpnMaps.isPresent() && optionalVpnMaps.get().getVpnMap() != null) {
            List<VpnMap> allMaps = optionalVpnMaps.get().getVpnMap();
            if (routerId != null) {
                for (VpnMap vpnMap : allMaps) {
                    if (routerId.equals(vpnMap.getRouterId())) {
                        if (externalVpn) {
                            if (!routerId.equals(vpnMap.getVpnId())) {
                                return vpnMap.getVpnId();
                            }
                        } else {
                            if (routerId.equals(vpnMap.getVpnId())) {
                                return vpnMap.getVpnId();
                            }
                        }
                    }
                }
            }
        }
        return null;
    }

    protected static Uuid getRouterforVpn(DataBroker broker, Uuid vpnId) {
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class).child(VpnMap.class,
                new VpnMapKey(vpnId)).build();
        Optional<VpnMap> optionalVpnMap = read(broker, LogicalDatastoreType.CONFIGURATION, vpnMapIdentifier);
        if (optionalVpnMap.isPresent()) {
            VpnMap vpnMap = optionalVpnMap.get();
            return vpnMap.getRouterId();
        }
        return null;
    }

    protected static String getNeutronPortNameFromVpnPortFixedIp(DataBroker broker, String vpnName, String fixedIp) {
        InstanceIdentifier id = buildVpnPortipToPortIdentifier(vpnName, fixedIp);
        Optional<VpnPortipToPort> vpnPortipToPortData = read(broker, LogicalDatastoreType.OPERATIONAL, id);
        if (vpnPortipToPortData.isPresent()) {
            return vpnPortipToPortData.get().getPortName();
        }
        return null;
    }

    protected static String getNeutronPortMacFromVpnPortFixedIp(DataBroker broker, String vpnName, String fixedIp) {
        InstanceIdentifier id = buildVpnPortipToPortIdentifier(vpnName, fixedIp);
        Optional<VpnPortipToPort> vpnPortipToPortData = read(broker, LogicalDatastoreType.OPERATIONAL, id);
        if (vpnPortipToPortData.isPresent()) {
            return vpnPortipToPortData.get().getMacAddress();
        }
        return null;
    }

    protected static List<Uuid> getSubnetIdsFromNetworkId(DataBroker broker, Uuid networkId) {
        InstanceIdentifier id = buildNetworkMapIdentifier(networkId);
        Optional<NetworkMap> optionalNetworkMap = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (optionalNetworkMap.isPresent()) {
            return optionalNetworkMap.get().getSubnetIdList();
        }
        return null;
    }

    protected static List<Uuid> getPortIdsFromSubnetId(DataBroker broker, Uuid subnetId) {
        InstanceIdentifier id = buildSubnetMapIdentifier(subnetId);
        Optional<Subnetmap> optionalSubnetmap = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (optionalSubnetmap.isPresent()) {
            return optionalSubnetmap.get().getPortList();
        }
        return null;
    }

    protected static Router getNeutronRouter(DataBroker broker, Uuid routerId) {
        Router router = null;
        router = routerMap.get(routerId);
        if (router != null) {
            return router;
        }
        InstanceIdentifier<Router> inst = InstanceIdentifier.create(Neutron.class).child(Routers.class).child(Router
                .class, new RouterKey(routerId));
        Optional<Router> rtr = read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (rtr.isPresent()) {
            router = rtr.get();
        }
        return router;
    }

    protected static Network getNeutronNetwork(DataBroker broker, Uuid networkId) {
        Network network = null;
        network = networkMap.get(networkId);
        if (network != null) {
            return network;
        }
        logger.debug("getNeutronNetwork for {}", networkId.getValue());
        InstanceIdentifier<Network> inst = InstanceIdentifier.create(Neutron.class).child(Networks.class).child
                (Network.class, new NetworkKey(networkId));
        Optional<Network> net = read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (net.isPresent()) {
            network = net.get();
        }
        return network;
    }

    protected static Port getNeutronPort(DataBroker broker, Uuid portId) {
        Port prt = null;
        prt = portMap.get(portId);
        if (prt != null) {
            return prt;
        }
        logger.debug("getNeutronPort for {}", portId.getValue());
        InstanceIdentifier<Port> inst = InstanceIdentifier.create(Neutron.class).child(Ports.class).child(Port.class,
                new PortKey(portId));
        Optional<Port> port = read(broker, LogicalDatastoreType.CONFIGURATION, inst);
        if (port.isPresent()) {
            prt = port.get();
        }
        return prt;
    }

    /**
     * Returns port_security_enabled status with the port.
     *
     * @param port the port
     * @return port_security_enabled status
     */
    protected static Boolean getPortSecurityEnabled(Port port) {
        String deviceOwner = port.getDeviceOwner();
        if (deviceOwner != null && deviceOwner.startsWith("network:")) {
            // port with device owner of network:xxx is created by
            // neutorn for its internal use. So security group doesn't apply.
            // router interface, dhcp port and floating ip.
            return false;
        }
        PortSecurityExtension portSecurity = port.getAugmentation(PortSecurityExtension.class);
        if (portSecurity != null) {
            return portSecurity.isPortSecurityEnabled();
        }
        return false;
    }

    /**
     * Gets security group UUIDs delta   .
     *
     * @param port1SecurityGroups the port 1 security groups
     * @param port2SecurityGroups the port 2 security groups
     * @return the security groups delta
     */
    protected static List<Uuid> getSecurityGroupsDelta(List<Uuid> port1SecurityGroups,
            List<Uuid> port2SecurityGroups) {
        if (port1SecurityGroups == null) {
            return null;
        }

        if (port2SecurityGroups == null) {
            return port1SecurityGroups;
        }

        List<Uuid> list1 = new ArrayList<>(port1SecurityGroups);
        List<Uuid> list2 = new ArrayList<>(port2SecurityGroups);
        for (Iterator<Uuid> iterator = list1.iterator(); iterator.hasNext();) {
            Uuid securityGroup1 = iterator.next();
            for (Uuid securityGroup2 : list2) {
                if (securityGroup1.getValue().equals(securityGroup2.getValue())) {
                    iterator.remove();
                    break;
                }
            }
        }
        return list1;
    }

    /**
     * Gets the fixed ips delta.
     *
     * @param port1FixedIps the port 1 fixed ips
     * @param port2FixedIps the port 2 fixed ips
     * @return the fixed ips delta
     */
    protected static List<FixedIps> getFixedIpsDelta(List<FixedIps> port1FixedIps, List<FixedIps> port2FixedIps) {
        if (port1FixedIps == null) {
            return null;
        }

        if (port2FixedIps == null) {
            return port1FixedIps;
        }

        List<FixedIps> list1 = new ArrayList<>(port1FixedIps);
        List<FixedIps> list2 = new ArrayList<>(port2FixedIps);
        for (Iterator<FixedIps> iterator = list1.iterator(); iterator.hasNext();) {
            FixedIps fixedIps1 = iterator.next();
            for (FixedIps fixedIps2 : list2) {
                if (fixedIps1.getIpAddress().equals(fixedIps2.getIpAddress())) {
                    iterator.remove();
                    break;
                }
            }
        }
        return list1;
    }

    /**
     * Gets the allowed address pairs delta.
     *
     * @param port1AllowedAddressPairs the port 1 allowed address pairs
     * @param port2AllowedAddressPairs the port 2 allowed address pairs
     * @return the allowed address pairs delta
     */
    protected static List<AllowedAddressPairs> getAllowedAddressPairsDelta(
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> port1AllowedAddressPairs,
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> port2AllowedAddressPairs) {
        if (port1AllowedAddressPairs == null) {
            return null;
        }

        if (port2AllowedAddressPairs == null) {
            return getAllowedAddressPairsForAclService(port1AllowedAddressPairs);
        }

        List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> list1 =
                new ArrayList<>(port1AllowedAddressPairs);
        List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> list2 =
                new ArrayList<>(port2AllowedAddressPairs);
        for (Iterator<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> iterator =
             list1.iterator(); iterator.hasNext();) {
            org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs allowedAddressPair1 =
                    iterator.next();
            for (org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs allowedAddressPair2 : list2) {
                if (allowedAddressPair1.getKey().equals(allowedAddressPair2.getKey())) {
                    iterator.remove();
                    break;
                }
            }
        }
        return getAllowedAddressPairsForAclService(list1);
    }

    /**
     * Gets the acl allowed address pairs.
     *
     * @param macAddress the mac address
     * @param ipAddress the ip address
     * @return the acl allowed address pairs
     */
    protected static AllowedAddressPairs getAclAllowedAddressPairs(MacAddress macAddress,
            org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.types.rev160517.IpPrefixOrAddress ipAddress) {
        AllowedAddressPairsBuilder aclAllowedAdressPairBuilder = new AllowedAddressPairsBuilder();
        aclAllowedAdressPairBuilder.setMacAddress(macAddress);
        if (ipAddress != null && ipAddress.getValue() != null) {
            if (ipAddress.getIpPrefix() != null) {
                aclAllowedAdressPairBuilder.setIpAddress(new IpPrefixOrAddress(ipAddress.getIpPrefix()));
            } else {
                aclAllowedAdressPairBuilder.setIpAddress(new IpPrefixOrAddress(ipAddress.getIpAddress()));
            }
        }
        return aclAllowedAdressPairBuilder.build();
    }

    /**
     * Gets the allowed address pairs for acl service.
     *
     * @param macAddress the mac address
     * @param fixedIps the fixed ips
     * @return the allowed address pairs for acl service
     */
    protected static List<AllowedAddressPairs> getAllowedAddressPairsForAclService(MacAddress macAddress,
            List<FixedIps> fixedIps) {
        List<AllowedAddressPairs> aclAllowedAddressPairs = new ArrayList<>();
        for (FixedIps fixedIp : fixedIps) {
            aclAllowedAddressPairs.add(getAclAllowedAddressPairs(macAddress,
                    new org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.types.rev160517.IpPrefixOrAddress(
                            fixedIp.getIpAddress().getValue())));
        }
        return aclAllowedAddressPairs;
    }

    /**
     * Gets the IPv6 Link Local Address corresponding to the MAC Address.
     *
     * @param macAddress the mac address
     * @return the allowed address pairs for acl service which includes the MAC + IPv6LLA
     */
    protected static AllowedAddressPairs updateIPv6LinkLocalAddressForAclService(MacAddress macAddress) {
        IpAddress ipv6LinkLocalAddress = getIpv6LinkLocalAddressFromMac(macAddress);
        return getAclAllowedAddressPairs(macAddress,
                new org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.types.rev160517.IpPrefixOrAddress(
                        ipv6LinkLocalAddress.getValue()));
    }

    /**
     * Gets the allowed address pairs for acl service.
     *
     * @param portAllowedAddressPairs the port allowed address pairs
     * @return the allowed address pairs for acl service
     */
    protected static List<AllowedAddressPairs> getAllowedAddressPairsForAclService(
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes
                .AllowedAddressPairs> portAllowedAddressPairs) {
        List<AllowedAddressPairs> aclAllowedAddressPairs = new ArrayList<>();
        for (org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs
                portAllowedAddressPair : portAllowedAddressPairs) {
            aclAllowedAddressPairs.add(getAclAllowedAddressPairs(portAllowedAddressPair.getMacAddress(),
                    portAllowedAddressPair.getIpAddress()));
        }
        return aclAllowedAddressPairs;
    }

    /**
     * Gets the updated security groups.
     *
     * @param aclInterfaceSecurityGroups the acl interface security groups
     * @param origSecurityGroups the orig security groups
     * @param newSecurityGroups the new security groups
     * @return the updated security groups
     */
    protected static List<Uuid> getUpdatedSecurityGroups(List<Uuid> aclInterfaceSecurityGroups,
            List<Uuid> origSecurityGroups, List<Uuid> newSecurityGroups) {
        List<Uuid> addedGroups = getSecurityGroupsDelta(newSecurityGroups, origSecurityGroups);
        List<Uuid> deletedGroups = getSecurityGroupsDelta(origSecurityGroups, newSecurityGroups);
        List<Uuid> updatedSecurityGroups =
                aclInterfaceSecurityGroups != null ? new ArrayList<>(aclInterfaceSecurityGroups) : new ArrayList<>();
        if (addedGroups != null) {
            updatedSecurityGroups.addAll(addedGroups);
        }
        if (deletedGroups != null) {
            updatedSecurityGroups.removeAll(deletedGroups);
        }
        return updatedSecurityGroups;
    }

    /**
     * Gets the allowed address pairs for fixed ips.
     *
     * @param aclInterfaceAllowedAddressPairs the acl interface allowed address pairs
     * @param portMacAddress the port mac address
     * @param origFixedIps the orig fixed ips
     * @param newFixedIps the new fixed ips
     * @return the allowed address pairs for fixed ips
     */
    protected static List<AllowedAddressPairs> getAllowedAddressPairsForFixedIps(
            List<AllowedAddressPairs> aclInterfaceAllowedAddressPairs, MacAddress portMacAddress,
            List<FixedIps> origFixedIps, List<FixedIps> newFixedIps) {
        List<FixedIps> addedFixedIps = getFixedIpsDelta(newFixedIps, origFixedIps);
        List<FixedIps> deletedFixedIps = getFixedIpsDelta(origFixedIps, newFixedIps);
        List<AllowedAddressPairs> updatedAllowedAddressPairs = aclInterfaceAllowedAddressPairs != null ?
                new ArrayList<>(aclInterfaceAllowedAddressPairs) : new ArrayList<>();
        if (deletedFixedIps != null) {
            updatedAllowedAddressPairs.removeAll(getAllowedAddressPairsForAclService(portMacAddress, deletedFixedIps));
        }
        if (addedFixedIps != null) {
            updatedAllowedAddressPairs.addAll(getAllowedAddressPairsForAclService(portMacAddress, addedFixedIps));
        }
        return updatedAllowedAddressPairs;
    }

    /**
     * Gets the updated allowed address pairs.
     *
     * @param aclInterfaceAllowedAddressPairs the acl interface allowed address pairs
     * @param origAllowedAddressPairs the orig allowed address pairs
     * @param newAllowedAddressPairs the new allowed address pairs
     * @return the updated allowed address pairs
     */
    protected static List<AllowedAddressPairs> getUpdatedAllowedAddressPairs(
            List<AllowedAddressPairs> aclInterfaceAllowedAddressPairs,
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> origAllowedAddressPairs,
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs> newAllowedAddressPairs) {
        List<AllowedAddressPairs> addedAllowedAddressPairs = getAllowedAddressPairsDelta(newAllowedAddressPairs,
                origAllowedAddressPairs);
        List<AllowedAddressPairs> deletedAllowedAddressPairs = getAllowedAddressPairsDelta(origAllowedAddressPairs,
                newAllowedAddressPairs);
        List<AllowedAddressPairs> updatedAllowedAddressPairs = aclInterfaceAllowedAddressPairs != null ?
                new ArrayList<>(aclInterfaceAllowedAddressPairs) : new ArrayList<>();
        if (addedAllowedAddressPairs != null) {
            updatedAllowedAddressPairs.addAll(addedAllowedAddressPairs);
        }
        if (deletedAllowedAddressPairs != null) {
            updatedAllowedAddressPairs.removeAll(deletedAllowedAddressPairs);
        }
        return updatedAllowedAddressPairs;
    }

    /**
     * Populate interface acl builder.
     *
     * @param interfaceAclBuilder the interface acl builder
     * @param port the port
     */
    protected static void populateInterfaceAclBuilder(InterfaceAclBuilder interfaceAclBuilder, Port port) {
        // Handle security group enabled
        List<Uuid> securityGroups = port.getSecurityGroups();
        if (securityGroups != null) {
                interfaceAclBuilder.setSecurityGroups(securityGroups);
        }
        List<AllowedAddressPairs> aclAllowedAddressPairs = NeutronvpnUtils.getAllowedAddressPairsForAclService(
                port.getMacAddress(), port.getFixedIps());
        // Update the allowed address pair with the IPv6 LLA that is auto configured on the port.
        aclAllowedAddressPairs.add(NeutronvpnUtils.updateIPv6LinkLocalAddressForAclService(port.getMacAddress()));
        List<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.AllowedAddressPairs>
            portAllowedAddressPairs = port.getAllowedAddressPairs();
        if (portAllowedAddressPairs != null) {
            aclAllowedAddressPairs.addAll(NeutronvpnUtils.getAllowedAddressPairsForAclService(portAllowedAddressPairs));
        }
        interfaceAclBuilder.setAllowedAddressPairs(aclAllowedAddressPairs);
    }

    protected static Subnet getNeutronSubnet(DataBroker broker, Uuid subnetId) {
        Subnet subnet = null;
        subnet = subnetMap.get(subnetId);
        if (subnet != null) {
            return subnet;
        }
        InstanceIdentifier<Subnet> inst = InstanceIdentifier.create(Neutron.class).child(Subnets.class).child(Subnet
                .class, new SubnetKey(subnetId));
        Optional<Subnet> sn = read(broker, LogicalDatastoreType.CONFIGURATION, inst);

        if (sn.isPresent()) {
            subnet = sn.get();
        }
        return subnet;
    }

    protected static List<Uuid> getNeutronRouterSubnetIds(DataBroker broker, Uuid routerId) {
        logger.debug("getNeutronRouterSubnetIds for {}", routerId.getValue());
        List<Uuid> subnetIdList = new ArrayList<>();
        Optional<Subnetmaps> subnetMaps = read(broker, LogicalDatastoreType.CONFIGURATION, InstanceIdentifier.builder
                (Subnetmaps.class).build());
        if (subnetMaps.isPresent() && subnetMaps.get().getSubnetmap() != null) {
            for (Subnetmap subnetmap : subnetMaps.get().getSubnetmap()) {
                if (routerId.equals(subnetmap.getRouterId())) {
                    subnetIdList.add(subnetmap.getId());
                }
            }
        }
        logger.debug("returning from getNeutronRouterSubnetIds for {}", routerId.getValue());
        return subnetIdList;
    }

    protected static String getVifPortName(Port port) {
        if (port == null || port.getUuid() == null) {
            logger.warn("Invalid Neutron port {}", port);
            return null;
        }
        String tapId = port.getUuid().getValue().substring(0, 11);
        String portNamePrefix = getPortNamePrefix(port);
        if (portNamePrefix != null) {
            return new StringBuilder().append(portNamePrefix).append(tapId).toString();
        }
        logger.debug("Failed to get prefix for port {}", port.getUuid());
        return null;
    }

    protected static String getPortNamePrefix(Port port) {
        PortBindingExtension portBinding = port.getAugmentation(PortBindingExtension.class);
        if (portBinding == null || portBinding.getVifType() == null) {
            return null;
        }
        switch (portBinding.getVifType()) {
            case NeutronConstants.VIF_TYPE_VHOSTUSER:
                return NeutronConstants.PREFIX_VHOSTUSER;
            case NeutronConstants.VIF_TYPE_OVS:
            case NeutronConstants.VIF_TYPE_DISTRIBUTED:
            case NeutronConstants.VIF_TYPE_BRIDGE:
            case NeutronConstants.VIF_TYPE_OTHER:
            case NeutronConstants.VIF_TYPE_MACVTAP:
                return NeutronConstants.PREFIX_TAP;
            case NeutronConstants.VIF_TYPE_UNBOUND:
            case NeutronConstants.VIF_TYPE_BINDING_FAILED:
            default:
                return null;
        }
    }

    protected static boolean isPortVifTypeUpdated(Port original, Port updated) {
        return getPortNamePrefix(original) == null && getPortNamePrefix(updated) != null;
    }

    protected static boolean lock(String lockName) {
        if (locks.get(lockName) != null) {
            synchronized (locks) {
                if (locks.get(lockName) == null) {
                    locks.putIfAbsent(lockName, new ImmutablePair<ReadWriteLock, AtomicInteger>(new
                            ReentrantReadWriteLock(), new AtomicInteger(0)));
                }
                locks.get(lockName).getRight().incrementAndGet();
            }
            try {
                if (locks.get(lockName) != null) {
                    locks.get(lockName).getLeft().writeLock().tryLock(LOCK_WAIT_TIME, secUnit);
                }
            } catch (InterruptedException e) {
                locks.get(lockName).getRight().decrementAndGet();
                logger.error("Unable to acquire lock for  {}", lockName);
                throw new RuntimeException(String.format("Unable to acquire lock for %s", lockName), e.getCause());
            }
        } else {
            locks.putIfAbsent(lockName, new ImmutablePair<ReadWriteLock, AtomicInteger>(new ReentrantReadWriteLock(),
                    new AtomicInteger(0)));
            locks.get(lockName).getRight().incrementAndGet();
            try {
                locks.get(lockName).getLeft().writeLock().tryLock(LOCK_WAIT_TIME, secUnit);
            } catch (Exception e) {
                locks.get(lockName).getRight().decrementAndGet();
                logger.error("Unable to acquire lock for  {}", lockName);
                throw new RuntimeException(String.format("Unable to acquire lock for %s", lockName), e.getCause());
            }
        }
        return true;
    }

    protected static boolean unlock(String lockName) {
        if (locks.get(lockName) != null) {
            try {
                locks.get(lockName).getLeft().writeLock().unlock();
            } catch (Exception e) {
                logger.error("Unable to un-lock for " + lockName, e);
                return false;
            }
            if (0 == locks.get(lockName).getRight().decrementAndGet()) {
                synchronized (locks) {
                    if (locks.get(lockName).getRight().get() == 0) {
                        locks.remove(lockName);
                    }
                }
            }
        }
        return true;
    }

    protected static Short getIPPrefixFromPort(DataBroker broker, Port port) {
        Short prefix = new Short((short) 0);
        String cidr = "";
        try {
            Uuid subnetUUID = port.getFixedIps().get(0).getSubnetId();
            SubnetKey subnetkey = new SubnetKey(subnetUUID);
            InstanceIdentifier<Subnet> subnetidentifier = InstanceIdentifier.create(Neutron.class).child(Subnets
                    .class).child(Subnet.class, subnetkey);
            Optional<Subnet> subnet = read(broker, LogicalDatastoreType.CONFIGURATION, subnetidentifier);
            if (subnet.isPresent()) {
                cidr = String.valueOf(subnet.get().getCidr().getValue());
                // Extract the prefix length from cidr
                String[] parts = cidr.split("/");
                if (parts.length == 2) {
                    prefix = Short.valueOf(parts[1]);
                    return prefix;
                } else {
                    logger.trace("Could not retrieve prefix from subnet CIDR");
                    System.out.println("Could not retrieve prefix from subnet CIDR");
                }
            } else {
                logger.trace("Unable to read on subnet datastore");
            }
        } catch (Exception e) {
            logger.error("Failed to retrieve IP prefix from port : ", e);
            System.out.println("Failed to retrieve IP prefix from port : " + e.getMessage());
        }
        return null;
    }

    protected static void createVpnPortFixedIpToPort(DataBroker broker, String vpnName, String fixedIp, String
            portName, String macAddress, boolean isSubnetIp, boolean isConfig, boolean isLearnt) {
        InstanceIdentifier<VpnPortipToPort> id = NeutronvpnUtils.buildVpnPortipToPortIdentifier(vpnName, fixedIp);
        VpnPortipToPortBuilder builder = new VpnPortipToPortBuilder().setKey(new VpnPortipToPortKey(fixedIp, vpnName)
        ).setVpnName(vpnName).setPortFixedip(fixedIp).setPortName(portName).setMacAddress(macAddress).setSubnetIp
                (isSubnetIp).setConfig(isConfig).setLearnt(isLearnt);
        try {
            synchronized ((vpnName + fixedIp).intern()) {
                MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, id, builder.build());
            }
            logger.trace("Neutron port with fixedIp: {}, vpn {}, interface {}, mac {}, isSubnetIp {} added to " +
                    "VpnPortipToPort DS", fixedIp, vpnName, portName, macAddress, isSubnetIp);
        } catch (Exception e) {
            logger.error("Failure while creating VPNPortFixedIpToPort map for vpn {} - fixedIP {}", vpnName, fixedIp,
                    e);
        }
    }

    protected static void removeVpnPortFixedIpToPort(DataBroker broker, String vpnName, String fixedIp) {
        InstanceIdentifier<VpnPortipToPort> id = NeutronvpnUtils.buildVpnPortipToPortIdentifier(vpnName, fixedIp);
        try {
            synchronized ((vpnName + fixedIp).intern()) {
                MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, id);
            }
            logger.trace("Neutron router port with fixedIp: {}, vpn {} removed from VpnPortipToPort DS", fixedIp,
                    vpnName);
        } catch (Exception e) {
            logger.error("Failure while removing VPNPortFixedIpToPort map for vpn {} - fixedIP {}", vpnName, fixedIp,
                    e);
        }
    }

    public static void addToNetworkCache(Network network) {
        networkMap.put(network.getUuid(), network);
    }

    public static void removeFromNetworkCache(Network network) {
        networkMap.remove(network.getUuid());
    }

    public static void addToRouterCache(Router router) {
        routerMap.put(router.getUuid(), router);
    }

    public static void removeFromRouterCache(Router router) {
        routerMap.remove(router.getUuid());
    }

    public static void addToPortCache(Port port) {
        portMap.put(port.getUuid(), port);
    }

    public static void removeFromPortCache(Port port) {
        portMap.remove(port.getUuid());
    }

    public static void addToSubnetCache(Subnet subnet) {
        subnetMap.put(subnet.getUuid(), subnet);
        IpAddress gatewayIp = subnet.getGatewayIp();
        if (gatewayIp != null) {
            Set<Uuid> gwIps = subnetGwIpMap.get(gatewayIp);
            if (gwIps == null) {
                gwIps = Sets.newConcurrentHashSet();
                subnetGwIpMap.put(gatewayIp, gwIps);
            }
            gwIps.add(subnet.getUuid());
        }
    }

    public static void removeFromSubnetCache(Subnet subnet) {
        subnetMap.remove(subnet.getUuid());
        IpAddress gatewayIp = subnet.getGatewayIp();
        if (gatewayIp != null) {
            Set<Uuid> gwIps = subnetGwIpMap.get(gatewayIp);
            if (gwIps != null) {
                gwIps.remove(subnet.getUuid());
            }
        }
    }


    public static Class<? extends SegmentTypeBase> getSegmentTypeFromNeutronNetwork(Network network) {
        NetworkProviderExtension providerExtension = network.getAugmentation(NetworkProviderExtension.class);
        return providerExtension != null ? NETWORK_MAP.get(providerExtension.getNetworkType()) : null;
    }

    public static String getPhysicalNetworkName(Network network) {
        NetworkProviderExtension providerExtension = network.getAugmentation(NetworkProviderExtension.class);
        return providerExtension != null ? providerExtension.getPhysicalNetwork() : null;
    }

    public static Collection<Uuid> getSubnetIdsForGatewayIp(IpAddress ipAddress) {
        return subnetGwIpMap.getOrDefault(ipAddress, Collections.emptySet());
    }

    static InstanceIdentifier<VpnPortipToPort> buildVpnPortipToPortIdentifier(String vpnName, String fixedIp) {
        InstanceIdentifier<VpnPortipToPort> id = InstanceIdentifier.builder(NeutronVpnPortipPortData.class).child
                (VpnPortipToPort.class, new VpnPortipToPortKey(fixedIp, vpnName)).build();
        return id;
    }

    static Boolean getIsExternal(Network network) {
        return network.getAugmentation(NetworkL3Extension.class) != null
                && network.getAugmentation(NetworkL3Extension.class).isExternal();
    }

    public static void addToQosPolicyCache(QosPolicy qosPolicy) {
        qosPolicyMap.put(qosPolicy.getUuid(),qosPolicy);
    }

    public static void removeFromQosPolicyCache(QosPolicy qosPolicy) {
        qosPolicyMap.remove(qosPolicy.getUuid());
    }

    public static void addToQosPortsCache(Uuid qosUuid, Port port) {
        if (qosPortsMap.containsKey(qosUuid)) {
            if (!qosPortsMap.get(qosUuid).containsKey(port.getUuid())) {
                qosPortsMap.get(qosUuid).put(port.getUuid(), port);
            }
        } else {
            HashMap<Uuid, Port> portMap = new HashMap<>();
            portMap.put(port.getUuid(), port);
            qosPortsMap.put(qosUuid, portMap);
        }
    }

    public static void removeFromQosPortsCache(Uuid qosUuid, Port port) {
        if (qosPortsMap.containsKey(qosUuid) && qosPortsMap.get(qosUuid).containsKey(port.getUuid())) {
            qosPortsMap.get(qosUuid).remove(port.getUuid(), port);
        }
    }

    public static void addToQosNetworksCache(Uuid qosUuid, Network network) {
        if (qosNetworksMap.containsKey(qosUuid)) {
            if (!qosNetworksMap.get(qosUuid).containsKey(network.getUuid())) {
                qosNetworksMap.get(qosUuid).put(network.getUuid(), network);
            }
        } else {
            HashMap<Uuid, Network> networkMap = new HashMap<>();
            networkMap.put(network.getUuid(), network);
            qosNetworksMap.put(qosUuid, networkMap);
        }
    }

    public static void removeFromQosNetworksCache(Uuid qosUuid, Network network) {
        if (qosNetworksMap.containsKey(qosUuid) && qosNetworksMap.get(qosUuid).containsKey(network.getUuid())) {
            qosNetworksMap.get(qosUuid).remove(network.getUuid(), network);
        }
    }

    static InstanceIdentifier<NetworkMap> buildNetworkMapIdentifier(Uuid networkId) {
        InstanceIdentifier<NetworkMap> id = InstanceIdentifier.builder(NetworkMaps.class).child(NetworkMap.class, new
                NetworkMapKey(networkId)).build();
        return id;
    }

    static InstanceIdentifier<VpnInterface> buildVpnInterfaceIdentifier(String ifName) {
        InstanceIdentifier<VpnInterface> id = InstanceIdentifier.builder(VpnInterfaces.class).child(VpnInterface
                .class, new VpnInterfaceKey(ifName)).build();
        return id;
    }

    static InstanceIdentifier<Subnetmap> buildSubnetMapIdentifier(Uuid subnetId) {
        InstanceIdentifier<Subnetmap> id = InstanceIdentifier.builder(Subnetmaps.class).child(Subnetmap.class, new
                SubnetmapKey(subnetId)).build();
        return id;
    }

    static InstanceIdentifier<Interface> buildVlanInterfaceIdentifier(String interfaceName) {
        InstanceIdentifier<Interface> id = InstanceIdentifier.builder(Interfaces.class).child(Interface.class, new
                InterfaceKey(interfaceName)).build();
        return id;
    }

    static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext
            .routers.Routers> buildExtRoutersIdentifier(Uuid routerId) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers
                .Routers> id = InstanceIdentifier.builder(ExtRouters.class).child(org.opendaylight.yang.gen.v1.urn
                .opendaylight.netvirt.natservice.rev160111.ext.routers.Routers.class, new RoutersKey(routerId
                .getValue())).build();
        return id;
    }

    static InstanceIdentifier<FloatingIpIdToPortMapping> buildfloatingIpIdToPortMappingIdentifier (Uuid floatingIpId) {
        return InstanceIdentifier.builder(FloatingIpPortInfo.class).child(FloatingIpIdToPortMapping.class, new
                FloatingIpIdToPortMappingKey(floatingIpId)).build();
    }

    static <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType,
                                                   InstanceIdentifier<T> path) {
        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();
        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return result;
    }

    static boolean isNetworkTypeSupported(Network network) {
        NetworkProviderExtension npe = network.getAugmentation(NetworkProviderExtension.class);
        return npe != null && supportedNetworkTypes.contains(npe.getNetworkType());
    }

    static ProviderTypes getProviderNetworkType(Network network) {
        if (network == null) {
            logger.error("Error in getting provider network type since network is null");
            return null;
        }
        NetworkProviderExtension npe = network.getAugmentation(NetworkProviderExtension.class);
        if (npe != null) {
            Class<? extends NetworkTypeBase> networkTypeBase = npe.getNetworkType();
            if (networkTypeBase != null) {
               if(networkTypeBase.isAssignableFrom(NetworkTypeFlat.class)) {
                   return ProviderTypes.FLAT;
               } else if (networkTypeBase.isAssignableFrom(NetworkTypeVlan.class)) {
                   return ProviderTypes.VLAN;
               } else if (networkTypeBase.isAssignableFrom(NetworkTypeVxlan.class)) {
                   return ProviderTypes.VXLAN;
               } else if (networkTypeBase.isAssignableFrom(NetworkTypeGre.class)) {
                   return ProviderTypes.GRE;
               }
            }
        }
        return null;
    }

    static boolean isNetworkOfType(Network network, Class<? extends NetworkTypeBase> type) {
        NetworkProviderExtension npe = network.getAugmentation(NetworkProviderExtension.class);
        return npe != null && type.isAssignableFrom(npe.getNetworkType());
    }

    /**
     * Get inter-VPN link state
     *
     * @param broker data broker
     * @param vpnLinkName VPN link name
     * @return Optional of InterVpnLinkState
     */
    public static Optional<InterVpnLinkState> getInterVpnLinkState(DataBroker broker, String vpnLinkName) {
        InstanceIdentifier<InterVpnLinkState> vpnLinkStateIid = InstanceIdentifier.builder(InterVpnLinkStates.class)
                .child(InterVpnLinkState.class, new InterVpnLinkStateKey(vpnLinkName)).build();
        return read(broker, LogicalDatastoreType.CONFIGURATION, vpnLinkStateIid);
    }

    /**
     * Returns an InterVpnLink by searching by one of its endpoint's IP.
     *
     * @param broker
     * @param endpointIp IP to search for
     * @return
     */
    public static Optional<InterVpnLink> getInterVpnLinkByEndpointIp(DataBroker broker, String endpointIp) {
        InstanceIdentifier<InterVpnLinks> interVpnLinksIid = InstanceIdentifier.builder(InterVpnLinks.class).build();
        Optional<InterVpnLinks> interVpnLinksOpData = MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION,
                interVpnLinksIid);
        if (interVpnLinksOpData.isPresent()) {
            List<InterVpnLink> allInterVpnLinks = interVpnLinksOpData.get().getInterVpnLink();
            for (InterVpnLink interVpnLink : allInterVpnLinks) {
                if (interVpnLink.getFirstEndpoint().getIpAddress().getValue().equals(endpointIp)
                        || interVpnLink.getSecondEndpoint().getIpAddress().getValue().equals(endpointIp)) {
                    return Optional.of(interVpnLink);
                }
            }
        }
        return Optional.absent();
    }


    public static Set<RouterDpnList> getAllRouterDpnList(DataBroker broker, BigInteger dpid) {
        Set<RouterDpnList> ret = new HashSet<>();
        InstanceIdentifier<NeutronRouterDpns> routerDpnId =
                InstanceIdentifier.create(NeutronRouterDpns.class);
        Optional<NeutronRouterDpns> neutronRouterDpnsOpt = MDSALUtil.read(broker, LogicalDatastoreType.OPERATIONAL, routerDpnId);
        if (neutronRouterDpnsOpt.isPresent()) {
            NeutronRouterDpns neutronRouterDpns = neutronRouterDpnsOpt.get();
            List<RouterDpnList> routerDpnLists = neutronRouterDpns.getRouterDpnList();
            for (RouterDpnList routerDpnList : routerDpnLists) {
                if (routerDpnList.getDpnVpninterfacesList() != null) {
                    for (DpnVpninterfacesList dpnInterfaceList : routerDpnList.getDpnVpninterfacesList()) {
                        if (dpnInterfaceList.getDpnId().equals(dpid)) {
                            ret.add(routerDpnList);
                        }
                    }
                }
            }
        }
        return ret;
    }

    protected static Integer getUniqueRDId(IdManagerService idManager, String poolName, String idKey) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();
        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                return rpcResult.getResult().getIdValue().intValue();
            } else {
                logger.debug("RPC Call to Get Unique Id returned with Errors", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            logger.debug("Exception when getting Unique Id", e);
        }
        return null;
    }

    protected static void releaseRDId(IdManagerService idManager, String poolName, String idKey) {
        ReleaseIdInput idInput = new ReleaseIdInputBuilder().setPoolName(poolName).setIdKey(idKey).build();
        try {
            Future<RpcResult<Void>> result = idManager.releaseId(idInput);
            RpcResult<Void> rpcResult = result.get();
            if (!rpcResult.isSuccessful()) {
                logger.debug("RPC Call to Get Unique Id returned with Errors", rpcResult.getErrors());
            } else {
                logger.info("ID for RD " + idKey + " released successfully");
            }
        } catch (InterruptedException | ExecutionException e) {
            logger.debug("Exception when trying to release ID into the pool", idKey, e);
        }
    }

    protected static IpAddress getIpv6LinkLocalAddressFromMac(MacAddress mac) {
        byte[] octets = bytesFromHexString(mac.getValue());

        /* As per the RFC2373, steps involved to generate a LLA include
           1. Convert the 48 bit MAC address to 64 bit value by inserting 0xFFFE
              between OUI and NIC Specific part.
           2. Invert the Universal/Local flag in the OUI portion of the address.
           3. Use the prefix "FE80::/10" along with the above 64 bit Interface
              identifier to generate the IPv6 LLA. */

        StringBuffer interfaceID = new StringBuffer();
        short u8byte = (short) (octets[0] & 0xff);
        u8byte ^= 1 << 1;
        interfaceID.append(Integer.toHexString(0xFF & u8byte));
        interfaceID.append(StringUtils.leftPad(Integer.toHexString(0xFF & octets[1]), 2, "0"));
        interfaceID.append(":");
        interfaceID.append(Integer.toHexString(0xFF & octets[2]));
        interfaceID.append("ff:fe");
        interfaceID.append(StringUtils.leftPad(Integer.toHexString(0xFF & octets[3]), 2, "0"));
        interfaceID.append(":");
        interfaceID.append(Integer.toHexString(0xFF & octets[4]));
        interfaceID.append(StringUtils.leftPad(Integer.toHexString(0xFF & octets[5]), 2, "0"));

        Ipv6Address ipv6LLA = new Ipv6Address("fe80:0:0:0:" + interfaceID.toString());
        IpAddress ipAddress = new IpAddress(ipv6LLA.getValue().toCharArray());
        return ipAddress;
    }

    protected static byte[] bytesFromHexString(String values) {
        String target = "";
        if (values != null) {
            target = values;
        }
        String[] octets = target.split(":");

        byte[] ret = new byte[octets.length];
        for (int i = 0; i < octets.length; i++) {
            ret[i] = Integer.valueOf(octets[i], 16).byteValue();
        }
        return ret;
    }

    static List<String> getExistingRDs(DataBroker broker) {
        List<String> existingRDs = new ArrayList<>();
        InstanceIdentifier<VpnInstances> path = InstanceIdentifier.builder(VpnInstances.class).build();
        Optional<VpnInstances> vpnInstancesOptional = NeutronvpnUtils.read(broker, LogicalDatastoreType.CONFIGURATION, path);
        if (vpnInstancesOptional.isPresent() && vpnInstancesOptional.get().getVpnInstance() != null) {
            for (VpnInstance vpnInstance : vpnInstancesOptional.get().getVpnInstance()) {
                existingRDs.add(vpnInstance.getIpv4Family().getRouteDistinguisher());
            }
        }
        return existingRDs;
    }

}
