/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import com.google.common.collect.Maps;
import java.io.IOException;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.DockerOvs;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.IpVersionV4;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeFlat;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AbstractNetOvs implements NetOvs {
    private static final Logger LOG = LoggerFactory.getLogger(AbstractNetOvs.class);
    protected final DockerOvs dockerOvs;
    protected final Boolean isUserSpace;
    protected final MdsalUtils mdsalUtils;
    private final SouthboundUtils southboundUtils;
    protected static final int DEFAULT_WAIT = 30 * 1000;
    protected Map<String, PortInfo> portInfoByName = new HashMap<>();
    protected Map<String, NeutronNetwork> neutronNetworkByName = new HashMap<>();
    protected Map<String, NeutronRouter> neutronRouterByName = new HashMap<>();
    protected Map<String, String> ipPfxSubnetIdMap = new HashMap<>();

    AbstractNetOvs(final DockerOvs dockerOvs, final Boolean isUserSpace, final MdsalUtils mdsalUtils,
                   SouthboundUtils southboundUtils) {
        this.dockerOvs = dockerOvs;
        this.isUserSpace = isUserSpace;
        this.mdsalUtils = mdsalUtils;
        this.southboundUtils = southboundUtils;
        LOG.info("{} isUserSpace: {}, usingExternalDocker: {}",
                getClass().getSimpleName(), isUserSpace, dockerOvs.usingExternalDocker());
    }

    @Override
    public String createNetwork(String networkName, String segId) {
        return createNetwork(networkName, segId, NetworkTypeVxlan.class, null);
    }

    private String createNetwork(String networkName, String segId,
                                 Class<? extends NetworkTypeBase> netType, String physNet) {
        NeutronNetwork neutronNetwork = new NeutronNetwork(mdsalUtils, segId, netType, physNet);
        neutronNetwork.createNetwork(networkName);
        putNeutronNetwork(networkName, neutronNetwork);
        return networkName;
    }

    @Override
    public String createSubnet(String networkName, int ipVersion, String ipPfx) {
        NeutronNetwork neutronNetwork = getNeutronNetwork(networkName);
        String subnetId = neutronNetwork.createSubnet(networkName + "subnet_v" + ipVersion, ipVersion, ipPfx);
        if (subnetId != null) {
            ipPfxSubnetIdMap.put(ipPfx, subnetId);
        }
        return subnetId;
    }

    @Override
    public String createFlatNetwork(String networkName, String segId, String providerNet) {
        return createNetwork(networkName, segId, NetworkTypeFlat.class, providerNet);
    }

    @Override
    public String createRouter(String routerName) {
        NeutronRouter neutronRouter = new NeutronRouter(mdsalUtils);
        neutronRouter.createRouter(routerName);
        putNeutronRouter(routerName, neutronRouter);
        return neutronRouter.getRouterId();
    }

    public void putNeutronNetwork(String networkName, NeutronNetwork neutronNetwork) {
        neutronNetworkByName.put(networkName, neutronNetwork);
    }

    public void putNeutronRouter(String routerName, NeutronRouter neutronRouter) {
        neutronRouterByName.put(routerName, neutronRouter);
    }

    protected NeutronNetwork getNeutronNetwork(String networkName) {
        return neutronNetworkByName.get(networkName);
    }

    protected Collection<Subnet> getNeutronSubnets(String networkName) {
        return getNeutronNetwork(networkName).getSubnets();
    }

    protected String getSubnetIpPfx(String subnetId) {
        for (String ipPfx: ipPfxSubnetIdMap.keySet()) {
            if (subnetId.equals(ipPfxSubnetIdMap.get(ipPfx))) {
                return ipPfx;
            }
        }
        return null;
    }

    protected String getNetworkId(String name) {
        return neutronNetworkByName.get(name).getNetworkId();
    }

    protected String getRouterId(String name) {
        return neutronRouterByName.get(name).getRouterId();
    }

    protected PortInfo buildPortInfo(int ovsInstance, String networkName) {
        long idx = portInfoByName.size() + 1;
        PortInfo portInfo = new PortInfo(ovsInstance, idx);
        for (Subnet subnet: getNeutronSubnets(networkName)) {
            // Allocate an IPAddress from each of the subnet that is part of the network.
            int ipVersion = (subnet.getIpVersion() == IpVersionV4.class) ? NetvirtITConstants.IPV4 :
                    NetvirtITConstants.IPV6;
            portInfo.allocateFixedIp(ipVersion, getSubnetIpPfx(subnet.getUuid().getValue()),
                    subnet.getUuid().getValue());
        }
        return portInfo;
    }

    protected void putPortInfo(PortInfo portInfo) {
        portInfoByName.put(portInfo.name, portInfo);
    }

    @Override
    public String createPort(int ovsInstance, Node bridgeNode, String networkName, List<Uuid> securityGroupList)
            throws InterruptedException, IOException {
        return null;
    }

    @Override
    public void createRouterInterface(String routerName, String networkName) {
        for (Subnet subnet: getNeutronSubnets(networkName)) {
            // Neutron creates separate router ports for IPv4 and IPv6 subnets.
            PortInfo portInfo = new PortInfo(-1, NetvirtITConstants.GATEWAY_SUFFIX);
            int ipVersion = (subnet.getIpVersion() == IpVersionV4.class) ? NetvirtITConstants.IPV4 :
                    NetvirtITConstants.IPV6;
            portInfo.allocateFixedIp(ipVersion, getSubnetIpPfx(subnet.getUuid().getValue()),
                    subnet.getUuid().getValue());
            LOG.info("createRouterInterface enter: router: {}, network: {}, port: {}",
                    routerName, networkName, portInfo.name);
            NeutronPort neutronPort = new NeutronPort(mdsalUtils, getNetworkId(networkName));
            neutronPort.createPort(portInfo, "network:router_interface", getRouterId(routerName), false, null);

            portInfoByName.put(portInfo.name, portInfo);
            LOG.info("createRouterInterface : router: {}, network: {}, port: {}",
                    routerName, networkName, portInfo.name);
        }
    }

    @Override
    public PortInfo getPortInfo(String portName) {
        return portInfoByName.get(portName);
    }

    @Override
    public void deletePort(String uuid) {
        if (uuid == null) {
            return;
        }

        Port port = new PortBuilder()
                .setUuid(new Uuid(uuid))
                .build();

        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Ports.class).child(Port.class, port.getKey()));
    }

    @Override
    public void destroy() {
        for (PortInfo portInfo : portInfoByName.values()) {
            deletePort(portInfo.id);
        }
        portInfoByName.clear();

        for (NeutronRouter neutronRouter : neutronRouterByName.values()) {
            neutronRouter.deleteRouter();
        }
        neutronRouterByName.clear();

        for (NeutronNetwork neutronNetwork : neutronNetworkByName.values()) {
            neutronNetwork.deleteSubnets();
            neutronNetwork.deleteNetwork();
        }
        neutronNetworkByName.clear();
        ipPfxSubnetIdMap.clear();
    }

    @Override
    public void preparePortForPing(String portName) throws InterruptedException, IOException {
    }

    @Override
    public int ping(String fromPort, String toPort) throws InterruptedException, IOException {
        return 0;
    }

    @Override
    public int ping6(String fromPort, String toPort) throws InterruptedException, IOException {
        return 0;
    }

    protected void addTerminationPoint(PortInfo portInfo, Node bridge, String portType) {
        Map<String, String> externalIds = Maps.newHashMap();
        externalIds.put("attached-mac", portInfo.mac);
        externalIds.put("iface-id", portInfo.id);
        southboundUtils.addTerminationPoint(bridge, portInfo.name, portType, null, externalIds, portInfo.ofPort);
    }

    @Override
    public void logState(int dockerInstance, String logText) throws InterruptedException, IOException {
    }

    @Override
    public String getInstanceIp(int ovsInstance) throws InterruptedException, IOException {
        return null;
    }

    protected PortInfo getPortInfoByOvsInstance(int ovsInstance) {
        PortInfo portInfoFound = null;
        for (PortInfo portInfo : portInfoByName.values()) {
            if (ovsInstance == portInfo.ovsInstance) {
                portInfoFound = portInfo;
            }
        }
        return portInfoFound;
    }
}