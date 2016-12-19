/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.primitives.Ints;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import org.opendaylight.controller.liblldp.NetUtils;
import org.opendaylight.controller.liblldp.Packet;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.packet.Ethernet;
import org.opendaylight.genius.mdsalutil.packet.IPv4;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.tag.name.map.ElanTagName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.SubnetOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnIdToVpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIdsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NetworkMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketReceived;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.TransmitPacketInput;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubnetRoutePacketInHandler implements PacketProcessingListener {
    private static final Logger LOG = LoggerFactory.getLogger(SubnetRoutePacketInHandler.class);
    private final DataBroker dataBroker;
    private final PacketProcessingService packetService;

    public SubnetRoutePacketInHandler(final DataBroker dataBroker,
                                      final PacketProcessingService packetService) {
        this.dataBroker = dataBroker;
        this.packetService =packetService;
    }

    public void onPacketReceived(PacketReceived notification) {
        LOG.trace("SubnetRoutePacketInHandler: PacketReceived invoked...");

        short tableId = notification.getTableId().getValue();
        byte[] data = notification.getPayload();
        if (notification.getMatch() == null || notification.getMatch().getMetadata() == null) {
            LOG.debug("on packet received where the match or metadata are null");
            return;
        }
        BigInteger metadata = notification.getMatch().getMetadata().getMetadata();
        Ethernet res = new Ethernet();

        if (tableId == NwConstants.L3_SUBNET_ROUTE_TABLE) {
            LOG.trace("SubnetRoutePacketInHandler: Some packet received as {}", notification);
            try {
                res.deserialize(data, 0, data.length * NetUtils.NumBitsInAByte);
            } catch (Exception e) {
                LOG.warn("SubnetRoutePacketInHandler: Failed to decode Packet ", e);
                return;
            }
            try {
                Packet pkt = res.getPayload();
                if (pkt instanceof IPv4) {
                    IPv4 ipv4 = (IPv4) pkt;
                    byte[] srcMac = res.getSourceMACAddress();
                    byte[] dstMac = res.getDestinationMACAddress();
                    byte[] srcIp = Ints.toByteArray(ipv4.getSourceAddress());
                    byte[] dstIp = Ints.toByteArray(ipv4.getDestinationAddress());
                    String dstIpStr = toStringIpAddress(dstIp);
                    String srcIpStr = toStringIpAddress(srcIp);
                    /*if (VpnUtil.getNeutronPortNamefromPortFixedIp(dataBroker, dstIpStr) != null) {
                        LOG.debug("SubnetRoutePacketInHandler: IPv4 Packet received with "
                                + "Target IP {} is a valid Neutron port, ignoring subnet route processing", dstIpStr);
                        return;
                    }*/
                    long vpnId = MetaDataUtil.getVpnIdFromMetadata(metadata);
                    LOG.info("SubnetRoutePacketInHandler: Processing IPv4 Packet received with Source IP {} "
                            + "and Target IP {} and vpnId {}", srcIpStr, dstIpStr, vpnId);

                    InstanceIdentifier<VpnIds> vpnIdsInstanceIdentifier = getVpnIdToVpnInstanceIdentifier(vpnId);
                    Optional<VpnIds> vpnIdsOptional = VpnUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, vpnIdsInstanceIdentifier);
                    if(!vpnIdsOptional.isPresent()) {
                        // Donot trigger subnetroute logic for packets from unknown VPNs
                        LOG.info("Ignoring IPv4 packet with destination Ip {} and source Ip {} as it came on unknown VPN with ID {}", dstIpStr, srcIpStr, vpnId);
                        return;
                    }
                    // It is an ARP request on a configured VPN.  So we must attempt to respond.
                    VpnIds vpnIds = vpnIdsOptional.get();
                    if (VpnUtil.getNeutronPortFromVpnPortFixedIp(dataBroker, vpnIds.getVpnInstanceName(), dstIpStr) !=
                            null) {
                        LOG.debug("SubnetRoutePacketInHandler: IPv4 Packet received with "
                                + "Target IP {} is a valid Neutron port, ignoring subnet route processing", dstIpStr);
                        return;
                    }
                    long elanTag = getElanTagFromSubnetRouteMetadata(metadata);
                    if (elanTag == 0) {
                        LOG.error("SubnetRoutePacketInHandler: elanTag value from metadata found to be 0, for IPv4 " +
                                " Packet received with Target IP {}", dstIpStr);
                        return;
                    }
                    LOG.info("SubnetRoutePacketInHandler: Processing IPv4 Packet received with Source IP {} "
                            + "and Target IP {} and elan Tag {}", srcIpStr, dstIpStr, elanTag);
                    BigInteger dpnId = getTargetDpnForPacketOut(dataBroker, elanTag, ipv4.getDestinationAddress());
                    //Handle subnet routes ip requests
                    if (dpnId != BigInteger.ZERO) {
                        long groupid = VpnUtil.getRemoteBCGroup(elanTag);
                        String key = srcIpStr + dstIpStr;
                        TransmitPacketInput arpRequestInput = ArpUtils.createArpRequestInput(dpnId, groupid, srcMac, srcIp, dstIp);
                        packetService.transmitPacket(arpRequestInput);
                    }
                    return;
                }
            } catch (Exception ex) {
                //Failed to handle packet
                LOG.error("SubnetRoutePacketInHandler: Failed to handle subnetroute packets ", ex);
            }
            return;
        }
        //All Arp responses learning for invisble IPs is handled by ArpNotificationHandler

    }

    private static BigInteger getTargetDpnForPacketOut(DataBroker broker, long elanTag, int ipAddress) {
        BigInteger dpnid = BigInteger.ZERO;
        ElanTagName elanInfo = VpnUtil.getElanInfoByElanTag(broker, elanTag);
        if (elanInfo == null) {
            LOG.trace("SubnetRoutePacketInHandler: Unable to retrieve ElanInfo for elanTag {}", elanTag);
            return dpnid;
        }
        InstanceIdentifier<NetworkMap> networkId = InstanceIdentifier.builder(NetworkMaps.class)
                .child(NetworkMap.class, new NetworkMapKey(new Uuid(elanInfo.getName()))).build();

        Optional<NetworkMap> optionalNetworkMap = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, networkId);
        if (optionalNetworkMap.isPresent()) {
            List<Uuid> subnetList = optionalNetworkMap.get().getSubnetIdList();
            LOG.trace("SubnetRoutePacketInHandler: Obtained subnetList as " + subnetList);
            for (Uuid subnetId : subnetList) {
                InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                        child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
                Optional<SubnetOpDataEntry> optionalSubs = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL,
                        subOpIdentifier);
                if (!optionalSubs.isPresent()) {
                    continue;
                }
                SubnetOpDataEntry subOpEntry = optionalSubs.get();
                if (subOpEntry.getNhDpnId() != null) {
                    LOG.trace("SubnetRoutePacketInHandler: Viewing Subnet " + subnetId);
                    boolean match = VpnUtil.isIpInSubnet(ipAddress, subOpEntry.getSubnetCidr());
                    LOG.trace("SubnetRoutePacketInHandler: Viewing Subnet " + subnetId + " matching " + match);
                    if (match) {
                        dpnid = subOpEntry.getNhDpnId();
                        return dpnid;
                    }
                }
            }
        }
        return dpnid;
    }

    private static String toStringIpAddress(byte[] ipAddress)
    {
        String ip = null;
        if (ipAddress == null) {
            return ip;
        }

        try {
            ip = InetAddress.getByAddress(ipAddress).getHostAddress();
        } catch(UnknownHostException e) {
            LOG.error("SubnetRoutePacketInHandler: Unable to translate byt[] ipAddress to String {}", e);
        }

        return ip;
    }

    public static long getElanTagFromSubnetRouteMetadata(BigInteger metadata) {
        return ((metadata.and(MetaDataUtil.METADATA_MASK_ELAN_SUBNET_ROUTE)).shiftRight(32)).longValue();
    }

    static InstanceIdentifier<VpnIds>
    getVpnIdToVpnInstanceIdentifier(long vpnId) {
        return InstanceIdentifier.builder(VpnIdToVpnInstance.class)
                .child(VpnIds.class,
                        new VpnIdsKey(Long.valueOf(vpnId))).build();
    }
}
