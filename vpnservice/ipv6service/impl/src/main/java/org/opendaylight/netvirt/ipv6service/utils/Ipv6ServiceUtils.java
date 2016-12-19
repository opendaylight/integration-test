/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import com.google.common.base.Optional;
import com.google.common.net.InetAddresses;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ExecutionException;
import org.apache.commons.lang3.StringUtils;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceBindings;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceTypeFlowBased;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.EthernetHeader;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ipv6service.nd.packet.rev160620.Ipv6Header;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ipv6ServiceUtils {
    private static final Logger LOG = LoggerFactory.getLogger(Ipv6ServiceUtils.class);
    private ConcurrentMap<String, InstanceIdentifier<Flow>> icmpv6FlowMap;
    public static final Ipv6ServiceUtils INSTANCE = new Ipv6ServiceUtils();
    public static Ipv6Address ALL_NODES_MCAST_ADDR;
    public static Ipv6Address UNSPECIFIED_ADDR;

    public Ipv6ServiceUtils() {
        icmpv6FlowMap = new ConcurrentHashMap<>();
        try {
            UNSPECIFIED_ADDR = Ipv6Address.getDefaultInstance(
                    InetAddress.getByName("0:0:0:0:0:0:0:0").getHostAddress());
            ALL_NODES_MCAST_ADDR = Ipv6Address.getDefaultInstance(InetAddress.getByName("FF02::1").getHostAddress());
        } catch (UnknownHostException e) {
            LOG.error("Ipv6ServiceUtils: Failed to instantiate the ipv6 address", e);
        }
    }

    public static Ipv6ServiceUtils getInstance() {
        return INSTANCE;
    }

    /**
     * Retrieves the object from the datastore.
     * @param broker the data broker.
     * @param datastoreType the data store type.
     * @param path the wild card path.
     * @return the required object.
     */
    public static <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType,
                                                          InstanceIdentifier<T> path) {
        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();
        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        } finally {
            tx.close();
        }
        return result;
    }

    /**
     * Retrieves the Interface from the datastore.
     * @param broker the data broker
     * @param interfaceName the interface name
     * @return the interface.
     */
    public static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
        .Interface getInterface(DataBroker broker, String interfaceName) {
        Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
            .Interface> optInterface =
                read(broker, LogicalDatastoreType.CONFIGURATION, getInterfaceIdentifier(interfaceName));
        if (optInterface.isPresent()) {
            return optInterface.get();
        }
        return null;
    }

    /**
     * Builds the interface identifier.
     * @param interfaceName the interface name.
     * @return the interface identifier.
     */
    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508
            .interfaces.Interface> getInterfaceIdentifier(String interfaceName) {
        return InstanceIdentifier.builder(Interfaces.class)
                .child(
                        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces
                                .Interface.class, new InterfaceKey(interfaceName)).build();
    }

    public String bytesToHexString(byte[] bytes) {
        if (bytes == null) {
            return "null";
        }
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < bytes.length; i++) {
            if (i > 0) {
                buf.append(":");
            }
            short u8byte = (short) (bytes[i] & 0xff);
            String tmp = Integer.toHexString(u8byte);
            if (tmp.length() == 1) {
                buf.append("0");
            }
            buf.append(tmp);
        }
        return buf.toString();
    }

    public byte[] bytesFromHexString(String values) {
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

    public int calcIcmpv6Checksum(byte[] packet, Ipv6Header ip6Hdr) {
        long checksum = getSummation(ip6Hdr.getSourceIpv6());
        checksum += getSummation(ip6Hdr.getDestinationIpv6());
        checksum = normalizeChecksum(checksum);

        checksum += ip6Hdr.getIpv6Length();
        checksum += ip6Hdr.getNextHeader();

        int icmp6Offset = Ipv6Constants.ICMPV6_OFFSET;
        long value = (((packet[icmp6Offset] & 0xff) << 8) | (packet[icmp6Offset + 1] & 0xff));
        checksum += value;
        checksum = normalizeChecksum(checksum);
        icmp6Offset += 2;

        //move to icmp6 payload skipping the checksum field
        icmp6Offset += 2;
        int length = packet.length - icmp6Offset;
        while (length > 1) {
            value = (((packet[icmp6Offset] & 0xff) << 8) | (packet[icmp6Offset + 1] & 0xff));
            checksum += value;
            checksum = normalizeChecksum(checksum);
            icmp6Offset += 2;
            length -= 2;
        }

        if (length > 0) {
            checksum += packet[icmp6Offset];
            checksum = normalizeChecksum(checksum);
        }

        int finalChecksum = (int)(~checksum & 0xffff);
        return finalChecksum;
    }

    public boolean validateChecksum(byte[] packet, Ipv6Header ip6Hdr, int recvChecksum) {
        int checksum = calcIcmpv6Checksum(packet, ip6Hdr);

        if (checksum == recvChecksum) {
            return true;
        }
        return false;
    }

    private long getSummation(Ipv6Address addr) {
        byte[] baddr = null;
        try {
            baddr = InetAddress.getByName(addr.getValue()).getAddress();
        } catch (UnknownHostException e) {
            LOG.error("getSummation: Failed to deserialize address {}", addr.getValue(), e);
        }

        long sum = 0;
        int len = 0;
        long value = 0;
        while (len < baddr.length) {
            value = (((baddr[len] & 0xff) << 8) | (baddr[len + 1] & 0xff));
            sum += value;
            sum = normalizeChecksum(sum);
            len += 2;
        }
        return sum;
    }

    private long normalizeChecksum(long value) {
        if ((value & 0xffff0000) > 0) {
            value = (value & 0xffff);
            value += 1;
        }
        return value;
    }

    public byte[] convertEthernetHeaderToByte(EthernetHeader ethPdu) {
        byte[] data = new byte[16];
        Arrays.fill(data, (byte)0);

        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.put(bytesFromHexString(ethPdu.getDestinationMac().getValue().toString()));
        buf.put(bytesFromHexString(ethPdu.getSourceMac().getValue().toString()));
        buf.putShort((short)ethPdu.getEthertype().intValue());
        return data;
    }

    public byte[] convertIpv6HeaderToByte(Ipv6Header ip6Pdu) {
        byte[] data = new byte[128];
        Arrays.fill(data, (byte)0);

        ByteBuffer buf = ByteBuffer.wrap(data);
        long flowLabel = (((long)(ip6Pdu.getVersion().shortValue() & 0x0f) << 28)
                | (ip6Pdu.getFlowLabel().longValue() & 0x0fffffff));
        buf.putInt((int)flowLabel);
        buf.putShort((short)ip6Pdu.getIpv6Length().intValue());
        buf.put((byte)ip6Pdu.getNextHeader().shortValue());
        buf.put((byte)ip6Pdu.getHopLimit().shortValue());
        try {
            byte[] baddr = InetAddress.getByName(ip6Pdu.getSourceIpv6().getValue()).getAddress();
            buf.put(baddr);
            baddr = InetAddress.getByName(ip6Pdu.getDestinationIpv6().getValue()).getAddress();
            buf.put(baddr);
        } catch (UnknownHostException e) {
            LOG.error("convertIpv6HeaderToByte: Failed to serialize src, dest address", e);
        }
        return data;
    }

    public Ipv6Address getIpv6LinkLocalAddressFromMac(MacAddress mac) {
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

        // Return the address in its fully expanded format.
        Ipv6Address ipv6LLA = new Ipv6Address(InetAddresses.forString(
                "fe80:0:0:0:" + interfaceID.toString()).getHostAddress());
        return ipv6LLA;
    }

    private static List<MatchInfo> getIcmpv6RSMatch(Long elanTag) {
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.IPV6ICMP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.icmp_v6,
                new long[] { Ipv6Constants.ICMP_V6_RS_CODE, 0}));
        matches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { ElanUtils.getElanMetadataLabel(elanTag), MetaDataUtil.METADATA_MASK_SERVICE}));
        return matches;
    }

    private List<MatchInfo> getIcmpv6NSMatch(Long elanTag, String ndTarget) {
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
        matches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { IPProtocols.IPV6ICMP.intValue() }));
        matches.add(new MatchInfo(MatchFieldType.icmp_v6,
                new long[] { Ipv6Constants.ICMP_V6_NS_CODE, 0}));
        matches.add(new MatchInfo(MatchFieldType.ipv6_nd_target,
                new String[] { ndTarget }));
        matches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { ElanUtils.getElanMetadataLabel(elanTag), MetaDataUtil.METADATA_MASK_SERVICE}));
        return matches;
    }

    private static String getIPv6FlowRef(BigInteger dpId, Long elanTag, String flowType) {
        return new StringBuffer().append(Ipv6Constants.FLOWID_PREFIX)
                .append(dpId).append(Ipv6Constants.FLOWID_SEPARATOR)
                .append(elanTag).append(Ipv6Constants.FLOWID_SEPARATOR)
                .append(flowType).toString();
    }

    public void installIcmpv6NsPuntFlow(short tableId, BigInteger dpId,  Long elanTag, String ipv6Address,
                                        IMdsalApiManager mdsalUtil,int addOrRemove) {
        List<MatchInfo> neighborSolicitationMatch = getIcmpv6NSMatch(elanTag, ipv6Address);
        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller,
                new String[] {}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions,
                actionsInfos));
        FlowEntity rsFlowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                getIPv6FlowRef(dpId, elanTag, ipv6Address),Ipv6Constants.DEFAULT_FLOW_PRIORITY, "IPv6NS",
                0, 0, NwConstants.COOKIE_IPV6_TABLE, neighborSolicitationMatch, instructions);
        if (addOrRemove == Ipv6Constants.DEL_FLOW) {
            LOG.trace("Removing IPv6 Neighbor Solicitation Flow DpId {}, elanTag {}", dpId, elanTag);
            mdsalUtil.removeFlow(rsFlowEntity);
        } else {
            LOG.trace("Installing IPv6 Neighbor Solicitation Flow DpId {}, elanTag {}", dpId, elanTag);
            mdsalUtil.installFlow(rsFlowEntity);
        }
    }

    public void installIcmpv6RsPuntFlow(short tableId, BigInteger dpId, Long elanTag, IMdsalApiManager mdsalUtil,
                                        int addOrRemove) {
        if (dpId == null || dpId.equals(Ipv6Constants.INVALID_DPID)) {
            return;
        }
        List<MatchInfo> routerSolicitationMatch = getIcmpv6RSMatch(elanTag);
        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        // Punt to controller
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller,
                new String[] {}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions,
                actionsInfos));
        FlowEntity rsFlowEntity = MDSALUtil.buildFlowEntity(dpId, tableId,
                getIPv6FlowRef(dpId, elanTag, "IPv6RS"),Ipv6Constants.DEFAULT_FLOW_PRIORITY, "IPv6RS", 0, 0,
                NwConstants.COOKIE_IPV6_TABLE, routerSolicitationMatch, instructions);
        if (addOrRemove == Ipv6Constants.DEL_FLOW) {
            LOG.trace("Removing IPv6 Router Solicitation Flow DpId {}, elanTag {}", dpId, elanTag);
            mdsalUtil.removeFlow(rsFlowEntity);
        } else {
            LOG.trace("Installing IPv6 Router Solicitation Flow DpId {}, elanTag {}", dpId, elanTag);
            mdsalUtil.installFlow(rsFlowEntity);
        }
    }

    public BoundServices getBoundServices(String serviceName, short servicePriority, int flowPriority,
                                          BigInteger cookie, List<Instruction> instructions) {
        StypeOpenflowBuilder augBuilder = new StypeOpenflowBuilder().setFlowCookie(cookie)
                .setFlowPriority(flowPriority).setInstruction(instructions);
        return new BoundServicesBuilder().setKey(new BoundServicesKey(servicePriority))
                .setServiceName(serviceName).setServicePriority(servicePriority)
                .setServiceType(ServiceTypeFlowBased.class)
                .addAugmentation(StypeOpenflow.class, augBuilder.build()).build();
    }

    private InstanceIdentifier buildServiceId(String interfaceName,
                                              short priority) {
        return InstanceIdentifier.builder(ServiceBindings.class).child(ServicesInfo.class,
                new ServicesInfoKey(interfaceName, ServiceModeIngress.class))
                .child(BoundServices.class, new BoundServicesKey(priority)).build();
    }

    public void bindIpv6Service(DataBroker broker, String interfaceName, Long elanTag, short tableId) {
        int instructionKey = 0;
        List<Instruction> instructions = new ArrayList<>();
        instructions.add(MDSALUtil.buildAndGetWriteMetadaInstruction(ElanUtils.getElanMetadataLabel(elanTag),
                MetaDataUtil.METADATA_MASK_SERVICE, ++instructionKey));
        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(tableId, ++instructionKey));
        short serviceIndex = ServiceIndex.getIndex(NwConstants.IPV6_SERVICE_NAME, NwConstants.IPV6_SERVICE_INDEX);
        BoundServices
                serviceInfo =
                getBoundServices(String.format("%s.%s", "ipv6", interfaceName),
                        serviceIndex, Ipv6Constants.DEFAULT_FLOW_PRIORITY,
                        NwConstants.COOKIE_IPV6_TABLE, instructions);
        MDSALUtil.syncWrite(broker, LogicalDatastoreType.CONFIGURATION,
                buildServiceId(interfaceName, serviceIndex), serviceInfo);
    }

    public void unbindIpv6Service(DataBroker broker, String interfaceName) {
        MDSALUtil.syncDelete(broker, LogicalDatastoreType.CONFIGURATION,
                buildServiceId(interfaceName, ServiceIndex.getIndex(NwConstants.IPV6_SERVICE_NAME,
                        NwConstants.IPV6_SERVICE_INDEX)));
    }

    public static BigInteger getDataPathId(String dpId) {
        long dpid = 0L;
        if (dpId != null) {
            dpid = new BigInteger(dpId.replaceAll(":", ""), 16).longValue();
        }
        return BigInteger.valueOf(dpid);
    }
}
