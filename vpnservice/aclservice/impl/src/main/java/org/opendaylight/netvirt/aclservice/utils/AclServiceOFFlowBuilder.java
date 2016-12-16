/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.Matches;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIp;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv4;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv6;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.DestinationPortRange;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.SourcePortRange;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AclServiceOFFlowBuilder {

    private static final Logger LOG =
            LoggerFactory.getLogger(AclServiceOFFlowBuilder.class);

    /**
     * Converts IP matches into flows.
     * @param matches
     *            the matches
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String, List<MatchInfoBase>> programIpFlow(Matches matches) {
        if (matches != null) {
            AceIp acl = (AceIp) matches.getAceType();
            Short protocol = acl.getProtocol();
            if (protocol == null) {
                return programEtherFlow(acl);
            } else if (acl.getProtocol() == NwConstants.IP_PROT_TCP) {
                return programTcpFlow(acl);
            } else if (acl.getProtocol() == NwConstants.IP_PROT_UDP) {
                return programUdpFlow(acl);
            } else if (acl.getProtocol() == NwConstants.IP_PROT_ICMP) {
                return programIcmpFlow(acl);
            } else if (acl.getProtocol() != -1) {
                return programOtherProtocolFlow(acl);
            }
        }
        return null;
    }

    /** Converts ether  matches to flows.
     * @param acl the access control list
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String,List<MatchInfoBase>> programEtherFlow(AceIp acl) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        flowMatches.addAll(addSrcIpMatches(acl));
        flowMatches.addAll(addDstIpMatches(acl));
        String flowId = "ETHER" + acl.getProtocol();
        Map<String,List<MatchInfoBase>> flowMatchesMap = new HashMap<>();
        flowMatchesMap.put(flowId,flowMatches);
        return flowMatchesMap;
    }

    /** Converts generic protocol matches to flows.
     *
     * @param acl the access control list
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String,List<MatchInfoBase>> programOtherProtocolFlow(AceIp acl) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        flowMatches.addAll(addSrcIpMatches(acl));
        flowMatches.addAll(addDstIpMatches(acl));
        if (acl.getAceIpVersion() instanceof AceIpv4 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV4 }));
        } else if (acl.getAceIpVersion() instanceof AceIpv6 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
        }
        flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
            new long[] { acl.getProtocol() }));
        String flowId = "OTHER_PROTO" + acl.getProtocol();
        Map<String,List<MatchInfoBase>> flowMatchesMap = new HashMap<>();
        flowMatchesMap.put(flowId,flowMatches);
        return flowMatchesMap;
    }

    /**Converts icmp matches to flows.
     * @param acl the access control list
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String,List<MatchInfoBase>> programIcmpFlow(AceIp acl) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        flowMatches.addAll(addSrcIpMatches(acl));
        flowMatches.addAll(addDstIpMatches(acl));
        //For ICMP port range indicates type and code
        SourcePortRange sourcePortRange = acl.getSourcePortRange();
        String flowId = "ICMP_";
        if (sourcePortRange != null) {
            if (acl.getAceIpVersion() instanceof AceIpv4 ) {
                flowMatches.add(new MatchInfo(MatchFieldType.icmp_v4,
                    new long[] { sourcePortRange.getLowerPort().getValue(),
                                 sourcePortRange.getUpperPort().getValue() }));
                flowId = flowId + "V4_SOURCE_" + sourcePortRange.getLowerPort().getValue()
                        + sourcePortRange.getUpperPort().getValue();
            } else if (acl.getAceIpVersion() instanceof AceIpv6 ) {
                flowMatches.add(new MatchInfo(MatchFieldType.icmp_v6,
                    new long[] { sourcePortRange.getLowerPort().getValue(),
                                 sourcePortRange.getUpperPort().getValue() }));
                flowId = flowId + "V6_SOURCE_" + sourcePortRange.getLowerPort().getValue() + "_"
                        + sourcePortRange.getUpperPort().getValue() + "_";
            }
        }
        DestinationPortRange destinationPortRange = acl.getDestinationPortRange();
        if (destinationPortRange != null) {
            if (acl.getAceIpVersion() instanceof AceIpv4 ) {
                flowMatches.add(new MatchInfo(MatchFieldType.icmp_v4,
                    new long[] { destinationPortRange.getLowerPort().getValue(),
                                 destinationPortRange.getUpperPort().getValue() }));
                flowId = flowId + "V4_DESTINATION_" + destinationPortRange.getLowerPort().getValue()
                        + destinationPortRange.getUpperPort().getValue() + "_";
            } else if (acl.getAceIpVersion() instanceof AceIpv6 ) {
                flowMatches.add(new MatchInfo(MatchFieldType.icmp_v6,
                    new long[] { destinationPortRange.getLowerPort().getValue(),
                                 destinationPortRange.getUpperPort().getValue() }));
                flowId = flowId + "V6_DESTINATION_" + destinationPortRange.getLowerPort().getValue()
                        + destinationPortRange.getUpperPort().getValue() + "_";
            }
        }
        flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
            new long[] { acl.getProtocol() }));
        Map<String,List<MatchInfoBase>> flowMatchesMap = new HashMap<>();
        flowMatchesMap.put(flowId,flowMatches);
        return flowMatchesMap;
    }

    /**Converts TCP matches to flows.
     * @param acl the access control list
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String,List<MatchInfoBase>> programTcpFlow(AceIp acl) {
        Map<String,List<MatchInfoBase>> flowMatchesMap = new HashMap<>();
        SourcePortRange sourcePortRange = acl.getSourcePortRange();
        DestinationPortRange destinationPortRange = acl.getDestinationPortRange();
        if (sourcePortRange == null && destinationPortRange == null) {
            List<MatchInfoBase> flowMatches = new ArrayList<>();
            flowMatches.addAll(addSrcIpMatches(acl));
            flowMatches.addAll(addDstIpMatches(acl));
            flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { acl.getProtocol() }));
            String flowId = "TCP_SOURCE_ALL_";
            flowMatchesMap.put(flowId,flowMatches);
            return flowMatchesMap;
        }
        if (sourcePortRange != null) {
            Map<Integer, Integer> portMaskMap = getLayer4MaskForRange(sourcePortRange.getLowerPort().getValue(),
                sourcePortRange.getUpperPort().getValue());
            for (Integer port: portMaskMap.keySet()) {
                List<MatchInfoBase> flowMatches = new ArrayList<>();
                flowMatches.addAll(addSrcIpMatches(acl));
                flowMatches.addAll(addDstIpMatches(acl));
                if (portMaskMap.get(port) != AclConstants.ALL_LAYER4_PORT_MASK) {
                    flowMatches.add(new NxMatchInfo(NxMatchFieldType.nx_tcp_src_with_mask,
                        new long[] {  port, portMaskMap.get(port) }));
                }
                flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                    new long[] { acl.getProtocol() }));
                String flowId = "TCP_SOURCE_" + port + "_" + portMaskMap.get(port);
                flowMatchesMap.put(flowId,flowMatches);
            }
        }
        if (destinationPortRange != null) {
            Map<Integer, Integer> portMaskMap = getLayer4MaskForRange(destinationPortRange.getLowerPort().getValue(),
                destinationPortRange.getUpperPort().getValue());
            for (Integer port: portMaskMap.keySet()) {
                List<MatchInfoBase> flowMatches = new ArrayList<>();
                flowMatches.addAll(addSrcIpMatches(acl));
                flowMatches.addAll(addDstIpMatches(acl));
                if (portMaskMap.get(port) != AclConstants.ALL_LAYER4_PORT_MASK) {
                    flowMatches.add(new NxMatchInfo(NxMatchFieldType.nx_tcp_dst_with_mask,
                        new long[] {  port, portMaskMap.get(port) }));
                }
                flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                    new long[] { acl.getProtocol() }));
                String flowId = "TCP_DESTINATION_" + port + "_" + portMaskMap.get(port);
                flowMatchesMap.put(flowId,flowMatches);
            }
        }
        return flowMatchesMap;
    }

    /**Converts UDP matches to flows.
     * @param acl the access control list
     * @return the map containing the flows and the respective flow id
     */
    public static Map<String,List<MatchInfoBase>> programUdpFlow(AceIp acl) {
        Map<String,List<MatchInfoBase>> flowMatchesMap = new HashMap<>();
        SourcePortRange sourcePortRange = acl.getSourcePortRange();
        DestinationPortRange destinationPortRange = acl.getDestinationPortRange();
        if (sourcePortRange == null && destinationPortRange == null) {
            List<MatchInfoBase> flowMatches = new ArrayList<>();
            flowMatches.addAll(addSrcIpMatches(acl));
            flowMatches.addAll(addDstIpMatches(acl));
            flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                new long[] { acl.getProtocol() }));
            String flowId = "UDP_SOURCE_ALL_";
            flowMatchesMap.put(flowId,flowMatches);
            return flowMatchesMap;
        }
        if (sourcePortRange != null) {
            Map<Integer, Integer> portMaskMap = getLayer4MaskForRange(sourcePortRange.getLowerPort().getValue(),
                sourcePortRange.getUpperPort().getValue());
            for (Integer port: portMaskMap.keySet()) {
                List<MatchInfoBase> flowMatches = new ArrayList<>();
                flowMatches.addAll(addSrcIpMatches(acl));
                flowMatches.addAll(addDstIpMatches(acl));
                if (portMaskMap.get(port) != AclConstants.ALL_LAYER4_PORT_MASK) {
                    flowMatches.add(new NxMatchInfo(NxMatchFieldType.nx_udp_src_with_mask,
                        new long[] {  port, portMaskMap.get(port) }));
                }
                flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                    new long[] { acl.getProtocol() }));
                String flowId = "UDP_SOURCE_" + port + "_" + portMaskMap.get(port);
                flowMatchesMap.put(flowId ,flowMatches);
            }
        }
        if (destinationPortRange != null) {
            Map<Integer, Integer> portMaskMap = getLayer4MaskForRange(destinationPortRange.getLowerPort().getValue(),
                destinationPortRange.getUpperPort().getValue());
            for (Integer port: portMaskMap.keySet()) {
                List<MatchInfoBase> flowMatches = new ArrayList<>();
                flowMatches.addAll(addSrcIpMatches(acl));
                flowMatches.addAll(addDstIpMatches(acl));
                if (portMaskMap.get(port) != AclConstants.ALL_LAYER4_PORT_MASK) {
                    flowMatches.add(new NxMatchInfo(NxMatchFieldType.nx_udp_dst_with_mask,
                        new long[] {  port, portMaskMap.get(port) }));
                }
                flowMatches.add(new MatchInfo(MatchFieldType.ip_proto,
                    new long[] { acl.getProtocol() }));
                String flowId = "UDP_DESTINATION_" + port + "_" + portMaskMap.get(port);
                flowMatchesMap.put(flowId, flowMatches);
            }
        }

        return flowMatchesMap;
    }

    /** Adds source ip matches to the flows.
     * @param acl the access control list
     * @return the list of flows.
     */
    public static List<MatchInfoBase> addSrcIpMatches(AceIp acl) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        if (acl.getAceIpVersion() instanceof AceIpv4 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV4 }));
            Ipv4Prefix srcNetwork = ((AceIpv4)acl.getAceIpVersion()).getSourceIpv4Network();
            if (null != srcNetwork && !srcNetwork.getValue().equals(AclConstants.IPV4_ALL_NETWORK)) {
                String[] ipaddressValues = srcNetwork.getValue().split("/");
                flowMatches.add(new MatchInfo(MatchFieldType.ipv4_source,
                    new String[] {ipaddressValues[0], ipaddressValues[1]}));
            }
        } else if (acl.getAceIpVersion() instanceof AceIpv6 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
            Ipv6Prefix srcNetwork = ((AceIpv6)acl.getAceIpVersion()).getSourceIpv6Network();
            if (null != srcNetwork) {
                flowMatches.add(new MatchInfo(MatchFieldType.ipv6_source,
                    new String[] {srcNetwork.getValue()}));
            }
        }
        return flowMatches;
    }

    /** Adds destination ip matches to the flows.
     * @param acl the access control list
     * @return the list of flows.
     */
    public static List<MatchInfoBase> addDstIpMatches(AceIp acl) {
        List<MatchInfoBase> flowMatches = new ArrayList<>();
        if (acl.getAceIpVersion() instanceof AceIpv4 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV4 }));
            Ipv4Prefix dstNetwork = ((AceIpv4)acl.getAceIpVersion()).getDestinationIpv4Network();
            if (null != dstNetwork && !dstNetwork.getValue().equals(AclConstants.IPV4_ALL_NETWORK)) {
                String[] ipaddressValues = dstNetwork.getValue().split("/");
                flowMatches.add(new MatchInfo(MatchFieldType.ipv4_destination,
                    new String[] {ipaddressValues[0], ipaddressValues[1]}));
            }
        } else if (acl.getAceIpVersion() instanceof AceIpv6 ) {
            flowMatches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_IPV6 }));
            Ipv6Prefix dstNetwork = ((AceIpv6)acl.getAceIpVersion()).getDestinationIpv6Network();
            if (null != dstNetwork) {
                flowMatches.add(new MatchInfo(MatchFieldType.ipv6_destination,
                    new String[] {dstNetwork.getValue()}));
            }
        }
        return flowMatches;
    }

    /**
     * Converts port range into a set of masked port ranges.
     *
     * @param portMin the starting port of the range.
     * @param portMax the ending port of the range.
     * @return the map containing the port no and their mask.
     *
     */
    public static Map<Integer,Integer>  getLayer4MaskForRange(int portMin, int portMax) {
        final int[] offset = { 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 };
        final int[] mask = { 0x8000, 0xC000, 0xE000, 0xF000, 0xF800, 0xFC00, 0xFE00, 0xFF00, 0xFF80, 0xFFC0, 0xFFE0,
            0xFFF0, 0xFFF8, 0xFFFC, 0xFFFE, 0xFFFF };
        int noOfPorts = portMax - portMin + 1;
        Map<Integer,Integer> portMap = new HashMap<>();
        if (noOfPorts == 1) {
            portMap.put(portMin, mask[15]);
            return portMap;
        } else if (noOfPorts == AclConstants.ALL_LAYER4_PORT) {
            portMap.put(portMin, AclConstants.ALL_LAYER4_PORT_MASK);
            return portMap;
        }
        if (noOfPorts < 0) { // TODO: replace with infrautils.counter in case of high repetitive usage
            LOG.warn("Cannot convert port range into a set of masked port ranges - Illegal port range {}-{}", portMin,
                    portMax);
            return portMap;
        }
        String binaryNoOfPorts = Integer.toBinaryString(noOfPorts);
        if (binaryNoOfPorts.length() > 16) { // TODO: replace with infrautils.counter in case of high repetitive usage
            LOG.warn("Cannot convert port range into a set of masked port ranges - Illegal port range {}-{}", portMin,
                    portMax);
            return portMap;
        }
        int medianOffset = 16 - binaryNoOfPorts.length();
        int medianLength = offset[medianOffset];
        int median = 0;
        for (int tempMedian = 0;tempMedian < portMax;) {
            tempMedian = medianLength + tempMedian;
            if (portMin < tempMedian) {
                median = tempMedian;
                break;
            }
        }
        int tempMedian = 0;
        int currentMedain = median;
        for (int tempMedianOffset = medianOffset;16 > tempMedianOffset;tempMedianOffset++) {
            tempMedian = currentMedain - offset[tempMedianOffset];
            if (portMin <= tempMedian) {
                for (;portMin <= tempMedian;) {
                    portMap.put(tempMedian, mask[tempMedianOffset]);
                    currentMedain = tempMedian;
                    tempMedian = tempMedian - offset[tempMedianOffset];
                }
            }
        }
        currentMedain = median;
        for (int tempMedianOffset = medianOffset;16 > tempMedianOffset;tempMedianOffset++) {
            tempMedian = currentMedain + offset[tempMedianOffset];
            if (portMax >= tempMedian - 1) {
                for (;portMax >= tempMedian - 1;) {
                    portMap.put(currentMedain, mask[tempMedianOffset]);
                    currentMedain = tempMedian;
                    tempMedian = tempMedian  + offset[tempMedianOffset];
                }
            }
        }
        return portMap;
    }

}
