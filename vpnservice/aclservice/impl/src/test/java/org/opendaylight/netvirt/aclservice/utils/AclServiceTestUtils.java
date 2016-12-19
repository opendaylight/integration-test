/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import static com.google.common.collect.Iterables.filter;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.google.common.collect.Iterables;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ConcurrentMap;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.junit.Assert;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.genius.utils.cache.CacheUtil;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.AccessListEntries;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIpBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv4Builder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.PortNumber;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.DestinationPortRangeBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.SourcePortRangeBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;


public class AclServiceTestUtils {

    public static void verifyGeneralFlows(List<MatchInfoBase> srcFlowMatches, String protocol, String srcIpv4Net,
            String dstIpv4Net, String mask) {
        verifyMatchInfo(srcFlowMatches, MatchFieldType.eth_type, Integer.toString(NwConstants.ETHTYPE_IPV4));
        verifyMatchInfo(srcFlowMatches, MatchFieldType.ip_proto, protocol);
        verifyMatchInfo(srcFlowMatches, MatchFieldType.ipv4_source, srcIpv4Net, mask);
        verifyMatchInfo(srcFlowMatches, MatchFieldType.ipv4_destination, dstIpv4Net, mask);
    }

    public static AceIpBuilder prepareAceIpBuilder(String srcIpv4Net, String dstIpv4Net, String lowerPort,
            String upperPort, short protocol) {
        AceIpBuilder builder = new AceIpBuilder();
        AceIpv4Builder v4builder = new AceIpv4Builder();
        if (srcIpv4Net != null) {
            v4builder.setSourceIpv4Network(new Ipv4Prefix(srcIpv4Net));
        } else {
            v4builder.setSourceIpv4Network(null);
        }

        if (dstIpv4Net != null) {
            v4builder.setDestinationIpv4Network(new Ipv4Prefix(dstIpv4Net));
        } else {
            v4builder.setDestinationIpv4Network(null);
        }
        builder.setAceIpVersion(v4builder.build());
        if (lowerPort != null && upperPort != null) {
            SourcePortRangeBuilder srcPortBuilder = new SourcePortRangeBuilder();
            srcPortBuilder.setLowerPort(PortNumber.getDefaultInstance(lowerPort));
            srcPortBuilder.setUpperPort(PortNumber.getDefaultInstance(upperPort));
            builder.setSourcePortRange(srcPortBuilder.build());
            DestinationPortRangeBuilder dstPortBuilder = new DestinationPortRangeBuilder();
            dstPortBuilder.setLowerPort(PortNumber.getDefaultInstance(lowerPort));
            dstPortBuilder.setUpperPort(PortNumber.getDefaultInstance(upperPort));
            builder.setDestinationPortRange(dstPortBuilder.build());
        }
        builder.setProtocol(protocol);
        return builder;
    }

    public static void verifyMatchInfo(List<MatchInfoBase> flowMatches, MatchFieldType matchType, String... params) {
        Iterable<MatchInfoBase> matches = filter(flowMatches,
            item -> item instanceof MatchInfo && ((MatchInfo) item).getMatchField().equals(matchType)
                 || item instanceof NxMatchInfo && ((NxMatchInfo) item).getMatchField().equals(matchType));
        assertFalse(Iterables.isEmpty(matches));
        for (MatchInfoBase baseMatch : matches) {
            if (baseMatch instanceof MatchInfo) {
                verifyMatchValues((MatchInfo)baseMatch, params);
            } else {
                verifyMatchValues((NxMatchInfo)baseMatch, params);
            }
        }
    }

    public static void verifyMatchInfo(List<MatchInfoBase> flowMatches, NxMatchFieldType matchType, String... params) {
        Iterable<MatchInfoBase> matches = filter(flowMatches,
            item -> item instanceof MatchInfo && ((MatchInfo) item).getMatchField().equals(matchType)
                 || item instanceof NxMatchInfo && ((NxMatchInfo) item).getMatchField().equals(matchType));
        assertFalse(Iterables.isEmpty(matches));
        for (MatchInfoBase baseMatch : matches) {
            if (baseMatch instanceof MatchInfo) {
                verifyMatchValues((MatchInfo)baseMatch, params);
            } else {
                verifyMatchValues((NxMatchInfo)baseMatch, params);
            }
        }
    }

    public static void verifyMatchValues(NxMatchInfo match, String... params) {
        switch (match.getMatchField()) {
            case nx_tcp_src_with_mask:
            case nx_tcp_dst_with_mask:
            case nx_udp_src_with_mask:
            case nx_udp_dst_with_mask:
            case ct_state:
                long[] values = Arrays.stream(params).mapToLong(l -> Long.parseLong(l)).toArray();
                Assert.assertArrayEquals(values, match.getMatchValues());
                break;
            default:
                assertTrue("match type is not supported", false);
                break;
        }
    }

    public static void verifyMatchValues(MatchInfo match, String... params) {
        switch (match.getMatchField()) {

            case ip_proto:
            case eth_type:
            case tcp_flags:
            case icmp_v4:
                long[] values = Arrays.stream(params).mapToLong(l -> Long.parseLong(l)).toArray();
                Assert.assertArrayEquals(values, match.getMatchValues());
                break;
            case ipv4_source:
            case ipv4_destination:
            case eth_src:
            case eth_dst:
            case arp_sha:
            case arp_tha:
                Assert.assertArrayEquals(params, match.getStringMatchValues());
                break;
            default:
                assertTrue("match type is not supported", false);
                break;
        }
    }

    public static void verifyMatchFieldTypeDontExist(List<MatchInfoBase> flowMatches, MatchFieldType matchType) {
        Iterable<MatchInfoBase> matches = filter(flowMatches,
            item -> ((MatchInfo) item).getMatchField().equals(matchType));
        Assert.assertTrue("unexpected match type " + matchType.name(), Iterables.isEmpty(matches));
    }

    public static void verifyMatchFieldTypeDontExist(List<MatchInfoBase> flowMatches, NxMatchFieldType matchType) {
        Iterable<MatchInfoBase> matches = filter(flowMatches,
            item -> ((MatchInfo) item).getMatchField().equals(matchType));
        Assert.assertTrue("unexpected match type " + matchType.name(), Iterables.isEmpty(matches));
    }

    public static void prepareAclDataUtil(AclDataUtil aclDataUtil, AclInterface inter, String... updatedAclNames) {
        aclDataUtil.addAclInterfaceMap(prapreaAclIds(updatedAclNames), inter);
    }

    public static Acl prepareAcl(String aclName, String... aces) {
        AccessListEntries aceEntries = mock(AccessListEntries.class);
        List<Ace> aceList = prepareAceList(aces);
        when(aceEntries.getAce()).thenReturn(aceList);

        Acl acl = mock(Acl.class);
        when(acl.getAccessListEntries()).thenReturn(aceEntries);
        when(acl.getAclName()).thenReturn(aclName);
        return acl;
    }

    public static List<Ace> prepareAceList(String... aces) {
        List<Ace> aceList = new ArrayList<>();
        for (String aceName : aces) {
            Ace aceMock = mock(Ace.class);
            when(aceMock.getRuleName()).thenReturn(aceName);
            aceList.add(aceMock);
        }
        return aceList;
    }

    public static List<Uuid> prapreaAclIds(String... names) {
        return Stream.of(names).map(name -> new Uuid(name)).collect(Collectors.toList());
    }

    public static void verifyActionTypeExist(List<ActionInfo> flowActions, ActionType actionType) {
        Iterable<ActionInfo> actions = filter(flowActions, item -> item.getActionType().equals(actionType));
        assertFalse(Iterables.isEmpty(actions));
    }

    public static void verifyActionInfo(List<ActionInfo> flowActions, ActionType actionType, String... params) {
        Iterable<ActionInfo> actions = filter(flowActions, item -> item.getActionType().equals(actionType));
        assertFalse(Iterables.isEmpty(actions));
        for (ActionInfo action : actions) {
            verifyActionValues(action, params);
        }
    }

    private static void verifyActionValues(ActionInfo action, String[] params) {
        switch (action.getActionType()) {
            case drop_action:
                break;
            case goto_table:
            case learn:
            case nx_resubmit:
                Assert.assertArrayEquals(params, action.getActionValues());
                break;
            default:
                assertTrue("match type is not supported", false);
                break;
        }
    }

    public static void verifyLearnActionFlowModInfo(List<ActionInfo> flowActions,
            NwConstants.LearnFlowModsType type, String... params) {
        Iterable<ActionInfo> actions = filter(flowActions,
            item -> item.getActionType().equals(ActionType.learn)
                 && item.getActionValuesMatrix()[0].equals(type.name()));
        assertFalse(Iterables.isEmpty(actions));
        for (ActionInfo action : actions) {
            verifyActionValues(action, params);
        }
    }

    public static void verifyInstructionInfo(List<InstructionInfo> instructionInfoList, InstructionType type,
            String ... params) {
        Iterable<InstructionInfo> matches = filter(instructionInfoList, item -> item.getInstructionType().equals(type));
        assertFalse(Iterables.isEmpty(matches));
        for (InstructionInfo baseMatch : matches) {
            verifyInstructionValues(baseMatch, params);
        }

    }

    private static void verifyInstructionValues(InstructionInfo inst, String[] params) {
        switch (inst.getInstructionType()) {
            case goto_table:
                long[] values = Arrays.stream(params).mapToLong(l -> Long.parseLong(l)).toArray();
                Assert.assertArrayEquals(values, inst.getInstructionValues());
                break;
            default:
                assertTrue("match type is not supported", false);
                break;
        }
    }

    public static void prepareAclClusterUtil(String entityName) {
        if (CacheUtil.getCache("entity.owner.cache") == null) {
            CacheUtil.createCache("entity.owner.cache");
        }
        ConcurrentMap entityOwnerCache = CacheUtil.getCache("entity.owner.cache");
        if (entityOwnerCache != null) {
            entityOwnerCache.put(entityName, true);
        }

    }

}
