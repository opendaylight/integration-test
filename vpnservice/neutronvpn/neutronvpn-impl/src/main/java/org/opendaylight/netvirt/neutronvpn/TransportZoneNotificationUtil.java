/*
 * Copyright (c) 2015 - 2016 HPE and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.BridgeRefInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.TransportZones;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.TransportZonesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZone;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZoneBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZoneKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.SubnetsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.SubnetsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.subnets.Vteps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.subnets.VtepsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.config.rev160806.NeutronvpnConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.NetworkKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TransportZoneNotificationUtil {

    private static final Logger LOG = LoggerFactory.getLogger(TransportZoneNotificationUtil.class);
    private static final String OF_URI_SEPARATOR = ":";
    private static final String TUNNEL_PORT = "tunnel_port";
    private static final String LOCAL_IP = "local_ip";
    private static final String ALL_SUBNETS = "0.0.0.0/0";
    private final DataBroker dataBroker;
    private final NeutronvpnManager nvManager;
    private final MdsalUtils mdsalUtils;
    private final SouthboundUtils southBoundUtils;
    private final NeutronvpnConfig neutronvpnConfig;

    public TransportZoneNotificationUtil(DataBroker dbx, NeutronvpnManager nvManager) {
        this.dataBroker = dbx;
        this.nvManager = nvManager;
        this.mdsalUtils = new MdsalUtils(dbx);
        southBoundUtils = new SouthboundUtils(mdsalUtils);
        this.neutronvpnConfig = nvManager.getNeutronvpnConfig();
    }


    /**
     * Update/add TransportZone for bridheEntryRef change.<br>
     * for any update on bridge entry we are looking for all the routers which are affected and try to recreate
     * its TZ
     * @param entry - the BridgeEntryRef that was updated
     */
    public void updateTrasportZone(BridgeRefEntry entry) {
        BigInteger dpid = entry.getDpid();
        Set<RouterDpnList> allRouterDpnList = NeutronvpnUtils.getAllRouterDpnList(dataBroker, dpid);
        for (RouterDpnList routerDpnList : allRouterDpnList) {
            updateTrasportZone(routerDpnList);
        }
    }

    /**
     * Update/add TransportZone for interface State inter.<br>
     * If Transport zone for given Network doesn't exist, then it will be added.<br>
     * If the TEP of the port's node exists in the TZ, it will not be added.
     * @param inter - the interface to update
     */
    public void updateTrasportZone(Interface inter) {
        List<Port> ports = getPortsFromInterface(inter);
        //supports VPN aware VMs (multiple ports for one interface)
        for (Port port : ports) {
            try {

                if (!checkIfVxlanNetwork(port)) {
                    continue;
                }

                String subnetIp = ALL_SUBNETS;

                BigInteger dpnId = getDpnIdFromInterfaceState(inter);

                InstanceIdentifier<TransportZone> inst = InstanceIdentifier.create(TransportZones.class)
                        .child(TransportZone.class, new TransportZoneKey(port.getNetworkId().getValue()));
                TransportZone zone = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, inst);

                if (zone == null) {
                    zone = createZone(subnetIp, port.getNetworkId().getValue());
                }

                if (addVtep(zone, subnetIp, dpnId) > 0) {
                    addTransportZone(zone, inter.getName());
                }

            } catch (Exception e) {
                LOG.warn("failed to add tunnels on interface added to subnet {}. ", inter, e);
            }
        }
    }

    public void updateTrasportZone(RouterDpnList routerDpnList) {
        try{
            InstanceIdentifier<TransportZone> inst = InstanceIdentifier.create(TransportZones.class).
                    child(TransportZone.class, new TransportZoneKey(routerDpnList.getRouterId()));
            TransportZone zone = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, inst);

            String subnetIp = ALL_SUBNETS;

            if (zone == null) {
                zone = createZone(subnetIp, routerDpnList.getRouterId());
            }
            int addedTeps = 0;
            for (DpnVpninterfacesList dpnVpninterfacesList : routerDpnList.getDpnVpninterfacesList()) {
                BigInteger dpnId = dpnVpninterfacesList.getDpnId();
                addedTeps += addVtep(zone, subnetIp, dpnId);
            }
            if (addedTeps > 0) {
                addTransportZone(zone, "router " + routerDpnList.getRouterId());
            }
        } catch (Exception e) {
            LOG.warn("failed to add tunnels on router added of routerDpnList {}. ", routerDpnList, e);
        }
    }

    public boolean isAutoTunnelConfigEnabled() {
        Boolean useTZ = true;
        if (neutronvpnConfig != null && neutronvpnConfig.isUseTransportZone() != null) {
            useTZ = neutronvpnConfig.isUseTransportZone();
        }
        LOG.info("isAutoTunnelConfigEnabled: useTz: {}, neutronvpnConfig: {}", useTZ, neutronvpnConfig);
        return useTZ;
    }

    private boolean checkIfVxlanNetwork(Port port) {
        InstanceIdentifier<Network> networkPath = InstanceIdentifier.create(Neutron.class)
                .child(Networks.class).child(Network.class, new NetworkKey(port.getNetworkId()));
        Network network = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, networkPath);

        if (network == null || !NeutronvpnUtils.isNetworkOfType(network, NetworkTypeVxlan.class)) {
            LOG.debug("port in non-VXLAN network " + port.getName());
            return false;
        }

        return true;
    }


    private BigInteger getDpnIdFromInterfaceState(Interface inter) {
        String lowerLayerIf = inter.getLowerLayerIf().get(0);
        NodeConnectorId nodeConnectorId = new NodeConnectorId(lowerLayerIf);
        BigInteger dpId = new BigInteger(getDpnFromNodeConnectorId(nodeConnectorId));
        return dpId;
    }

    /*
     * takes all Neutron Ports that are related to the given interface state
     * @param interfaceState - interface state to update
     * @return - list of ports bound to interface
     */
    private List<Port> getPortsFromInterface(Interface interfaceState) {
        String physPortId = getPortFromInterfaceName(interfaceState.getName());
        List<Port> portsList = new ArrayList<>();

        InstanceIdentifier<Interfaces> interPath = InstanceIdentifier.create(Interfaces.class);
        Interfaces interfaces = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, interPath);
        if (interfaces == null) {
            LOG.error("No interfaces in configuration");
            return portsList;
        }
        List<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
            .Interface> inters = interfaces.getInterface();

        // take all interfaces with parent-interface with physPortId name
        for (org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                .Interface inter : inters) {
            ParentRefs parent = inter.getAugmentation(ParentRefs.class);
            if (parent == null || !physPortId.equals(parent.getParentInterface())) {
                continue;
            }
            String parentInt = inter.getName();
            Uuid portUid = new Uuid(parentInt);
            InstanceIdentifier<Port> pathPort = InstanceIdentifier.create(Neutron.class).child(Ports.class)
                    .child(Port.class, new PortKey(portUid));
            Port port = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, pathPort);

            if (port == null) {
                LOG.debug("got Interface State of non NeutronPort instance " + physPortId);
                continue;
            }

            portsList.add(port);
        }

        return portsList;
    }


    private String getPortFromInterfaceName(String name) {
        String[] splitedStr = name.split(OF_URI_SEPARATOR);
        name = splitedStr.length > 1 ? splitedStr[1] : name;
        return name;
    }


    // TODO: code is used in another places. Should be extracted into utility
    private String getDpnFromNodeConnectorId(NodeConnectorId portId) {
        String[] split = portId.getValue().split(OF_URI_SEPARATOR);
        return split[1];
    }



    private TransportZone createZone(String subnetIp, String zoneName) {
        TransportZoneBuilder tzb = new TransportZoneBuilder();
        tzb.setKey(new TransportZoneKey(zoneName));
        tzb.setTunnelType(TunnelTypeVxlan.class);
        tzb.setZoneName(zoneName);
        List<Subnets> subnets = new ArrayList<>();
        subnets.add(newSubnets(subnetIp));
        tzb.setSubnets(subnets);
        return tzb.build();
    }


    private void addTransportZone(TransportZone zone, String interName) {
        InstanceIdentifier<TransportZones> path = InstanceIdentifier.builder(TransportZones.class).build();
        TransportZones zones = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, path);
        if (zones == null) {
            List<TransportZone> zoneList = new ArrayList<>();
            zoneList.add(zone);
            zones = new TransportZonesBuilder().setTransportZone(zoneList).build();
        } else {
            zones.getTransportZone().add(zone);
        }

        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, path, zones);
        LOG.info("updating transport zone {} due to {} handling", zone.getZoneName(), interName);
    }

    private int addVtep(TransportZone zone, String subnetIp, BigInteger dpnId) throws Exception {

        Subnets subnets = findSubnets(zone.getSubnets(), subnetIp);

        for(Vteps existingVtep : subnets.getVteps()){
            if (existingVtep.getDpnId().equals(dpnId)) {
                return 0;
            }
        }

        IpAddress nodeIp =  getNodeIP(dpnId);

        VtepsBuilder vtepsBuilder = new VtepsBuilder();
        vtepsBuilder.setDpnId(dpnId);
        vtepsBuilder.setIpAddress(nodeIp);
        vtepsBuilder.setPortname(TUNNEL_PORT);

        subnets.getVteps().add(vtepsBuilder.build());

        return 1;
    }

    // search for relevant subnets for the given subnetIP, add one if it is necessary
    private Subnets findSubnets(List<Subnets> subnets, String subnetIp) {
        for (Subnets subnet : subnets) {
            IpPrefix subnetPrefix = new IpPrefix(subnetIp.toCharArray());
            if (subnet.getPrefix().equals(subnetPrefix)) {
                return subnet;
            }
        }

        Subnets retSubnet = newSubnets(subnetIp);
        subnets.add(retSubnet);

        return retSubnet;
    }

    private Subnets newSubnets(String subnetIp) {
        SubnetsBuilder subnetsBuilder = new SubnetsBuilder();
        subnetsBuilder.setDeviceVteps(new ArrayList<>());
        subnetsBuilder.setGatewayIp(new IpAddress("0.0.0.0".toCharArray()));
        subnetsBuilder.setKey(new SubnetsKey(new IpPrefix(subnetIp.toCharArray())));
        subnetsBuilder.setVlanId(0);
        subnetsBuilder.setVteps(new ArrayList<Vteps>());
        return subnetsBuilder.build();
    }

    private IpAddress getNodeIP(BigInteger dpId) throws Exception {
        Node node = getPortsNode(dpId);
        String localIp = southBoundUtils.getOpenvswitchOtherConfig(node, LOCAL_IP);
        if (localIp == null) {
            throw new Exception("missing local_ip key in ovsdb:openvswitch-other-configs in operational"
                    + " network-topology for node: " + node.getNodeId().getValue());
        }

        return new IpAddress(localIp.toCharArray());
    }

    @SuppressWarnings("unchecked")
    private Node getPortsNode(BigInteger dpnId) throws Exception{
        InstanceIdentifier<BridgeRefEntry> bridgeRefInfoPath = InstanceIdentifier.
                create(BridgeRefInfo.class).child(BridgeRefEntry.class, new BridgeRefEntryKey(dpnId));
        BridgeRefEntry bridgeRefEntry = mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, bridgeRefInfoPath);
        if (bridgeRefEntry == null) {
            throw new Exception("no bridge ref entry found for dpnId: " + dpnId);
        }

        InstanceIdentifier<Node> nodeId = ((InstanceIdentifier<OvsdbBridgeAugmentation>) bridgeRefEntry
                .getBridgeReference().getValue()).firstIdentifierOf(Node.class);
        Node node = mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, nodeId);

        if (node == null) {
            throw new Exception("missing node for dpnId: " + dpnId);
        }
        return node;

    }
}
