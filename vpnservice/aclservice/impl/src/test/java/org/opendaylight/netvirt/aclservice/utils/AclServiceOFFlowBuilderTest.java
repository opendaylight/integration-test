/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import static com.google.common.collect.Iterables.filter;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import com.google.common.collect.Iterables;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.junit.Test;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.Matches;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIpBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv4Builder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;


public class AclServiceOFFlowBuilderTest {

    @Test
    public void testProgramIpFlow_NullMatches() {
        Matches matches = null;
        Map<String, List<MatchInfoBase>> flowMap = AclServiceOFFlowBuilder.programIpFlow(matches);
        assertNull(flowMap);
    }

    @Test
    public void testprogramOtherProtocolFlow() {
        AceIpBuilder builder = AclServiceTestUtils.prepareAceIpBuilder("10.1.1.1/24", "20.1.1.1/24", null, null,
                (short) 1);
        Map<String, List<MatchInfoBase>> flowMatchesMap =
                AclServiceOFFlowBuilder.programOtherProtocolFlow(builder.build());
        List<MatchInfoBase> flowMatches = flowMatchesMap.get("OTHER_PROTO" + "1");
        AclServiceTestUtils.verifyGeneralFlows(flowMatches, "1", "10.1.1.1", "20.1.1.1", "24");
    }

    @Test
    public void testprogramIcmpFlow() {
        AceIpBuilder builder = AclServiceTestUtils.prepareAceIpBuilder("10.1.1.1/24", "20.1.1.1/24", "1024", "2048",
                (short) 1);
        Map<String, List<MatchInfoBase>> flowMatchesMap = AclServiceOFFlowBuilder.programIcmpFlow(builder.build());
        List<MatchInfoBase> flowMatches = flowMatchesMap.entrySet().iterator().next().getValue();

        AclServiceTestUtils.verifyGeneralFlows(flowMatches, "1", "10.1.1.1", "20.1.1.1", "24");

        Iterable<MatchInfoBase> icmpv4Matches = filter(flowMatches,
                (item -> ((MatchInfo) item).getMatchField().equals(MatchFieldType.icmp_v4)));
        AclServiceTestUtils.verifyMatchValues((MatchInfo) Iterables.get(icmpv4Matches, 0), "1024", "2048");
        AclServiceTestUtils.verifyMatchValues((MatchInfo) Iterables.get(icmpv4Matches, 1), "1024", "2048");
    }

    @Test
    public void testprogramTcpFlow_NoSrcDstPortRange() {
        AceIpBuilder builder = AclServiceTestUtils.prepareAceIpBuilder("10.1.1.1/24", "20.1.1.1/24", null, null,
                (short) 1);

        Map<String, List<MatchInfoBase>> flowMatchesMap = AclServiceOFFlowBuilder.programTcpFlow(builder.build());
        List<MatchInfoBase> flowMatches = flowMatchesMap.get("TCP_SOURCE_ALL_");

        AclServiceTestUtils.verifyGeneralFlows(flowMatches, "1", "10.1.1.1", "20.1.1.1", "24");
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, NxMatchFieldType.nx_tcp_src_with_mask);
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, NxMatchFieldType.nx_tcp_dst_with_mask);
    }

    @Test
    public void testprogramTcpFlow_WithSrcDstPortRange() {
        AceIpBuilder builder = AclServiceTestUtils.prepareAceIpBuilder("10.1.1.1/24", "20.1.1.1/24", "1024", "1024",
                (short) 1);

        Map<String, List<MatchInfoBase>> flowMatchesMap = AclServiceOFFlowBuilder.programTcpFlow(builder.build());

        List<MatchInfoBase> srcFlowMatches = new ArrayList<MatchInfoBase>();
        List<MatchInfoBase> dstFlowMatches = new ArrayList<MatchInfoBase>();

        for (String flowId : flowMatchesMap.keySet()) {
            if (flowId.startsWith("TCP_SOURCE_")) {
                srcFlowMatches.addAll(flowMatchesMap.get(flowId));
            }
            if (flowId.startsWith("TCP_DESTINATION_")) {
                dstFlowMatches.addAll(flowMatchesMap.get(flowId));
            }
        }

        AclServiceTestUtils.verifyGeneralFlows(srcFlowMatches, "1", "10.1.1.1", "20.1.1.1", "24");
        Iterable<MatchInfoBase> nxSrcMatches = filter(srcFlowMatches,
            (item -> item instanceof NxMatchInfo) );
        Iterable<MatchInfoBase> tcpSrcMatches = filter(nxSrcMatches,
                (item -> ((NxMatchInfo) item).getMatchField().equals(NxMatchFieldType.nx_tcp_src_with_mask)));

        AclServiceTestUtils.verifyMatchValues((NxMatchInfo) Iterables.getFirst(tcpSrcMatches, null), "1024", "65535");

        AclServiceTestUtils.verifyGeneralFlows(dstFlowMatches, "1", "10.1.1.1", "20.1.1.1", "24");
        Iterable<MatchInfoBase> nxDstMatches = filter(dstFlowMatches,
            (item -> item instanceof NxMatchInfo) );
        Iterable<MatchInfoBase> tcpDstMatches = filter(nxDstMatches,
                (item -> ((NxMatchInfo) item).getMatchField().equals(NxMatchFieldType.nx_tcp_dst_with_mask)));

        AclServiceTestUtils.verifyMatchValues((NxMatchInfo) Iterables.getFirst(tcpDstMatches, null), "1024", "65535");
    }

    @Test
    public void testProgramUdpFlow_NoSrcDstPortRange() {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        v4builder.setSourceIpv4Network(new Ipv4Prefix("10.1.1.1/24"));
        v4builder.setDestinationIpv4Network(new Ipv4Prefix("20.1.1.1/24"));
        builder.setAceIpVersion(v4builder.build());
        builder.setSourcePortRange(null);
        builder.setDestinationPortRange(null);
        short protocol = 1;
        builder.setProtocol(protocol);

        Map<String, List<MatchInfoBase>> flowMatchesMap = AclServiceOFFlowBuilder.programUdpFlow(builder.build());

        List<MatchInfoBase> flowMatches = flowMatchesMap.get("UDP_SOURCE_ALL_");

        AclServiceTestUtils.verifyGeneralFlows(flowMatches, "1", "10.1.1.1", "20.1.1.1", "24");
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, NxMatchFieldType.nx_udp_src_with_mask);
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, NxMatchFieldType.nx_udp_dst_with_mask);
    }

    @Test
    public void testprogramUdpFlow_WithSrcDstPortRange() {
        AceIpBuilder builder = AclServiceTestUtils.prepareAceIpBuilder("10.1.1.1/24", "20.1.1.1/24", "1024", "1024",
                (short) 1);

        Map<String, List<MatchInfoBase>> flowMatchesMap = AclServiceOFFlowBuilder.programUdpFlow(builder.build());
        List<MatchInfoBase> srcFlowMatches = new ArrayList<MatchInfoBase>();
        List<MatchInfoBase> dstFlowMatches = new ArrayList<MatchInfoBase>();

        for (String flowId : flowMatchesMap.keySet()) {
            if (flowId.startsWith("UDP_SOURCE_")) {
                srcFlowMatches.addAll(flowMatchesMap.get(flowId));
            }
            if (flowId.startsWith("UDP_DESTINATION_")) {
                dstFlowMatches.addAll(flowMatchesMap.get(flowId));
            }
        }

        AclServiceTestUtils.verifyGeneralFlows(srcFlowMatches, "1", "10.1.1.1", "20.1.1.1", "24");

        Iterable<MatchInfoBase> nxSrcMatches = filter(srcFlowMatches,
            (item -> item instanceof NxMatchInfo) );
        Iterable<MatchInfoBase> udpSrcMatches = filter(nxSrcMatches,
                (item -> ((NxMatchInfo) item).getMatchField().equals(NxMatchFieldType.nx_udp_src_with_mask)));
        AclServiceTestUtils.verifyMatchValues((NxMatchInfo) Iterables.getFirst(udpSrcMatches, null), "1024", "65535");

        AclServiceTestUtils.verifyGeneralFlows(dstFlowMatches, "1", "10.1.1.1", "20.1.1.1", "24");

        Iterable<MatchInfoBase> nxDstMatches = filter(dstFlowMatches,
            (item -> item instanceof NxMatchInfo) );
        Iterable<MatchInfoBase> udpDstMatches = filter(nxDstMatches,
                (item -> ((NxMatchInfo) item).getMatchField().equals(NxMatchFieldType.nx_udp_dst_with_mask)));
        AclServiceTestUtils.verifyMatchValues((NxMatchInfo) Iterables.getFirst(udpDstMatches, null), "1024", "65535");
    }

    @Test
    public void testaddDstIpMatches_v4() {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        v4builder.setDestinationIpv4Network(new Ipv4Prefix("10.1.1.1/24"));
        builder.setAceIpVersion(v4builder.build());

        List<MatchInfoBase> flowMatches = AclServiceOFFlowBuilder.addDstIpMatches(builder.build());

        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.eth_type,
                Integer.toString(NwConstants.ETHTYPE_IPV4));
        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.ipv4_destination, "10.1.1.1", "24");
    }

    @Test
    public void testaddDstIpMatches_v4NoDstNetwork() {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        v4builder.setDestinationIpv4Network(null);
        builder.setAceIpVersion(v4builder.build());

        List<MatchInfoBase> flowMatches = AclServiceOFFlowBuilder.addDstIpMatches(builder.build());

        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.eth_type,
                Integer.toString(NwConstants.ETHTYPE_IPV4));
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, MatchFieldType.ipv4_destination);
    }

    @Test
    public void testaddSrcIpMatches_v4() {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        v4builder.setSourceIpv4Network(new Ipv4Prefix("10.1.1.1/24"));
        builder.setAceIpVersion(v4builder.build());

        List<MatchInfoBase> flowMatches = AclServiceOFFlowBuilder.addSrcIpMatches(builder.build());

        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.eth_type,
                Integer.toString(NwConstants.ETHTYPE_IPV4));
        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.ipv4_source, "10.1.1.1", "24");
    }

    @Test
    public void testaddSrcIpMatches_v4NoSrcNetwork() {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        v4builder.setSourceIpv4Network(null);
        builder.setAceIpVersion(v4builder.build());

        List<MatchInfoBase> flowMatches = AclServiceOFFlowBuilder.addSrcIpMatches(builder.build());
        AclServiceTestUtils.verifyMatchInfo(flowMatches, MatchFieldType.eth_type,
                Integer.toString(NwConstants.ETHTYPE_IPV4));
        AclServiceTestUtils.verifyMatchFieldTypeDontExist(flowMatches, MatchFieldType.ipv4_source);
    }

    @Test
    public void testgetLayer4MaskForRange_SinglePort() {
        Map<Integer, Integer> layer4MaskForRange = AclServiceOFFlowBuilder.getLayer4MaskForRange(1111, 1111);
        assertEquals("port L4 mask missing", 1, layer4MaskForRange.size());
    }

    @Test
    public void testgetLayer4MaskForRange_MultiplePorts() {
        Map<Integer, Integer> layer4MaskForRange = AclServiceOFFlowBuilder.getLayer4MaskForRange(1024, 2048);
        assertEquals("port L4 mask missing", 2, layer4MaskForRange.size());
    }

    @Test
    public void testgetLayer4MaskForRange_IllegalPortRange_ExceedMin() {
        Map<Integer, Integer> layer4MaskForRange = AclServiceOFFlowBuilder.getLayer4MaskForRange(0, 1);

        assertEquals("port L4 mask missing", 1, layer4MaskForRange.size());
    }

    @Test
    public void testgetLayer4MaskForRange_IllegalPortRange_ExceedMax() {
        Map<Integer, Integer> layer4MaskForRange = AclServiceOFFlowBuilder.getLayer4MaskForRange(1, 65536);
        assertEquals("Illegal ports range", 0, layer4MaskForRange.size());
    }

    @Test
    public void testgetLayer4MaskForRange_IllegalPortRange_MinGreaterThanMax() {
        Map<Integer, Integer> layer4MaskForRange = AclServiceOFFlowBuilder.getLayer4MaskForRange(8192, 4096);
        assertEquals("Illegal ports range", 0, layer4MaskForRange.size());
    }
}
