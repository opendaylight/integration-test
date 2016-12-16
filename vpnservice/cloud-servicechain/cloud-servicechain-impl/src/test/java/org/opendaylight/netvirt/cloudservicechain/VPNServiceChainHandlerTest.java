/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain;

import static org.mockito.Matchers.argThat;
import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.anyObject;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import java.math.BigInteger;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import org.hamcrest.Description;
import org.hamcrest.Matcher;
import org.hamcrest.TypeSafeMatcher;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.cloudservicechain.matchers.FlowEntityMatcher;
import org.opendaylight.netvirt.cloudservicechain.matchers.FlowMatcher;
import org.opendaylight.netvirt.cloudservicechain.utils.VpnServiceChainUtils;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.IpAddresses;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.IpAddressesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.IpAddressesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstanceBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstanceKey;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


@RunWith(MockitoJUnitRunner.class)
public class VPNServiceChainHandlerTest {

    static final Logger LOG = LoggerFactory.getLogger(VPNServiceChainHandler.class);

    static final String RD = "100:100";
    static final String VPN_NAME = "AccessVPN";
    static final long VPN_ID = 1;
    static final long SCF_TAG = 1L;
    static final int SERV_CHAIN_TAG = 100;
    static final BigInteger DPN_ID = BigInteger.valueOf(1L);
    static final int LPORT_TAG = 1;
    static final String DC_GW_IP = "3.3.3.3";

    private VPNServiceChainHandler vpnsch; // SUT

    @Mock DataBroker broker;
    @Mock ReadOnlyTransaction readTx;
    @Mock WriteTransaction writeTx;
    @Mock IMdsalApiManager mdsalMgr;
    @Mock IVpnManager vpnManager;


    @BeforeClass
    public static void setUpBeforeClass() throws Exception {
    }

    @AfterClass
    public static void tearDownAfterClass() throws Exception {
    }

    @Before
    public void setUp() throws Exception {

        when(broker.newReadOnlyTransaction()).thenReturn(readTx);
        when(broker.newWriteOnlyTransaction()).thenReturn(writeTx);
        CheckedFuture chkdFuture = mock(CheckedFuture.class);
        when(writeTx.submit()).thenReturn(chkdFuture);

        // SUT
        vpnsch = new VPNServiceChainHandler(broker, mdsalMgr, vpnManager);
    }

    @After
    public void tearDown() throws Exception {
    }

    private <T extends DataObject> Matcher<InstanceIdentifier<T>> isIIdType(final Class<T> klass) {
        return new TypeSafeMatcher<InstanceIdentifier<T>>() {
            @Override
            public void describeTo(Description desc) {
                desc.appendText("Instance Identifier should have Target Type " + klass);
            }

            @Override
            protected boolean matchesSafely(InstanceIdentifier<T> id) {
                return id.getTargetType().equals(klass);
            }
        };
    }

    private void stubGetRouteDistinguisher(String vpnName, String rd) throws Exception {
        VpnInstance instance = new VpnInstanceBuilder().setKey(new VpnInstanceKey(vpnName)).setVrfId(rd)
                                                       .setVpnInstanceName(vpnName).build();

        InstanceIdentifier<VpnInstance> id = VpnServiceChainUtils.getVpnInstanceToVpnIdIdentifier(vpnName);
        CheckedFuture chkdFuture = mock(CheckedFuture.class);

        when(chkdFuture.checkedGet()).thenReturn(Optional.of(instance));
        // when(readTx.read(eq(LogicalDatastoreType.CONFIGURATION), eq(id))).thenReturn(chkdFuture);
        when(readTx.read(eq(LogicalDatastoreType.CONFIGURATION),
                         argThat(isIIdType(VpnInstance.class)))).thenReturn(chkdFuture);
    }


    private void stubNoRdForVpnName(String vpnName) throws Exception {
        CheckedFuture<Optional<VpnInstance>, ReadFailedException> chkdFuture = mock(CheckedFuture.class);
        when(chkdFuture.checkedGet()).thenReturn(Optional.absent());
        when(readTx.read(eq(LogicalDatastoreType.CONFIGURATION),
                         eq(VpnServiceChainUtils.getVpnInstanceToVpnIdIdentifier(vpnName))))
            .thenReturn(chkdFuture);
    }

    private void stubNoVpnInstanceForRD(String rd) throws Exception {
        CheckedFuture<Optional<VpnInstanceOpDataEntry>, ReadFailedException> chkdFuture = mock(CheckedFuture.class);
        when(chkdFuture.checkedGet()).thenReturn(Optional.absent());

        InstanceIdentifier<VpnInstanceOpDataEntry> id = InstanceIdentifier.create(VpnInstanceOpData.class)
                .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(rd));

        when(readTx.read(eq(LogicalDatastoreType.OPERATIONAL), eq(id))).thenReturn(chkdFuture);
    }

    private void stubGetVpnInstance(String rd) throws Exception {

        IpAddresses ipAddr =
            new IpAddressesBuilder().setIpAddress("1.3.4.5").setKey(new IpAddressesKey("1.3.4.5")).build();
        List<VpnInterfaces> ifacesList =
            Collections.singletonList(new VpnInterfacesBuilder().setInterfaceName("eth0").build());
        VpnToDpnListBuilder vtdlb =
            new VpnToDpnListBuilder().setKey(new VpnToDpnListKey(DPN_ID))
                                     .setDpnId(DPN_ID)
                                     .setIpAddresses(Collections.singletonList(ipAddr))
                                     .setVpnInterfaces(ifacesList);

        VpnInstanceOpDataEntry vpnInstanceOpDataEntry =
            new VpnInstanceOpDataEntryBuilder().setKey(new VpnInstanceOpDataEntryKey(rd))
                                               .setVpnId(VPN_ID)
                                               .setVpnToDpnList(Collections.singletonList(vtdlb.build()))
                                               .setVrfId("1").build();
        CheckedFuture chkdFuture = mock(CheckedFuture.class);
        when(chkdFuture.checkedGet()).thenReturn(Optional.of(vpnInstanceOpDataEntry));
        when(readTx.read(eq(LogicalDatastoreType.OPERATIONAL),
                         eq(VpnServiceChainUtils.getVpnInstanceOpDataIdentifier(rd)))).thenReturn(chkdFuture);
    }


    private VrfEntry buildVrfEntry(long label, String prefix, String nextop) {
        return new VrfEntryBuilder().setKey(new VrfEntryKey(prefix)).setDestPrefix(prefix).setLabel(label)
                                    .setNextHopAddressList(Collections.singletonList(nextop)).build();
    }

    private void stubGetVrfEntries(String rd, List<VrfEntry> vrfEntryList)
        throws Exception {

        VrfTables tables = new VrfTablesBuilder().setKey(new VrfTablesKey(rd)).setRouteDistinguisher(rd)
                                                 .setVrfEntry(vrfEntryList).build();
        CheckedFuture chkdFuture = mock(CheckedFuture.class);
        when(chkdFuture.checkedGet()).thenReturn(Optional.of(tables));
        when(readTx.read(eq(LogicalDatastoreType.CONFIGURATION), eq(VpnServiceChainUtils.buildVrfId(rd))))
                .thenReturn(chkdFuture);

    }

    private void stubReadVpnToDpnList(String rd, BigInteger dpnId, List<String> vpnIfacesOnDpn)
        throws Exception {

        List<VpnInterfaces> vpnIfacesList =
            vpnIfacesOnDpn.stream()
                          .map((ifaceName) -> new VpnInterfacesBuilder().setKey(new VpnInterfacesKey(ifaceName))
                                                                        .setInterfaceName(ifaceName).build())
                          .collect(Collectors.toList());

        CheckedFuture chkdFuture = mock(CheckedFuture.class);
        when(chkdFuture.checkedGet()).thenReturn(Optional.of(vpnIfacesList));
        when(readTx.read(eq(LogicalDatastoreType.OPERATIONAL),
                         eq(VpnServiceChainUtils.getVpnToDpnListIdentifier(rd, dpnId))))
             .thenReturn(chkdFuture);
    }

    @Test
    public void testprogramScfToVpnPipelineNullRd() throws Exception {
        /////////////////////
        // Basic stubbing //
        /////////////////////
        stubNoRdForVpnName(VPN_NAME);
        /////////////////////
        // SUT //
        /////////////////////
        vpnsch.programScfToVpnPipeline(VPN_NAME, SCF_TAG, SERV_CHAIN_TAG, DPN_ID.longValue(), LPORT_TAG,
                                       /* lastServiceChain */ false,
                                       NwConstants.ADD_FLOW);
        // verify that nothing is written in Open Flow tables

        ArgumentCaptor<FlowEntity> argumentCaptor = ArgumentCaptor.forClass(FlowEntity.class);
        verify(mdsalMgr, times(0)).installFlow(argumentCaptor.capture());

        List<FlowEntity> installedFlowsCaptured = argumentCaptor.getAllValues();
        assert (installedFlowsCaptured.size() == 0);

    }

    @Test
    public void testprogramScfToVpnPipelineNullVpnInstance() throws Exception {

        /////////////////////
        // Basic stubbing //
        /////////////////////
        stubGetRouteDistinguisher(VPN_NAME, RD);
        stubNoVpnInstanceForRD(RD);
        /////////////////////
        // SUT //
        /////////////////////
        vpnsch.programScfToVpnPipeline(VPN_NAME, SCF_TAG, SERV_CHAIN_TAG, DPN_ID.longValue(), LPORT_TAG,
                                       /* lastServiceChain */ false, NwConstants.ADD_FLOW);

        ArgumentCaptor<FlowEntity> argumentCaptor = ArgumentCaptor.forClass(FlowEntity.class);
        verify(mdsalMgr, times(0)).installFlow(argumentCaptor.capture());

        List<FlowEntity> installedFlowsCaptured = argumentCaptor.getAllValues();
        assert (installedFlowsCaptured.size() == 0);

    }

    @Test
    public void testprogramScfToVpnPipeline() throws Exception {

        /////////////////////
        // Basic stubbing //
        /////////////////////
        stubGetRouteDistinguisher(VPN_NAME, RD);
        stubGetVpnInstance(RD);
        stubGetVrfEntries(RD, Collections.singletonList(buildVrfEntry(2000L, "11.12.13.14", DC_GW_IP)));
        stubReadVpnToDpnList(RD, DPN_ID, Collections.singletonList("iface1"));
        /////////
        // SUT //
        /////////
        vpnsch.programScfToVpnPipeline(VPN_NAME, SCF_TAG, SERV_CHAIN_TAG, DPN_ID.longValue(), LPORT_TAG,
                                       /* lastServiceChain */ false,
                                       NwConstants.ADD_FLOW);
        ////////////
        // Verify //
        ////////////

        // Verifying installed flows
        ArgumentCaptor<Flow> argumentCaptor = ArgumentCaptor.forClass(Flow.class);
        verify(mdsalMgr, times(2)).installFlow((BigInteger)anyObject(), argumentCaptor.capture());
        List<Flow> installedFlowsCaptured = argumentCaptor.getAllValues();
        assert (installedFlowsCaptured.size() == 2);
        Flow expectedLportDispatcherFlowEntity =
            VpnServiceChainUtils.buildLPortDispFromScfToL3VpnFlow(VPN_ID, DPN_ID, LPORT_TAG, NwConstants.ADD_FLOW);
        assert (new FlowMatcher(expectedLportDispatcherFlowEntity).matches(installedFlowsCaptured.get(0)));

        // Verifying VpnToDpn update
        String vpnPseudoPortIfaceName =
            VpnServiceChainUtils.buildVpnPseudoPortIfName(DPN_ID.longValue(), SCF_TAG, SERV_CHAIN_TAG, LPORT_TAG);
        verify(vpnManager).updateVpnFootprint(eq(DPN_ID), eq(VPN_NAME), eq(vpnPseudoPortIfaceName), eq(Boolean.TRUE));
    }


    @Test
    public void testProgramVpnToScfPipeline() throws Exception {

        /////////////////////
        // Basic stubbing //
        /////////////////////
        stubGetRouteDistinguisher(VPN_NAME, RD);
        stubGetVpnInstance(RD);
        VrfEntry vrfEntry = buildVrfEntry(2000L, "11.12.13.14", DC_GW_IP);
        stubGetVrfEntries(RD, Collections.singletonList(vrfEntry));
        stubReadVpnToDpnList(RD, DPN_ID, Collections.singletonList("iface1"));

        /////////
        // SUT //
        /////////
        short tableId = 10;
        vpnsch.programVpnToScfPipeline(VPN_NAME, tableId, SCF_TAG, LPORT_TAG, NwConstants.ADD_FLOW);

        ArgumentCaptor<FlowEntity> argumentCaptor = ArgumentCaptor.forClass(FlowEntity.class);
        verify(mdsalMgr, times(2)).installFlow(argumentCaptor.capture());
        List<FlowEntity> installedFlowsCaptured = argumentCaptor.getAllValues();
        assert (installedFlowsCaptured.size() == 2);

        FlowEntity expectedLFibFlowEntity =
            VpnServiceChainUtils.buildLFibVpnPseudoPortFlow(DPN_ID, vrfEntry.getLabel(),
                                                            vrfEntry.getNextHopAddressList().get(0), LPORT_TAG);
        assert (new FlowEntityMatcher(expectedLFibFlowEntity).matches(installedFlowsCaptured.get(0)));

        FlowEntity expectedLPortDispatcher =
            VpnServiceChainUtils.buildLportFlowDispForVpnToScf(DPN_ID, LPORT_TAG, SCF_TAG, tableId);
        assert (new FlowEntityMatcher(expectedLPortDispatcher).matches(installedFlowsCaptured.get(1)));

    }

}
