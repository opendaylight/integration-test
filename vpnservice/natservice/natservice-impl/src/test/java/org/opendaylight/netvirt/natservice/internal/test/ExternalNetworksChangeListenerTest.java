/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal.test;

import static org.junit.Assert.assertEquals;
import static org.mockito.Matchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.natservice.internal.ExternalNetworksChangeListener;
import org.opendaylight.netvirt.natservice.internal.ExternalRoutersListener;
import org.opendaylight.netvirt.natservice.internal.FloatingIPListener;
import org.opendaylight.netvirt.natservice.internal.NaptManager;
import org.opendaylight.netvirt.natservice.internal.NatUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.FibRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.VpnRpcService;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;

@RunWith(PowerMockRunner.class)
@PrepareForTest(MDSALUtil.class)
public class ExternalNetworksChangeListenerTest {

    @Mock DataBroker dataBroker;
    @Mock ListenerRegistration<DataChangeListener> dataChangeListenerRegistration;
    @Mock IMdsalApiManager mdsalManager;
    @Mock FlowEntity flowMock;
    @Mock GroupEntity groupMock;
    InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks> id = null;
    org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks networks = null;
    private ExternalNetworksChangeListener extNetworks;

    @Before
    public void setUp() throws Exception {
        MockitoAnnotations.initMocks(this);
        when(dataBroker.registerDataChangeListener(
                any(LogicalDatastoreType.class),
                any(InstanceIdentifier.class),
                any(DataChangeListener.class),
                any(DataChangeScope.class)))
                .thenReturn(dataChangeListenerRegistration);
        extNetworks = new ExternalNetworksChangeListener(dataBroker,
                Mockito.mock(IMdsalApiManager.class),
                Mockito.mock(FloatingIPListener.class),
                Mockito.mock(ExternalRoutersListener.class),
                Mockito.mock(OdlInterfaceRpcService.class),
                Mockito.mock(NaptManager.class),
                Mockito.mock(IBgpManager.class),
                Mockito.mock(VpnRpcService.class),
                Mockito.mock(FibRpcService.class));

        PowerMockito.mockStatic(MDSALUtil.class);
    }


    @Test
    public void testSnatFlowEntity() {
        FlowEntity flowMock = mock(FlowEntity.class);
        final short SNAT_TABLE = 40;
        final int DEFAULT_SNAT_FLOW_PRIORITY = 0;
        final String FLOWID_SEPARATOR = ".";
        String SNAT_FLOWID_PREFIX = "SNAT.";


        BigInteger dpnId = new BigInteger("100");
        String routerName = new String("200");
        long routerId = 200;
        long groupId = 300;
        List<BucketInfo> bucketInfo = new ArrayList<>();
        List<ActionInfo> listActionInfoPrimary = new ArrayList<>();
        listActionInfoPrimary.add(new ActionInfo(ActionType.output,
                new String[] {"3"}));
        BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);
        List<ActionInfo> listActionInfoSecondary = new ArrayList<>();
        listActionInfoSecondary.add(new ActionInfo(ActionType.output,
                new String[] {"4"}));
        BucketInfo bucketSecondary = new BucketInfo(listActionInfoPrimary);
        bucketInfo.add(0, bucketPrimary);
        bucketInfo.add(1, bucketSecondary);

        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.group, new String[] {String.valueOf(groupId)}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));


        String flowRef =  new StringBuffer().append(SNAT_FLOWID_PREFIX).append(dpnId).append(FLOWID_SEPARATOR).
                append(SNAT_TABLE).append(FLOWID_SEPARATOR).append(routerId).toString();

        BigInteger cookieSnat = NatUtil.getCookieSnatFlow(routerId);
        try {
            PowerMockito.when(MDSALUtil.class, "buildFlowEntity", dpnId, SNAT_TABLE, flowRef,
                    DEFAULT_SNAT_FLOW_PRIORITY, flowRef, 0, 0,
                    cookieSnat, matches, instructions ).thenReturn(flowMock);
        } catch (Exception e) {
            // Test failed anyways
            assertEquals("true", "false");
        }
        /* TODO : Fix this to mock it properly when it reads DS
        extNetworks.buildSnatFlowEntity(dpnId, routerName, groupId);
        PowerMockito.verifyStatic(); */

    }

}
