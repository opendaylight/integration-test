/*
 * Copyright (c) 2016 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants.Ipv6RtrAdvertType;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6ServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IetfInetUtil;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.EthernetHeader;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.Ipv6Header;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.RouterAdvertisementPacket;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.RouterAdvertisementPacketBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.RouterSolicitationPacket;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.router.advertisement.packet.PrefixList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.router.advertisement.packet.PrefixListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.TransmitPacketInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.TransmitPacketInputBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ipv6RouterAdvt {
    private static final Logger LOG = LoggerFactory.getLogger(Ipv6RouterAdvt.class);
    private static PacketProcessingService pktService;
    private Ipv6ServiceUtils ipv6Utils;

    public Ipv6RouterAdvt() {
        ipv6Utils = Ipv6ServiceUtils.getInstance();
    }

    public static void setPacketProcessingService(PacketProcessingService packetService) {
        pktService = packetService;
    }

    public boolean transmitRtrAdvertisement(Ipv6RtrAdvertType raType, VirtualPort routerPort,
                                            List<NodeConnectorRef> outportList, RouterSolicitationPacket rsPdu) {
        if (pktService == null) {
            LOG.info("transmitRtrAdvertisement packet processing service is not yet configured");
            return false;
        }
        RouterAdvertisementPacketBuilder raPacket = new RouterAdvertisementPacketBuilder();
        updateRAResponse(raType, rsPdu, raPacket, routerPort);
        // Serialize the response packet
        byte[] txPayload = fillRouterAdvertisementPacket(raPacket.build());
        for (NodeConnectorRef outport: outportList) {
            InstanceIdentifier<Node> outNode = outport.getValue().firstIdentifierOf(Node.class);
            TransmitPacketInput input = new TransmitPacketInputBuilder().setPayload(txPayload)
                    .setNode(new NodeRef(outNode))
                    .setEgress(outport).build();
            LOG.debug("Transmitting the Router Advt packet out {}", outport);
            pktService.transmitPacket(input);
        }
        return true;
    }

    private void updateRAResponse(Ipv6RtrAdvertType raType, RouterSolicitationPacket pdu,
                                  RouterAdvertisementPacketBuilder raPacket,
                                  VirtualPort routerPort) {
        short icmpv6RaFlags = 0;
        String gatewayMac = null;
        IpAddress gatewayIp;
        List<String> autoConfigPrefixList = new ArrayList<String>();
        List<String> statefulConfigPrefixList = new ArrayList<String>();

        for (VirtualSubnet subnet : routerPort.getSubnets()) {
            gatewayIp = subnet.getGatewayIp();
            // Skip if its a v4 subnet.
            if (gatewayIp.getIpv4Address() != null) {
                continue;
            }

            if (!subnet.getIpv6RAMode().isEmpty()) {
                if (Ipv6Constants.IPV6_AUTO_ADDRESS_SUBNETS.contains(subnet.getIpv6RAMode())) {
                    autoConfigPrefixList.add(String.valueOf(subnet.getSubnetCidr().getValue()));
                }

                if (subnet.getIpv6RAMode().equalsIgnoreCase(Ipv6Constants.IPV6_DHCPV6_STATEFUL)) {
                    statefulConfigPrefixList.add(String.valueOf(subnet.getSubnetCidr().getValue()));
                }
            }

            if (subnet.getIpv6RAMode().equalsIgnoreCase(Ipv6Constants.IPV6_DHCPV6_STATELESS)) {
                icmpv6RaFlags = (short) (icmpv6RaFlags | (1 << 6)); // Other Configuration.
            } else if (subnet.getIpv6RAMode().equalsIgnoreCase(Ipv6Constants.IPV6_DHCPV6_STATEFUL)) {
                icmpv6RaFlags = (short) (icmpv6RaFlags | (1 << 7)); // Managed Address Conf.
            }
        }

        gatewayMac = routerPort.getMacAddress();

        MacAddress sourceMac = MacAddress.getDefaultInstance(gatewayMac);
        raPacket.setSourceMac(sourceMac);
        if (raType == Ipv6RtrAdvertType.SOLICITED_ADVERTISEMENT) {
            raPacket.setDestinationMac(pdu.getSourceMac());
            raPacket.setDestinationIpv6(pdu.getSourceIpv6());
            raPacket.setFlowLabel(pdu.getFlowLabel());
        } else {
            raPacket.setDestinationMac(new MacAddress(Ipv6Constants.DEF_MCAST_MAC));
            raPacket.setDestinationIpv6(Ipv6ServiceUtils.ALL_NODES_MCAST_ADDR);
            raPacket.setFlowLabel(Ipv6Constants.DEF_FLOWLABEL);
        }

        raPacket.setEthertype(Ipv6Constants.IP_V6_ETHTYPE);

        raPacket.setVersion(Ipv6Constants.IPV6_VERSION);
        int prefixListLength = autoConfigPrefixList.size() + statefulConfigPrefixList.size();
        raPacket.setIpv6Length(Ipv6Constants.ICMPV6_RA_LENGTH_WO_OPTIONS
                + Ipv6Constants.ICMPV6_OPTION_SOURCE_LLA_LENGTH
                + prefixListLength * Ipv6Constants.ICMPV6_OPTION_PREFIX_LENGTH);
        raPacket.setNextHeader(Ipv6Constants.ICMP6_NHEADER);
        raPacket.setHopLimit(Ipv6Constants.ICMP_V6_MAX_HOP_LIMIT);
        raPacket.setSourceIpv6(ipv6Utils.getIpv6LinkLocalAddressFromMac(sourceMac));

        raPacket.setIcmp6Type(Ipv6Constants.ICMP_V6_RA_CODE);
        raPacket.setIcmp6Code((short)0);
        raPacket.setIcmp6Chksum(0);

        raPacket.setCurHopLimit((short) Ipv6Constants.IPV6_DEFAULT_HOP_LIMIT);
        raPacket.setFlags((short) icmpv6RaFlags);

        if (raType == Ipv6RtrAdvertType.CEASE_ADVERTISEMENT) {
            raPacket.setRouterLifetime(0);
        } else {
            raPacket.setRouterLifetime(Ipv6Constants.IPV6_ROUTER_LIFETIME);
        }
        raPacket.setReachableTime((long) 0);
        raPacket.setRetransTime((long) 0);

        raPacket.setOptionSourceAddr((short)1);
        raPacket.setSourceAddrLength((short)1);
        raPacket.setSourceLlAddress(MacAddress.getDefaultInstance(gatewayMac));

        List<PrefixList> prefixList = new ArrayList<PrefixList>();
        PrefixListBuilder prefix = new PrefixListBuilder();
        prefix.setOptionType((short)3);
        prefix.setOptionLength((short)4);
        // Note: EUI-64 auto-configuration requires 64 bits.
        prefix.setPrefixLength((short)64);
        prefix.setValidLifetime((long) Ipv6Constants.IPV6_RA_VALID_LIFETIME);
        prefix.setPreferredLifetime((long) Ipv6Constants.IPV6_RA_PREFERRED_LIFETIME);
        prefix.setReserved((long) 0);

        short autoConfPrefixFlags = 0;
        autoConfPrefixFlags = (short) (autoConfPrefixFlags | (1 << 7)); // On-link flag
        autoConfPrefixFlags = (short) (autoConfPrefixFlags | (1 << 6)); // Autonomous address-configuration flag.
        for (String v6Prefix : autoConfigPrefixList) {
            prefix.setFlags((short)autoConfPrefixFlags);
            prefix.setPrefix(new Ipv6Prefix(v6Prefix));
            prefixList.add(prefix.build());
        }

        short statefulPrefixFlags = 0;
        statefulPrefixFlags = (short) (statefulPrefixFlags | (1 << 7)); // On-link flag
        for (String v6Prefix : statefulConfigPrefixList) {
            prefix.setFlags((short)statefulPrefixFlags);
            prefix.setPrefix(new Ipv6Prefix(v6Prefix));
            prefixList.add(prefix.build());
        }

        raPacket.setPrefixList((List<PrefixList>) prefixList);

        return;
    }

    private byte[] fillRouterAdvertisementPacket(RouterAdvertisementPacket pdu) {
        ByteBuffer buf = ByteBuffer.allocate(Ipv6Constants.ICMPV6_OFFSET + pdu.getIpv6Length());

        buf.put(ipv6Utils.convertEthernetHeaderToByte((EthernetHeader)pdu), 0, 14);
        buf.put(ipv6Utils.convertIpv6HeaderToByte((Ipv6Header)pdu), 0, 40);
        buf.put(icmp6RAPayloadtoByte(pdu), 0, pdu.getIpv6Length());
        int checksum = ipv6Utils.calcIcmpv6Checksum(buf.array(), (Ipv6Header) pdu);
        buf.putShort((Ipv6Constants.ICMPV6_OFFSET + 2), (short)checksum);
        return (buf.array());
    }

    private byte[] icmp6RAPayloadtoByte(RouterAdvertisementPacket pdu) {
        byte[] data = new byte[pdu.getIpv6Length()];
        Arrays.fill(data, (byte)0);

        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.put((byte)pdu.getIcmp6Type().shortValue());
        buf.put((byte)pdu.getIcmp6Code().shortValue());
        buf.putShort((short)pdu.getIcmp6Chksum().intValue());
        buf.put((byte)pdu.getCurHopLimit().shortValue());
        buf.put((byte)pdu.getFlags().shortValue());
        buf.putShort((short)pdu.getRouterLifetime().intValue());
        buf.putInt((int)pdu.getReachableTime().longValue());
        buf.putInt((int)pdu.getRetransTime().longValue());
        buf.put((byte)pdu.getOptionSourceAddr().shortValue());
        buf.put((byte)pdu.getSourceAddrLength().shortValue());
        buf.put(ipv6Utils.bytesFromHexString(pdu.getSourceLlAddress().getValue().toString()));

        for (PrefixList prefix : pdu.getPrefixList()) {
            buf.put((byte)prefix.getOptionType().shortValue());
            buf.put((byte)prefix.getOptionLength().shortValue());
            buf.put((byte)prefix.getPrefixLength().shortValue());
            buf.put((byte)prefix.getFlags().shortValue());
            buf.putInt((int)prefix.getValidLifetime().longValue());
            buf.putInt((int)prefix.getPreferredLifetime().longValue());
            buf.putInt((int)prefix.getReserved().longValue());
            buf.put(IetfInetUtil.INSTANCE.ipv6PrefixToBytes(new Ipv6Prefix(prefix.getPrefix())),0,16);
        }
        return data;
    }
}
