/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import static org.junit.Assert.assertEquals;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.when;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.Futures;
import java.math.BigInteger;
import java.util.Arrays;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceTestUtils;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.netvirt.aclservice.utils.MethodInvocationParamSaver;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.Ipv4Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.AclBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.AclKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.AccessListEntriesBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.AceBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.MatchesBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIpBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv4Builder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.PortNumber;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.DestinationPortRangeBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.DirectionIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.IpPrefixOrAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttr;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttrBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairsBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

@RunWith(MockitoJUnitRunner.class)
public class StatelessIngressAclServiceImplTest {

    StatelessIngressAclServiceImpl testedService;

    @Mock DataBroker dataBroker;
    @Mock IMdsalApiManager mdsalManager;
    @Mock WriteTransaction mockWriteTx;
    @Mock ReadOnlyTransaction mockReadTx;
    @Mock AclserviceConfig config;

    MethodInvocationParamSaver<Void> installFlowValueSaver = null;
    MethodInvocationParamSaver<Void> removeFlowValueSaver = null;

    @Before
    public void setUp() {
        AclDataUtil aclDataUtil = new AclDataUtil();
        AclServiceUtils aclServiceUtils = new AclServiceUtils(aclDataUtil, config);
        testedService = new StatelessIngressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        doReturn(Futures.immediateCheckedFuture(null)).when(mockWriteTx).submit();
        doReturn(mockReadTx).when(dataBroker).newReadOnlyTransaction();
        doReturn(mockWriteTx).when(dataBroker).newWriteOnlyTransaction();
        installFlowValueSaver = new MethodInvocationParamSaver<>(null);
        doAnswer(installFlowValueSaver).when(mdsalManager).installFlow(any(FlowEntity.class));
        removeFlowValueSaver = new MethodInvocationParamSaver<>(null);
        doAnswer(removeFlowValueSaver).when(mdsalManager).removeFlow(any(FlowEntity.class));
    }

    @Test
    public void addAcl__NullInterface() {
        assertEquals(false, testedService.applyAcl(null));
    }

    @Test
    public void addAcl__MissingInterfaceStateShouldFail() throws Exception {
        AclInterface ai = new AclInterface();
        ai.setPortSecurityEnabled(true);
        ai.setDpId(BigInteger.ONE);
        assertEquals(false, testedService.applyAcl(ai));
    }

    @Test
    public void addAcl__SinglePort() throws Exception {
        Uuid sgUuid = new Uuid("12345678-1234-1234-1234-123456789012");
        AclInterface ai = stubTcpAclInterface(sgUuid, "if_name", "1.1.1.1/32", 80, 80);
        assertEquals(true, testedService.applyAcl(ai));
        assertEquals(7, installFlowValueSaver.getNumOfInvocations());

        FlowEntity firstRangeFlow = (FlowEntity) installFlowValueSaver.getInvocationParams(6).get(0);
        AclServiceTestUtils.verifyMatchInfo(firstRangeFlow.getMatchInfoList(),
                NxMatchFieldType.nx_tcp_dst_with_mask, "80", "65535");
        AclServiceTestUtils.verifyMatchInfo(firstRangeFlow.getMatchInfoList(), MatchFieldType.tcp_flags, "2");
        AclServiceTestUtils.verifyActionInfo(firstRangeFlow.getInstructionInfoList().get(0).getActionInfos(),
                ActionType.nx_resubmit, "" + NwConstants.EGRESS_LPORT_DISPATCHER_TABLE);
    }

    @Test
    public void addAcl__AllowAll() throws Exception {
        Uuid sgUuid = new Uuid("12345678-1234-1234-1234-123456789012");
        AclInterface ai = stubAllowAllInterface(sgUuid, "if_name");
        assertEquals(true, testedService.applyAcl(ai));
        assertEquals(7, installFlowValueSaver.getNumOfInvocations());

        FlowEntity firstRangeFlow = (FlowEntity) installFlowValueSaver.getInvocationParams(6).get(0);
        AclServiceTestUtils.verifyActionInfo(firstRangeFlow.getInstructionInfoList().get(0).getActionInfos(),
                ActionType.nx_resubmit, "" + NwConstants.EGRESS_LPORT_DISPATCHER_TABLE);
    }

    @Test
    public void addAcl__MultipleRanges() throws Exception {
        Uuid sgUuid = new Uuid("12345678-1234-1234-1234-123456789012");
        AclInterface ai = stubTcpAclInterface(sgUuid, "if_name", "1.1.1.1/32", 80, 84);
        assertEquals(true, testedService.applyAcl(ai));
        assertEquals(8, installFlowValueSaver.getNumOfInvocations());
        FlowEntity firstRangeFlow = (FlowEntity) installFlowValueSaver.getInvocationParams(6).get(0);
        // should have been 80-83 will be fixed as part of the port range support
        // https://bugs.opendaylight.org/show_bug.cgi?id=6200
        AclServiceTestUtils.verifyMatchInfo(firstRangeFlow.getMatchInfoList(),
                NxMatchFieldType.nx_tcp_dst_with_mask, "80", "65532");
        AclServiceTestUtils.verifyMatchInfo(firstRangeFlow.getMatchInfoList(), MatchFieldType.tcp_flags, "2");

        FlowEntity secondRangeFlow = (FlowEntity) installFlowValueSaver.getInvocationParams(7).get(0);
        AclServiceTestUtils.verifyMatchInfo(secondRangeFlow.getMatchInfoList(),
                NxMatchFieldType.nx_tcp_dst_with_mask, "84", "65535");
        AclServiceTestUtils.verifyMatchInfo(secondRangeFlow.getMatchInfoList(), MatchFieldType.tcp_flags, "2");
    }

    @Test
    public void addAcl__UdpSinglePortShouldDoNothing() throws Exception {
        Uuid sgUuid = new Uuid("12345678-1234-1234-1234-123456789012");
        AclInterface ai = stubUdpAclInterface(sgUuid, "if_name", "1.1.1.1/32", 80, 80);
        assertEquals(true, testedService.applyAcl(ai));
        assertEquals(6, installFlowValueSaver.getNumOfInvocations());
    }

    @Test
    public void removeAcl__SinglePort() throws Exception {
        Uuid sgUuid = new Uuid("12345678-1234-1234-1234-123456789012");
        AclInterface ai = stubTcpAclInterface(sgUuid, "if_name", "1.1.1.1/32", 80, 80);
        assertEquals(true, testedService.removeAcl(ai));
        assertEquals(7, removeFlowValueSaver.getNumOfInvocations());
        FlowEntity firstSynFlow = (FlowEntity) removeFlowValueSaver.getInvocationParams(6).get(0);
        AclServiceTestUtils.verifyMatchInfo(firstSynFlow.getMatchInfoList(),
                NxMatchFieldType.nx_tcp_dst_with_mask, "80", "65535");
        AclServiceTestUtils.verifyMatchInfo(firstSynFlow.getMatchInfoList(), MatchFieldType.tcp_flags,
                AclConstants.TCP_FLAG_SYN + "");

    }

    private AclInterface stubUdpAclInterface(Uuid sgUuid, String ifName, String ipv4PrefixStr,
            int tcpPortLower, int tcpPortUpper) {
        AclInterface ai = new AclInterface();
        ai.setPortSecurityEnabled(true);
        ai.setSecurityGroups(Arrays.asList(sgUuid));
        ai.setDpId(BigInteger.ONE);
        ai.setLPortTag(new Integer(2));
        stubInterfaceAcl(ifName, ai);

        stubAccessList(sgUuid, ipv4PrefixStr, tcpPortLower, tcpPortUpper, (short)NwConstants.IP_PROT_UDP);
        return ai;
    }

    private AclInterface stubTcpAclInterface(Uuid sgUuid, String ifName, String ipv4PrefixStr,
            int tcpPortLower, int tcpPortUpper) {
        AclInterface ai = new AclInterface();
        ai.setPortSecurityEnabled(true);
        ai.setDpId(BigInteger.ONE);
        ai.setLPortTag(Integer.valueOf(2));
        ai.setSecurityGroups(Arrays.asList(sgUuid));
        stubInterfaceAcl(ifName, ai);

        stubAccessList(sgUuid, ipv4PrefixStr, tcpPortLower, tcpPortUpper, (short)NwConstants.IP_PROT_TCP);
        return ai;
    }

    private AclInterface stubAllowAllInterface(Uuid sgUuid, String ifName) {
        AclInterface ai = new AclInterface();
        ai.setPortSecurityEnabled(true);
        ai.setSecurityGroups(Arrays.asList(sgUuid));
        ai.setDpId(BigInteger.ONE);
        ai.setLPortTag(new Integer(2));
        stubInterfaceAcl(ifName, ai);

        stubAccessList(sgUuid, "0.0.0.0/0", -1, -1, (short)-1);
        return ai;
    }

    private void stubInterfaceAcl(String ifName, AclInterface ai) {
        AllowedAddressPairsBuilder aapb = new AllowedAddressPairsBuilder();
        aapb.setIpAddress(new IpPrefixOrAddress("1.1.1.1/32".toCharArray()));
        aapb.setMacAddress(new MacAddress("AA:BB:CC:DD:EE:FF"));
        ai.setAllowedAddressPairs(Arrays.asList(aapb.build()));
    }

    private void stubAccessList(Uuid sgUuid, String ipv4PrefixStr, int portLower, int portUpper, short protocol) {
        AclBuilder ab = new AclBuilder();
        ab.setAclName("AAA");
        ab.setKey(new AclKey(sgUuid.getValue(),Ipv4Acl.class));

        AceIpBuilder aceIpBuilder = new AceIpBuilder();
        if (portLower != -1 && portUpper != -1) {
            DestinationPortRangeBuilder dprb = new DestinationPortRangeBuilder();
            dprb.setLowerPort(new PortNumber(portLower));
            dprb.setUpperPort(new PortNumber(portUpper));
            aceIpBuilder.setDestinationPortRange(dprb.build());
        }
        AceIpv4Builder aceIpv4Builder = new AceIpv4Builder();
        if (ipv4PrefixStr != null) {
            Ipv4Prefix ipv4Prefix = new Ipv4Prefix(ipv4PrefixStr);
            aceIpv4Builder.setDestinationIpv4Network(ipv4Prefix);
            aceIpBuilder.setAceIpVersion(aceIpv4Builder.build());
        }
        if (protocol != -1) {
            aceIpBuilder.setProtocol(protocol);
        }
        MatchesBuilder matches = new MatchesBuilder();
        matches.setAceType(aceIpBuilder.build());
        AceBuilder aceBuilder = new AceBuilder();
        aceBuilder.setMatches(matches.build());
        SecurityRuleAttrBuilder securityRuleAttrBuilder = new SecurityRuleAttrBuilder();
        securityRuleAttrBuilder.setDirection(DirectionIngress.class);
        aceBuilder.addAugmentation(SecurityRuleAttr.class, securityRuleAttrBuilder.build());
        AccessListEntriesBuilder aleb = new AccessListEntriesBuilder();
        aleb.setAce(Arrays.asList(aceBuilder.build()));
        ab.setAccessListEntries(aleb.build());

        InstanceIdentifier<Acl> aclKey = AclServiceUtils.getAclInstanceIdentifier(sgUuid.getValue());
        when(mockReadTx.read(LogicalDatastoreType.CONFIGURATION, aclKey))
            .thenReturn(Futures.immediateCheckedFuture(Optional.of(ab.build())));
    }
}
