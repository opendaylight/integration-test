/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.util.Collection;
import java.util.HashMap;
import java.util.UUID;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.Dhcpv6Slaac;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.IpVersionV4;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.IpVersionV6;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.NetworkBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtensionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.SubnetBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class NeutronNetwork {
    private final MdsalUtils mdsalUtils;
    private final String segId;
    private final String tenantId;
    private final String networkId;
    private HashMap<String, Subnet> subnetIpPrefixMap;
    private final Class<? extends NetworkTypeBase> netType;
    private final String providerNet;
    private Network network;

    NeutronNetwork(final MdsalUtils mdsalUtils, final String segId) {
        this(mdsalUtils, segId, NetworkTypeVxlan.class, null);
    }

    NeutronNetwork(final MdsalUtils mdsalUtils, final String segId,
                   Class<? extends NetworkTypeBase> netType, String providerNet) {
        this.mdsalUtils = mdsalUtils;
        this.segId = segId;
        tenantId = UUID.randomUUID().toString();
        networkId = UUID.randomUUID().toString();
        this.netType = netType;
        this.providerNet = providerNet;
        this.subnetIpPrefixMap = new HashMap<String, Subnet>();
    }

    String getNetworkId() {
        return networkId;
    }

    void createNetwork(final String name) {
        NetworkProviderExtension networkProviderExtension = new NetworkProviderExtensionBuilder()
                .setNetworkType(netType)
                .setSegmentationId(segId)
                .setPhysicalNetwork(providerNet)
                .build();

        network = new NetworkBuilder()
                .setTenantId(new Uuid(tenantId))
                .setUuid(new Uuid(networkId))
                .setAdminStateUp(true)
                .setShared(false)
                .setStatus("ACTIVE")
                .setName(name)
                .addAugmentation(NetworkProviderExtension.class, networkProviderExtension)
                .build();

        mdsalUtils.put(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Networks.class).child(Network.class, network.getKey()), network);
    }

    void deleteNetwork() {
        if (network == null) {
            return;
        }

        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Networks.class).child(Network.class, network.getKey()));

    }

    String createSubnet(final String name, int ipVersion, String ipPfx) {
        String subnetId = null;
        if (subnetIpPrefixMap.get(ipPfx) == null) {
            Subnet subnet;
            subnetId = UUID.randomUUID().toString();
            if (NetvirtITConstants.IPV4 == ipVersion) {
                String cidr = ipPfx + "0/24";
                subnet = new SubnetBuilder()
                        .setName(name)
                        .setTenantId(new Uuid(tenantId))
                        .setUuid(new Uuid(subnetId))
                        .setNetworkId(new Uuid(networkId))
                        .setCidr(new IpPrefix(cidr.toCharArray()))
                        .setGatewayIp(new IpAddress(new Ipv4Address(ipPfx + NetvirtITConstants.GATEWAY_SUFFIX)))
                        .setIpVersion(IpVersionV4.class)
                        .setEnableDhcp(true)
                        .build();
            } else {
                String cidr = ipPfx + NetvirtITConstants.IPV6_SLAAC_SUBNET_PREFIX;
                subnet = new SubnetBuilder()
                        .setName(name)
                        .setTenantId(new Uuid(tenantId))
                        .setUuid(new Uuid(subnetId))
                        .setNetworkId(new Uuid(networkId))
                        .setCidr(new IpPrefix(cidr.toCharArray()))
                        .setGatewayIp(new IpAddress(new Ipv6Address(ipPfx + NetvirtITConstants.IPV6_GATEWAY_SUFFIX)))
                        .setIpVersion(IpVersionV6.class)
                        .setIpv6AddressMode(Dhcpv6Slaac.class)
                        .setIpv6RaMode(Dhcpv6Slaac.class)
                        .setEnableDhcp(true)
                        .build();

            }
            subnetIpPrefixMap.put(ipPfx, subnet);
            mdsalUtils.put(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                    .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                    .child(Subnets.class).child(Subnet.class, subnet.getKey()), subnet);
        }
        return subnetId;
    }

    void deleteSubnets() {
        for (Subnet subnet: subnetIpPrefixMap.values()) {
            mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                    .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                    .child(Subnets.class).child(Subnet.class, subnet.getKey()));
        }
        subnetIpPrefixMap.clear();
    }

    public Collection<Subnet> getSubnets() {
        return subnetIpPrefixMap.values();
    }

    public String getSubnetId(String ipPfx) {
        Subnet subnet = subnetIpPrefixMap.get(ipPfx);
        if (subnet != null) {
            return subnet.getUuid().getValue();
        }
        return null;
    }
}
